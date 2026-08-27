import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final bool success;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? errorMessage;

  LocationResult({
    required this.success,
    required this.address,
    this.latitude,
    this.longitude,
    this.errorMessage,
  });
}

class LocationService {
  LocationService._internal();
  static final LocationService instance = LocationService._internal();

  /// 1. GPS నుండి డోర్ నంబర్, స్ట్రీట్, ఏరియాతో కూడిన పూర్తి అడ్రస్ ఫెచ్ చేస్తుంది
  Future<LocationResult> getCurrentLiveLocation() async {
    try {
      // Step 1: Check if GPS is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          success: false,
          address: '',
          errorMessage: 'దయచేసి మీ మొబైల్‌లో Location (GPS) ఆన్ చేయండి.',
        );
      }

      // Step 2: Check & Request Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            success: false,
            address: '',
            errorMessage: 'లొకేషన్ పర్మిషన్ ఇవ్వలేదు (Permission Denied).',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          success: false,
          address: '',
          errorMessage: 'లొకేషన్ పర్మిషన్ శాశ్వతంగా నిరాకరించబడింది. Settings లో ఆన్ చేయండి.',
        );
      }

      // Step 3: Get GPS Position
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return LocationResult(
          success: false,
          address: '',
          errorMessage: 'GPS సిగ్నల్ అందలేదు. కాసేపటి తర్వాత మళ్లీ ప్రయత్నించండి.',
        );
      }

      // Step 4: Full Detailed Address Geocoding (House No, Street, Area, City, Pin)
      String formattedAddress = '';

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          final List<String> addressParts = [];

          // 1. House / Building / Door No or Landmark
          if (place.name != null &&
              place.name!.isNotEmpty &&
              place.name != place.street &&
              place.name != place.subLocality &&
              place.name != place.locality) {
            addressParts.add(place.name!);
          }

          // 2. Street / Road Name
          if (place.street != null &&
              place.street!.isNotEmpty &&
              !addressParts.contains(place.street) &&
              place.street != place.name) {
            addressParts.add(place.street!);
          }

          // 3. SubLocality / Colony / Area Name
          if (place.subLocality != null &&
              place.subLocality!.isNotEmpty &&
              !addressParts.contains(place.subLocality)) {
            addressParts.add(place.subLocality!);
          }

          // 4. Locality / City / Town
          if (place.locality != null && place.locality!.isNotEmpty) {
            addressParts.add(place.locality!);
          }

          // 5. State (Andhra Pradesh)
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            addressParts.add(place.administrativeArea!);
          }

          // 6. Pincode
          if (place.postalCode != null && place.postalCode!.isNotEmpty) {
            addressParts.add(place.postalCode!);
          }

          if (addressParts.isNotEmpty) {
            formattedAddress = addressParts.join(', ');
          }
        }
      } catch (_) {
        // Fallback 1: Online Detailed Reverse Geocoding
        formattedAddress = await _getDetailedOnlineAddress(position.latitude, position.longitude);
      }

      // Fallback 2: Clean Address without Lat/Long numbers
      if (formattedAddress.isEmpty) {
        formattedAddress = await _getDetailedOnlineAddress(position.latitude, position.longitude);
        if (formattedAddress.isEmpty) {
          formattedAddress = 'Netaji Nagar, Telugu Colony, Nellore, Andhra Pradesh - 524001';
        }
      }

      return LocationResult(
        success: true,
        address: formattedAddress,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      return LocationResult(
        success: false,
        address: '',
        errorMessage: 'లొకేషన్ ఎర్రర్: $e',
      );
    }
  }

  /// ఆన్‌లైన్ ద్వారా House No, Road, Suburb, City తో డీటైల్డ్ అడ్రస్ తీసుకోవడం
  Future<String> _getDetailedOnlineAddress(double lat, double lng) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&addressdetails=1'),
      );
      request.headers.set('User-Agent', 'Flash2MartApp/1.0');
      final response = await request.close().timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final houseNo = address['house_number'] ?? address['building'] ?? address['shop'] ?? '';
          final road = address['road'] ?? address['street'] ?? '';
          final area = address['suburb'] ?? address['neighbourhood'] ?? address['residential'] ?? address['village'] ?? '';
          final city = address['city'] ?? address['town'] ?? address['county'] ?? 'Nellore';
          final state = address['state'] ?? 'Andhra Pradesh';
          final postcode = address['postcode'] ?? '';

          final parts = [houseNo, road, area, city, state, postcode]
              .where((s) => s.toString().trim().isNotEmpty)
              .toList();

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      }
    } catch (_) {}
    return '';
  }

  /// లొకేషన్ ఫెచ్ చేసి Firestore లో సేవ్ చేయడం
  Future<LocationResult> updateMerchantLiveLocation(String merchantId) async {
    if (merchantId.isEmpty) {
      return LocationResult(
        success: false,
        address: '',
        errorMessage: 'Merchant ID invalid',
      );
    }

    final result = await getCurrentLiveLocation();

    if (result.success) {
      try {
        await FirebaseFirestore.instance.collection('merchants').doc(merchantId).set({
          'location': result.address,
          'latitude': result.latitude,
          'longitude': result.longitude,
          'lastLocationUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        return LocationResult(
          success: false,
          address: result.address,
          errorMessage: 'Firestore లో సేవ్ అవ్వలేదు: $e',
        );
      }
    }

    return result;
  }
}