import '../models/geofence_model.dart';
import 'api_service.dart';

class GeofenceService {
  final _api = ApiService();

  Future<GeofenceModel?> getGeofence() async {
    final res = await _api.get('/geofence');
    final data = _api.parseResponse(res);
    if (data['data'] == null) return null;
    return GeofenceModel.fromJson(data['data']);
  }

  Future<void> setGeofence({
    required double latitude,
    required double longitude,
    required int radiusMeter,
  }) async {
    final res = await _api.put('/geofence', {
      'latitude': latitude,
      'longitude': longitude,
      'radius_meter': radiusMeter,
    });
    _api.parseResponse(res);
  }
}
