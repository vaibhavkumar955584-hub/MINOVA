import 'package:workmanager/workmanager.dart';
import '../firebase/firebase_bootstrap.dart';
import 'sync_engine.dart';

const backgroundSyncTask = 'minesafe.sync.reports';

@pragma('vm:entry-point')
void backgroundSyncDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == backgroundSyncTask) {
      await FirebaseBootstrap.initialize();
      await SyncEngine.instance.processQueue();
    }
    return true;
  });
}

class BackgroundSyncService {
  static final BackgroundSyncService instance = BackgroundSyncService._();
  BackgroundSyncService._();

  Future<void> initialize() async {
    await Workmanager().initialize(backgroundSyncDispatcher);
    await Workmanager().registerPeriodicTask(
      'minesafe-periodic-sync',
      backgroundSyncTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
    );
  }
}
