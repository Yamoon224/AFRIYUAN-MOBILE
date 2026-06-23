class BeneficiaryModel {
  final int id;
  final String firstName;
  final String lastName;
  final String? nickname;
  final String receiveMethod;
  final String beneficiaryType;
  final String? phoneNumber;
  final String? bankName;
  final String? bankAccountNumber;
  final String? walletAccountNumber;

  const BeneficiaryModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.nickname,
    required this.receiveMethod,
    required this.beneficiaryType,
    this.phoneNumber,
    this.bankName,
    this.bankAccountNumber,
    this.walletAccountNumber,
  });

  String get displayName => nickname ?? '$firstName $lastName';
  bool get isChina => beneficiaryType == 'china';

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) {
    final d = json['data'] ?? json;
    return BeneficiaryModel(
      id: d['id'],
      firstName: d['first_name'],
      lastName: d['last_name'],
      nickname: d['nickname'],
      receiveMethod: d['receive_method'],
      beneficiaryType: d['beneficiary_type'] ?? 'china',
      phoneNumber: d['phone_number'],
      bankName: d['bank_name'],
      bankAccountNumber: d['bank_account_number'],
      walletAccountNumber: d['wallet_account_number'],
    );
  }
}
