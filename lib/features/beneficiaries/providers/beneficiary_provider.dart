import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/models/beneficiary_model.dart';

class BeneficiaryState {
  final List<BeneficiaryModel> beneficiaries;
  final bool isLoading;
  final String? error;

  const BeneficiaryState({this.beneficiaries = const [], this.isLoading = false, this.error});
  BeneficiaryState copyWith({List<BeneficiaryModel>? beneficiaries, bool? isLoading, String? error}) =>
      BeneficiaryState(beneficiaries: beneficiaries ?? this.beneficiaries, isLoading: isLoading ?? this.isLoading, error: error);
}

class BeneficiaryNotifier extends StateNotifier<BeneficiaryState> {
  BeneficiaryNotifier() : super(const BeneficiaryState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final res   = await ApiClient.instance.get(Endpoints.beneficiaries);
      final items = (res.data['data'] as List).map((j) => BeneficiaryModel.fromJson(j)).toList();
      state = state.copyWith(beneficiaries: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      await ApiClient.instance.post(Endpoints.beneficiaries, data: data);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ApiClient.instance.delete('${Endpoints.beneficiaries}/$id');
      state = state.copyWith(beneficiaries: state.beneficiaries.where((b) => b.id != id).toList());
      return true;
    } catch (_) { return false; }
  }
}

final beneficiaryProvider = StateNotifierProvider<BeneficiaryNotifier, BeneficiaryState>((ref) => BeneficiaryNotifier()..load());
