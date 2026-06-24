class WalletModel {
  final String uuid;
  final double balance;
  final String currencyCode;
  final String status;

  const WalletModel({
    required this.uuid,
    required this.balance,
    required this.currencyCode,
    required this.status,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        uuid: json['uuid'] as String,
        balance: (json['balance'] as num).toDouble(),
        currencyCode: json['currency_code'] as String,
        status: json['status'] as String,
      );

  bool get isActive => status == 'active';
}

class WalletTransaction {
  final String uuid;
  final String type; // credit | debit
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? description;
  final String? source;
  final String createdAt;

  const WalletTransaction({
    required this.uuid,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.description,
    this.source,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        uuid: json['uuid'] as String,
        type: json['type'] as String,
        amount: (json['amount'] as num).toDouble(),
        balanceBefore: (json['balance_before'] as num).toDouble(),
        balanceAfter: (json['balance_after'] as num).toDouble(),
        description: json['description'] as String?,
        source: json['source'] as String?,
        createdAt: json['created_at'] as String,
      );
}

class InternalTransferRecipient {
  final String uuid;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;

  const InternalTransferRecipient({
    required this.uuid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
  });

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  factory InternalTransferRecipient.fromJson(Map<String, dynamic> json) =>
      InternalTransferRecipient(
        uuid: json['uuid'] as String,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        email: json['email'] as String,
        phoneNumber: json['phone_number'] as String?,
      );
}
