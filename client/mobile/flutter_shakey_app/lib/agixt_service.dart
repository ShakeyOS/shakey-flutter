import 'package:agixtsdk/agixtsdk.dart';

class AGiXTService {
  static final AGiXTService _instance = AGiXTService._internal();

  factory AGiXTService() {
    return _instance;
  }

  AGiXTService._internal();

  final AGiXTSDK agixtSDK = AGiXTSDK(
    baseUri: 'http://localhost:7437',
    apiKey: null,
  );
}
