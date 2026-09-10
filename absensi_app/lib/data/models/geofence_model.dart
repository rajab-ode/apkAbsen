class GeofenceModel {
  final double latitude;
  final double longitude;
  final int radiusMeter;

  const GeofenceModel({
    required this.latitude,
    required this.longitude,
    required this.radiusMeter,
  });

  factory GeofenceModel.fromJson(Map<String, dynamic> j) => GeofenceModel(
        latitude: double.parse(j['latitude'].toString()),
        longitude: double.parse(j['longitude'].toString()),
        radiusMeter: j['radius_meter'] is int
            ? j['radius_meter']
            : int.parse(j['radius_meter'].toString()),
      );
}
