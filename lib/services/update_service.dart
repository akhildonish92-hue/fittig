import 'package:shorebird_code_push/shorebird_code_push.dart';

class UpdateService {
  UpdateService({ShorebirdUpdater? updater})
      : _updater = updater ?? ShorebirdUpdater();

  final ShorebirdUpdater _updater;

  bool get isUpdaterSupported => _updater.isAvailable;

  Future<bool> checkForUpdates() async {
    if (!isUpdaterSupported) return false;

    try {
      final status = await _updater.checkForUpdate();
      return status == UpdateStatus.outdated;
    } catch (_) {
      return false;
    }
  }

  Future<bool> attemptUpdate() async {
    if (!isUpdaterSupported) return false;

    try {
      final status = await _updater.checkForUpdate();
      if (status != UpdateStatus.outdated) return false;

      await _updater.update();
      return true;
    } catch (_) {
      return false;
    }
  }
}
