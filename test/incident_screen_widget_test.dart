import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/core/theme/app_theme.dart';
import 'package:minesafe/features/report/incident/incident_report_screen.dart';
import 'package:minesafe/models/user_model.dart';
import 'package:minesafe/core/auth/auth_service.dart';
import 'package:minesafe/shared/providers/app_providers.dart';

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthService()) {
    state = user;
  }
}

void main() {
  testWidgets('IncidentReportScreen renders cleanly without layout/constraint exceptions',
      (WidgetTester tester) async {
    final mockUser = UserModel(
      id: 'usr_priya_02',
      employeeId: 'DGMS-INSP-404',
      fullName: 'Priya Mukhopadhyay',
      role: UserRole.inspector,
      designation: 'Statutory Mine Inspector',
      assignedMineId: 'JH-DHA-BCCL-007',
      assignedMineName: 'BCCL Pit-7 (Dhanbad)',
      phone: '+91 98111 22334',
      email: 'p.mukhopadhyay@dgms.gov.in',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(mockUser)),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const IncidentReportScreen(),
        ),
      ),
    );

    // Initial pump and settle
    await tester.pumpAndSettle();

    // Verify screen title is present
    expect(find.text('Emergency Incident Log'), findsOneWidget);

    // Verify banner is present
    expect(find.textContaining('STATUTORY EMERGENCY NOTICE'), findsOneWidget);

    // Verify Incident Classification
    expect(find.text('INCIDENT CLASSIFICATION / घटना का प्रकार'), findsOneWidget);

    // Verify Add Person button is clickable and adds a person
    final addPersonButton = find.text('Add Person');
    expect(addPersonButton, findsOneWidget);
    await tester.ensureVisible(addPersonButton);
    await tester.pumpAndSettle();

    await tester.tap(addPersonButton);
    await tester.pumpAndSettle();

    expect(find.text('Person #2 Name / Details'), findsOneWidget);

    // Verify submit button is rendered
    expect(find.text('SUBMIT EMERGENCY INCIDENT REPORT'), findsOneWidget);
  });
}
