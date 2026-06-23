import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/models/user_model.dart';

const _storage = FlutterSecureStorage();

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});
  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) =>
      AuthState(user: user ?? this.user, isLoading: isLoading ?? this.isLoading, error: error);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiClient.instance.post(Endpoints.login, data: {'email': email, 'password': password});
      final token = res.data['token'];
      await _storage.write(key: 'auth_token', value: token);
      state = state.copyWith(isLoading: false, user: UserModel.fromJson(res.data['user']));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>?> register(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiClient.instance.post(Endpoints.register, data: data);
      final token = res.data['token'];
      await _storage.write(key: 'auth_token', value: token);
      state = state.copyWith(isLoading: false, user: UserModel.fromJson(res.data['user']));
      return res.data;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiClient.instance.post(Endpoints.verifyOtp, data: {'otp': otp, 'type': 'phone'});
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> loadUser() async {
    try {
      final res = await ApiClient.instance.get(Endpoints.me);
      state = state.copyWith(user: UserModel.fromJson(res.data));
    } catch (_) {}
  }

  Future<void> logout() async {
    await ApiClient.instance.post(Endpoints.logout).catchError((_) {});
    await _storage.delete(key: 'auth_token');
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
