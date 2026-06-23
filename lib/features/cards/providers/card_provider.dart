import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';

class CardModel {
  final int id;
  final String brand;
  final String lastFour;
  final int expMonth;
  final int expYear;
  final bool isDefault;
  final String? funding;

  const CardModel({required this.id, required this.brand, required this.lastFour, required this.expMonth, required this.expYear, required this.isDefault, this.funding});

  String get displayName => '${brand.toUpperCase()} •••• $lastFour';
  bool get isExpired => DateTime(expYear, expMonth).isBefore(DateTime.now());

  factory CardModel.fromJson(Map<String, dynamic> j) => CardModel(
    id: j['id'], brand: j['card_brand'] ?? 'unknown', lastFour: j['last_four'],
    expMonth: j['exp_month'], expYear: j['exp_year'],
    isDefault: j['is_default'] == true || j['is_default'] == 1,
    funding: j['funding'],
  );
}

class CardState {
  final List<CardModel> cards;
  final String? setupIntentSecret;
  final bool isLoading;
  final String? error;

  const CardState({this.cards = const [], this.setupIntentSecret, this.isLoading = false, this.error});
  CardState copyWith({List<CardModel>? cards, String? setupIntentSecret, bool? isLoading, String? error}) =>
      CardState(cards: cards ?? this.cards, setupIntentSecret: setupIntentSecret ?? this.setupIntentSecret, isLoading: isLoading ?? this.isLoading, error: error);
}

class CardNotifier extends StateNotifier<CardState> {
  CardNotifier() : super(const CardState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final res    = await ApiClient.instance.get(Endpoints.cards);
      final intent = await ApiClient.instance.get(Endpoints.setupIntent);
      state = state.copyWith(
        cards: (res.data['data'] as List).map((j) => CardModel.fromJson(j)).toList(),
        setupIntentSecret: intent.data['client_secret'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addCard(String paymentMethodId) async {
    try {
      await ApiClient.instance.post(Endpoints.cards, data: {'payment_method_id': paymentMethodId});
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> setDefault(int id) async {
    await ApiClient.instance.patch('${Endpoints.cards}/$id/default');
    await load();
  }

  Future<void> delete(int id) async {
    await ApiClient.instance.delete('${Endpoints.cards}/$id');
    state = state.copyWith(cards: state.cards.where((c) => c.id != id).toList());
  }
}

final cardProvider = StateNotifierProvider<CardNotifier, CardState>((ref) => CardNotifier()..load());
