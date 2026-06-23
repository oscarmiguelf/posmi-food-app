import 'package:flutter/foundation.dart';

@immutable
class AuthState {
  const AuthState({
    this.accessToken,
    this.isLoading = false,
    this.error,
  });

  const AuthState.initial() : this(isLoading: true);

  final String? accessToken;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => accessToken != null;

  AuthState copyWith({
    String? accessToken,
    bool? isLoading,
    String? error,
    bool clearToken = false,
    bool clearError = false,
  }) =>
      AuthState(
        accessToken: clearToken ? null : accessToken ?? this.accessToken,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}
