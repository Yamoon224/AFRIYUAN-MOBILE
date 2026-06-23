class UserModel {
  final int id;
  final String uuid;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String kycStatus;
  final int kycLevel;
  final String accountStatus;
  final String? profilePhotoUrl;

  const UserModel({
    required this.id,
    required this.uuid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.kycStatus,
    required this.kycLevel,
    required this.accountStatus,
    this.profilePhotoUrl,
  });

  String get fullName => '$firstName $lastName';
  bool get isKycApproved => kycStatus == 'approved';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final d = json['data'] ?? json;
    return UserModel(
      id: d['id'],
      uuid: d['uuid'],
      firstName: d['first_name'],
      lastName: d['last_name'],
      email: d['email'],
      phoneNumber: d['phone_number'],
      kycStatus: d['kyc_status'] ?? 'pending',
      kycLevel: d['kyc_level'] ?? 0,
      accountStatus: d['account_status'] ?? 'active',
      profilePhotoUrl: d['profile_photo_url'],
    );
  }
}
