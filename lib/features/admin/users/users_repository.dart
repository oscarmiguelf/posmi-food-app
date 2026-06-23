import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_client_provider.dart';

final usersRepositoryProvider = Provider<UsersRepository>(
  (ref) => UsersRepository(ref.watch(dioProvider)),
);

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.roleName,
    required this.isActive,
    this.stationId,
    this.stationName,
  });

  final String id;
  final String name;
  final String email;
  final String roleName;
  final bool isActive;
  final String? stationId;
  final String? stationName;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        roleName: (json['role'] as Map<String, dynamic>?)?['name']
                as String? ??
            json['roleName']?.toString() ??
            '—',
        isActive: json['isActive'] as bool? ?? true,
        stationId: json['stationId'] as String?,
        stationName:
            (json['station'] as Map<String, dynamic>?)?['name'] as String?,
      );
}

class UsersRepository {
  UsersRepository(this._dio);
  final Dio _dio;

  Future<List<UserModel>> getAll() async {
    final res = await _dio.get<Map<String, dynamic>>('/users');
    final data = res.data!['data'] as List<dynamic>;
    return data
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getRoles() async {
    final res = await _dio.get<Map<String, dynamic>>('/roles');
    return (res.data!['data'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<UserModel> create(Map<String, dynamic> body) async {
    final res =
        await _dio.post<Map<String, dynamic>>('/users', data: body);
    return UserModel.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<UserModel> update(String id, Map<String, dynamic> body) async {
    final res = await _dio
        .patch<Map<String, dynamic>>('/users/$id', data: body);
    return UserModel.fromJson(res.data!['data'] as Map<String, dynamic>);
  }
}
