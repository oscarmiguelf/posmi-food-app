import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({
    required this.localHubBaseUrl,
    required this.cloudBaseUrl,
  });

  final String localHubBaseUrl;
  final String cloudBaseUrl;

  static AppConfig get development => const AppConfig(
        localHubBaseUrl: 'http://pos-local.local:3000/api/v1',
        cloudBaseUrl: 'http://localhost:3000/api/v1',
      );

  static AppConfig get production => const AppConfig(
        localHubBaseUrl: 'http://pos-local.local:3000/api/v1',
        cloudBaseUrl: 'https://api.posmifood.com/api/v1',
      );

  static AppConfig get current =>
      kDebugMode ? development : production;
}
