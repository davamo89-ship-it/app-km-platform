import 'package:flutter/foundation.dart';

import '../../models/strava_sync_result.dart';
import 'strava_sync_exception.dart';
import 'strava_sync_service.dart';

enum StravaSyncStatus { idle, synchronizing, success, error }

class StravaSyncController extends ChangeNotifier {
  StravaSyncController({required StravaSyncService syncService})
    : _syncService = syncService;

  final StravaSyncService _syncService;

  StravaSyncStatus _status = StravaSyncStatus.idle;
  StravaSyncResult? _lastResult;
  String? _errorMessage;
  String? _errorCode;

  StravaSyncStatus get status => _status;

  StravaSyncResult? get lastResult => _lastResult;

  String? get errorMessage => _errorMessage;

  String? get errorCode => _errorCode;

  bool get isSynchronizing {
    return _status == StravaSyncStatus.synchronizing;
  }

  bool get hasResult => _lastResult != null;

  bool get hasError {
    return _status == StravaSyncStatus.error;
  }

  Future<StravaSyncResult?> synchronizeToday({required String userId}) async {
    if (isSynchronizing) {
      return null;
    }

    _status = StravaSyncStatus.synchronizing;
    _errorMessage = null;
    _errorCode = null;

    notifyListeners();

    try {
      final result = await _syncService.synchronizeToday(userId: userId);

      _lastResult = result;
      _status = StravaSyncStatus.success;

      notifyListeners();

      return result;
    } on StravaSyncException catch (error) {
      _status = StravaSyncStatus.error;
      _errorMessage = error.message;
      _errorCode = error.code;

      notifyListeners();

      return null;
    } catch (_) {
      _status = StravaSyncStatus.error;
      _errorMessage = 'Ocurrió un error inesperado durante la sincronización.';
      _errorCode = 'unexpected_error';

      notifyListeners();

      return null;
    }
  }

  void clearResult() {
    _lastResult = null;
    _errorMessage = null;
    _errorCode = null;
    _status = StravaSyncStatus.idle;

    notifyListeners();
  }
}
