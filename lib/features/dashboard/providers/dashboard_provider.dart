import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/models/transaction_model.dart';

class DashboardData {
  final double totalSent;
  final double monthSent;
  final int beneficiariesCount;
  final List<Map<String, dynamic>> rates;
  final List<TransactionModel> recentTransactions;

  const DashboardData({
    this.totalSent = 0,
    this.monthSent = 0,
    this.beneficiariesCount = 0,
    this.rates = const [],
    this.recentTransactions = const [],
  });
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final api = ApiClient.instance;

  final results = await Future.wait([
    api.get(Endpoints.transfers, queryParameters: {'status': 'completed', 'per_page': 5}),
    api.get(Endpoints.exchangeRates),
    api.get(Endpoints.beneficiaries),
  ]);

  final txData   = results[0].data['data'] as List? ?? [];
  final ratesData = results[1].data['data'] as List? ?? [];
  final benCount = (results[2].data['meta']?['total'] ?? 0) as int;

  final transactions = txData.map((j) => TransactionModel.fromJson(j)).toList();
  final totalSent = transactions.fold<double>(0, (s, t) => s + t.sendAmount);

  return DashboardData(
    totalSent: totalSent,
    monthSent: totalSent,
    beneficiariesCount: benCount,
    rates: ratesData.cast<Map<String, dynamic>>(),
    recentTransactions: transactions,
  );
});

final quoteProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final res = await ApiClient.instance.post(Endpoints.transferQuote, data: params);
  return res.data as Map<String, dynamic>;
});
