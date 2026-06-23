import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/models/transaction_model.dart';

class TransferState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  const TransferState({
    this.transactions = const [],
    this.isLoading    = false,
    this.error,
    this.currentPage  = 1,
    this.hasMore      = true,
  });

  TransferState copyWith({List<TransactionModel>? transactions, bool? isLoading, String? error, int? currentPage, bool? hasMore}) =>
      TransferState(transactions: transactions ?? this.transactions, isLoading: isLoading ?? this.isLoading, error: error, currentPage: currentPage ?? this.currentPage, hasMore: hasMore ?? this.hasMore);
}

class TransferNotifier extends StateNotifier<TransferState> {
  TransferNotifier() : super(const TransferState());

  Future<void> load({bool refresh = false}) async {
    if (state.isLoading) return;
    if (refresh) state = const TransferState();
    state = state.copyWith(isLoading: true);

    try {
      final res = await ApiClient.instance.get(Endpoints.transactions, queryParameters: {'page': state.currentPage, 'per_page': 15});
      final data  = (res.data['data'] as List).map((j) => TransactionModel.fromJson(j)).toList();
      final total = res.data['meta']?['total'] ?? data.length;

      state = state.copyWith(
        transactions: refresh ? data : [...state.transactions, ...data],
        currentPage: state.currentPage + 1,
        hasMore: state.transactions.length + data.length < total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Map<String, dynamic>?> getQuote(Map<String, dynamic> params) async {
    final res = await ApiClient.instance.post(Endpoints.transferQuote, data: params);
    return res.data as Map<String, dynamic>;
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      await ApiClient.instance.post(Endpoints.transfers, data: data);
      await load(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> cancel(String uuid) async {
    try {
      await ApiClient.instance.patch('${Endpoints.transfers}/$uuid/cancel');
      await load(refresh: true);
      return true;
    } catch (_) { return false; }
  }
}

final transferProvider = StateNotifierProvider<TransferNotifier, TransferState>((ref) => TransferNotifier()..load());

final transactionDetailProvider = FutureProvider.family<TransactionModel, String>((ref, uuid) async {
  final res = await ApiClient.instance.get('${Endpoints.transfers}/$uuid');
  return TransactionModel.fromJson(res.data['data'] ?? res.data);
});
