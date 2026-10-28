import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class FaskesLocation {
  const FaskesLocation({
    required this.name,
    required this.category,
    required this.address,
    required this.distanceMeters,
  });

  final String name;
  final String category;
  final String address;
  final double distanceMeters;
}

class FaskesSearchService {
  static const int maxDistanceMeters = 60000;
  static final Uri _endpoint = Uri.parse(
    'https://overpass-api.de/api/interpreter',
  );

  Future<List<FaskesLocation>> findNearby({
    required double latitude,
    required double longitude,
  }) async {
    final query =
        '''
[out:json][timeout:50];
(
  nwr(around:${maxDistanceMeters},${latitude},${longitude})["amenity"~"^(hospital|clinic|doctors)\$"];
  nwr(around:${maxDistanceMeters},${latitude},${longitude})["healthcare"~"^(hospital|clinic|doctor|health_post|birthing_centre)\$"];
  nwr(around:${maxDistanceMeters},${latitude},${longitude})["name"~"puskesmas",i];
);
out center;
''';

    final response = await http
        .post(
          _endpoint,
          headers: const {'Accept': 'application/json'},
          body: {'data': query},
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw StateError('Overpass returned HTTP ${response.statusCode}');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = payload['elements'];
    if (elements is! List) return const [];

    final seen = <String>{};
    final places = <FaskesLocation>[];
    for (final element in elements) {
      if (element is! Map<String, dynamic>) continue;

      final tags = element['tags'];
      if (tags is! Map<String, dynamic>) continue;
      final name = (tags['name'] as String?)?.trim();
      if (name == null || name.isEmpty) continue;

      final center = element['center'];
      final coordinates = center is Map<String, dynamic> ? center : element;
      final lat = (coordinates['lat'] as num?)?.toDouble();
      final lon = (coordinates['lon'] as num?)?.toDouble();
      if (lat == null || lon == null) continue;

      final id = '${element['type']}/${element['id']}';
      if (!seen.add(id)) continue;

      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        lat,
        lon,
      );
      final address =
          [tags['addr:street'], tags['addr:suburb'], tags['addr:city']]
              .whereType<String>()
              .map((part) => part.trim())
              .where((part) => part.isNotEmpty)
              .toSet()
              .join(', ');

      places.add(
        FaskesLocation(
          name: name,
          category: (tags['healthcare'] ?? tags['amenity'] ?? 'Faskes')
              .toString(),
          address: address,
          distanceMeters: distance,
        ),
      );
    }

    places.sort(
      (first, second) => first.distanceMeters.compareTo(second.distanceMeters),
    );
    return places;
  }
}
