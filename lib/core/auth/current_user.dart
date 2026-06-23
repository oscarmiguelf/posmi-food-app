import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_notifier.dart';

class CurrentUser {
  const CurrentUser({
    required this.sub,
    required this.email,
    required this.roleName,
    required this.branchIds,
  });

  final String sub;
  final String email;
  final String roleName;
  final List<String> branchIds;

  bool get isAdmin => roleName.toLowerCase() == 'admin';
  String? get branchId => branchIds.isNotEmpty ? branchIds.first : null;
}

final currentUserProvider = Provider<CurrentUser?>((ref) {
  final token = ref.watch(authProvider).accessToken;
  if (token == null) return null;
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final normalized = base64Url.normalize(parts[1]);
    final payload =
        json.decode(utf8.decode(base64Url.decode(normalized))) as Map;
    return CurrentUser(
      sub: payload['sub']?.toString() ?? '',
      email: payload['email']?.toString() ?? '',
      roleName: payload['roleName']?.toString() ?? '',
      branchIds: (payload['branchIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  } catch (_) {
    return null;
  }
});
