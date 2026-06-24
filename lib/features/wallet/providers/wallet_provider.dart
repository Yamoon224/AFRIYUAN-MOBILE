import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/models/wallet_model.dart';

// ── Wallet state ──────────────────────────────────────────────────────────────

class WalletState {
  final WalletModel? wallet;
  final List<WalletTransaction> transactions;
  final bool loading;
  final String? error;

  const WalletState({
    this.wallet,
    this.transactions = const [],
    this.loading = false,
    this.error,
  });

  WalletState copyWith({
    WalletModel? wallet,
    List<WalletTransaction>? transactions,
    bool? loading,
    String? error,
  }) =>
      WalletState(
        wallet: wallet ?? this.wallet,
        transactions: transactions ?? this.transactions,
        loading: loading ?? this.loading,
        error: error,
      );
}

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier() : super(const WalletState());

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final walletRes = await ApiClient.instance.dio.get(Endpoints.wallet);
      final txRes    = await ApiClient.instance.dio.get(Endpoints.walletTransactions);

      final wallet = WalletModel.fromJson(
          walletRes.data['data'] as Map<String, dynamic>);

      final raw = txRes.data['data'] as List<dynamic>? ?? [];
      final txList = raw
          .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(wallet: wallet, transactions: txList, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<String?> topUp(double amount, String description) async {
    try {
      await ApiClient.instance.dio.post(Endpoints.walletTopUp,
          data: {'amount': amount, 'description': description});
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> withdraw(double amount, String description) async {
    try {
      await ApiClient.instance.dio.post(Endpoints.walletWithdraw,
          data: {'amount': amount, 'description': description});
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>(
        (_) => WalletNotifier()..load());

// ── Internal transfer state ───────────────────────────────────────────────────

class InternalTransferState {
  final List<InternalTransferRecipient> searchResults;
  final InternalTransferRecipient? selectedRecipient;
  final bool searching;
  final bool submitting;
  final String? error;

  const InternalTransferState({
    this.searchResults = const [],
    this.selectedRecipient,
    this.searching = false,
    this.submitting = false,
    this.error,
  });

  InternalTransferState copyWith({
    List<InternalTransferRecipient>? searchResults,
    InternalTransferRecipient? selectedRecipient,
    bool clearRecipient = false,
    bool? searching,
    bool? submitting,
    String? error,
  }) =>
      InternalTransferState(
        searchResults: searchResults ?? this.searchResults,
        selectedRecipient: clearRecipient
            ? null
            : (selectedRecipient ?? this.selectedRecipient),
        searching: searching ?? this.searching,
        submitting: submitting ?? this.submitting,
        error: error,
      );
}

class InternalTransferNotifier
    extends StateNotifier<InternalTransferState> {
  InternalTransferNotifier() : super(const InternalTransferState());

  Future<void> searchRecipient(String query) async {
    if (query.length < 3) {
      state = state.copyWith(searchResults: []);
      return;
    }
    state = state.copyWith(searching: true, error: null);
    try {
      final res = await ApiClient.instance.dio.get(
        Endpoints.internalTransferSearch,
        queryParameters: {'q': query},
      );
      final list = (res.data['data'] as List<dynamic>)
          .map((e) => InternalTransferRecipient.fromJson(
              e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(searchResults: list, searching: false);
    } catch (_) {
      state = state.copyWith(searching: false, searchResults: []);
    }
  }

  void selectRecipient(InternalTransferRecipient recipient) {
    state = state.copyWith(selectedRecipient: recipient, searchResults: []);
  }

  void clearRecipient() {
    state = state.copyWith(clearRecipient: true, searchResults: []);
  }

  Future<String?> transfer(double amount, String description) async {
    if (state.selectedRecipient == null) return 'No recipient selected.';
    state = state.copyWith(submitting: true, error: null);
    try {
      await ApiClient.instance.dio.post(Endpoints.internalTransfers, data: {
        'receiver_uuid': state.selectedRecipient!.uuid,
        'amount': amount,
        'description': description,
      });
      state = const InternalTransferState();
      return null;
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
      return e.toString();
    }
  }
}

final internalTransferProvider =
    StateNotifierProvider<InternalTransferNotifier, InternalTransferState>(
        (_) => InternalTransferNotifier());
