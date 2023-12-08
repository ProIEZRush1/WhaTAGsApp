import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class LocationUtils {
  static Future<Position?> _getLocation() async {
    try {
      var position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      printGreen(
          'Location latitude=${position.latitude},longitude=${position.longitude}');
      return position;
    } catch (e) {
      printRed('Exception on getCurrentPosition $e');
    }
    return null;
  }

  static Future<Position?> getLocation() async {
    var serviceStatus = await Geolocator.isLocationServiceEnabled();
    if (serviceStatus) {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          printRed('Location permissions are denied');
          Future.error('Location permissions are denied');
        } else if (permission == LocationPermission.deniedForever) {
          printRed("'Location permissions are permanently denied");
          Future.error(
              'Location permissions are permanently denied, we cannot request permissions.');
        } else {
          return _getLocation();
        }
      } else {
        return _getLocation();
      }
    } else {
      printRed("GPS Service is not enabled, turn on GPS location");
    }
    return null;
  }

  static Future<bool> openMap(double latitude, double longitude,
      [String? label]) async {
    return launchUrl(_createCoordinatesUri(latitude, longitude, label));
  }

  static Uri _createCoordinatesUri(double latitude, double longitude,
      [String? label]) {
    Uri uri;

    if (Platform.isAndroid) {
      var query = '$latitude,$longitude';

      if (label != null) query += '($label)';

      uri = Uri(scheme: 'geo', host: '0,0', queryParameters: {'q': query});
    } else if (Platform.isIOS) {
      var params = {
        'll': '$latitude,$longitude',
        'q': label ?? '$latitude, $longitude',
      };

      uri = Uri.https('maps.apple.com', '/', params);
    } else {
      uri = Uri.https('www.google.com', '/maps/search/',
          {'api': '1', 'query': '$latitude,$longitude'});
    }

    return uri;
  }
}

void printGreen(String text) {
  print('\x1B[32m$text\x1B[0m');
}

void printRed(String text) {
  print('\x1B[31m$text\x1B[0m');
}
