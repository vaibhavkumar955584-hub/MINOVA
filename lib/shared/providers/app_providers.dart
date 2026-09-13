import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../core/ai/document_ocr_service.dart';
import '../../core/ai/gemini_copilot_service.dart';
import '../../core/auth/app_security_state.dart';
import '../../core/auth/app_session_coordinator.dart';
import '../../core/auth/biometric_service.dart';
import '../../core/auth/auth_service.dart';
import '../../core/auth/firebase_auth_service.dart';
import '../../core/auth/mpin_service.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/auth/secure_storage.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../core/evidence/evidence_service.dart';
import '../../core/location/location_service.dart';
import '../../core/sync/sync_engine.dart';
import '../../models/user_model.dart';
import '../../core/firebase/firebase_user_repository.dart';
import '../../repositories/attendance_repository.dart';
import '../../repositories/correction_repository.dart';
import '../../repositories/document_repository.dart';
import '../../repositories/incident_repository.dart';
import '../../repositories/inspection_repository.dart';
import '../../repositories/observation_repository.dart';

// Services
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>(
  (ref) => FirebaseAuthService(),
);
final firebaseUserRepositoryProvider = Provider<FirebaseUserRepository>(
  (ref) => FirebaseUserRepository.instance,
);
final mpinServiceProvider = Provider<MpinService>(
  (ref) => MpinService.instance,
);
final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService.instance,
);
final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService.instance,
);
final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService.instance,
);
final evidenceServiceProvider = Provider<EvidenceService>(
  (ref) => EvidenceService.instance,
);
final documentOcrServiceProvider = Provider<DocumentOcrService>(
  (ref) => DocumentOcrService(),
);
final geminiCopilotServiceProvider = Provider<GeminiCopilotService>(
  (ref) => GeminiCopilotService(),
);
final syncEngineProvider = Provider<SyncEngine>((ref) => SyncEngine.instance);

// Repositories
final inspectionRepositoryProvider = Provider<InspectionRepository>(
  (ref) => InspectionRepository(),
);
final incidentRepositoryProvider = Provider<IncidentRepository>(
  (ref) => IncidentRepository(),
);
final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepository(),
);
final observationRepositoryProvider = Provider<ObservationRepository>(
  (ref) => ObservationRepository(),
);
final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => DocumentRepository(),
);
final correctionRepositoryProvider = Provider<CorrectionRepository>(
  (ref) => CorrectionRepository(),
);

// Reactive States
class AuthNotifier extends StateNotifier<UserModel?> {
  final AuthService _authService;
  final FirebaseAuthService? _firebaseAuth;
  final FirebaseUserRepository? _userRepository;
  final MpinService? _mpinService;

  AuthNotifier(
    this._authService, {
    FirebaseAuthService? firebaseAuth,
    FirebaseUserRepository? userRepository,
    MpinService? mpinService,
  }) : _firebaseAuth = firebaseAuth,
       _userRepository = userRepository,
       _mpinService = mpinService,
       super(_authService.currentUser);

  FirebaseAuthService get _firebaseAuthService =>
      _firebaseAuth ?? FirebaseAuthService();

  FirebaseUserRepository get _firebaseUserRepository =>
      _userRepository ?? FirebaseUserRepository.instance;

  MpinService get _localMpinService => _mpinService ?? MpinService.instance;

  Future<void> restoreSession() async {
    if (_firebaseAuth != null && _firebaseAuthService.isAvailable) {
      final firebaseUser = _firebaseAuthService.currentUser;
      if (firebaseUser == null) {
        await _authService.logout();
        state = null;
        return;
      }
      final profile = await _firebaseUserRepository.loadProfile(
        firebaseUser.uid,
      );
      if (profile == null) {
        await _authService.logout();
        state = null;
        return;
      }
      try {
        _validateInspectorProfile(profile);
        await _authService.setAuthenticatedUser(
          user: profile,
          token: 'firebase_${firebaseUser.uid}',
        );
        state = profile;
        return;
      } on AuthException {
        await _authService.logout();
        state = null;
        return;
      }
    }
    final user = await _authService.restoreSession();
    state = user;
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _firebaseAuthService.sendPasswordResetEmail(email);

  Future<void> resetMpin({
    required String email,
    required String password,
    required String newPin,
  }) async {
    await _firebaseAuthService.reauthenticate(email: email, password: password);
    await refactorMpin(newPin);
  }

  Future<void> refactorMpin(String newPin) async {
    await _localMpinService.setupMpin(newPin);
  }

  Future<void> login(String employeeId, String password) async {
    final user = await _authService.login(
      employeeId: employeeId,
      password: password,
    );
    state = user;
  }

  Future<void> loginWithEmail(String email, String password) async {
    final user = await _firebaseAuthService.signInWithEmailPassword(
      email: email,
      password: password,
    );
    await _adoptFirebaseUser(user);
  }

  Future<void> _adoptFirebaseUser(fb.User firebaseUser) async {
    final existing = await _firebaseUserRepository.loadProfile(
      firebaseUser.uid,
    );
    if (existing == null) {
      await _firebaseAuthService.signOut();
      throw const AuthException(
        'Your inspector profile is not configured. Please contact your mine manager.',
      );
    }
    try {
      _validateInspectorProfile(existing);
    } on AuthException {
      await _firebaseAuthService.signOut();
      rethrow;
    }
    final profile = existing;
    await _authService.setAuthenticatedUser(
      user: profile,
      token: 'firebase_${firebaseUser.uid}',
    );
    state = profile;
  }

  void _validateInspectorProfile(UserModel profile) {
    if (profile.accountStatus.toLowerCase() != 'active') {
      throw const AuthException(
        'Your account is inactive. Please contact your mine manager.',
      );
    }
    if (profile.role != UserRole.inspector) {
      throw const AuthException(
        'This mobile app is only available to inspector accounts.',
      );
    }
    if (profile.assignedMineIds.where((id) => id.trim().isNotEmpty).isEmpty) {
      throw const AuthException(
        'No mine is assigned to your account. Please contact your mine manager.',
      );
    }
    if (profile.managerId == null || profile.managerId!.trim().isEmpty) {
      throw const AuthException(
        'Your manager assignment is missing. Please contact your mine manager.',
      );
    }
  }

  Future<void> logout() async {
    if (_firebaseAuth != null && _firebaseAuthService.isAvailable) {
      try {
        await _firebaseAuthService.signOut();
      } catch (_) {}
    }
    await _authService.logout();
    await _localMpinService.clearMpin();
    await SecureTokenStorage.instance.lockSession();
    state = null;
  }

  void switchUser(UserModel user) {
    _authService.switchUser(user);
    state = user;
  }
}

final sessionUnlockedProvider = StateProvider<bool>((ref) => false);

final appSessionCoordinatorProvider =
    StateNotifierProvider<AppSessionCoordinator, AppSecuritySnapshot>((ref) {
  return AppSessionCoordinator(
    mpinService: ref.watch(mpinServiceProvider),
    biometricService: ref.watch(biometricServiceProvider),
  );
});

final authStateProvider = StateNotifierProvider<AuthNotifier, UserModel?>((
  ref,
) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(
    authService,
    firebaseAuth: ref.watch(firebaseAuthServiceProvider),
    userRepository: ref.watch(firebaseUserRepositoryProvider),
    mpinService: ref.watch(mpinServiceProvider),
  );
});

final rolePermissionsProvider = Provider<RolePermissions?>((ref) {
  final user = ref.watch(authStateProvider);
  if (user == null) return null;
  return RolePermissions.forUser(user);
});

// Connectivity Stream Provider
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  return connectivity.onConnectivityChanged;
});

// Sync Status & Pending Counter Stream Provider
final pendingSyncCountProvider = StreamProvider<int>((ref) async* {
  final syncEngine = ref.watch(syncEngineProvider);
  yield await syncEngine.getPendingSyncCount();
  await for (final _ in syncEngine.onSyncEvents) {
    yield await syncEngine.getPendingSyncCount();
  }
});
