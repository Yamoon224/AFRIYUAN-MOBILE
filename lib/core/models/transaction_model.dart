class TransactionModel {
  final String uuid;
  final String referenceNumber;
  final String sendCurrency;
  final double sendAmount;
  final String receiveCurrency;
  final double receiveAmount;
  final double feeAmount;
  final double exchangeRate;
  final String direction;
  final String status;
  final String paymentMethod;
  final String? beneficiaryName;
  final DateTime createdAt;

  const TransactionModel({
    required this.uuid,
    required this.referenceNumber,
    required this.sendCurrency,
    required this.sendAmount,
    required this.receiveCurrency,
    required this.receiveAmount,
    required this.feeAmount,
    required this.exchangeRate,
    required this.direction,
    required this.status,
    required this.paymentMethod,
    this.beneficiaryName,
    required this.createdAt,
  });

  bool get isAfricaToChina => direction == 'africa_to_china';
  bool get isCompleted => status == 'completed';
  bool get isProcessing => ['processing', 'payment_confirmed', 'sent_to_beneficiary'].contains(status);

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      uuid: json['uuid'],
      referenceNumber: json['reference_number'],
      sendCurrency: json['send_currency'],
      sendAmount: double.parse(json['send_amount'].toString()),
      receiveCurrency: json['receive_currency'],
      receiveAmount: double.parse(json['receive_amount'].toString()),
      feeAmount: double.parse(json['fee_amount']?.toString() ?? '0'),
      exchangeRate: double.parse(json['exchange_rate']?.toString() ?? '0'),
      direction: json['direction'] ?? 'africa_to_china',
      status: json['status'],
      paymentMethod: json['payment_method'] ?? '',
      beneficiaryName: json['beneficiary']?['nickname'] ?? json['beneficiary']?['first_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
