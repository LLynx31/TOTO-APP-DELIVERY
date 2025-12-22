/// DTO pour la requête d'inscription
class RegisterRequestDto {
  final String phoneNumber;
  final String fullName;
  final String password;
  final String? email;

  const RegisterRequestDto({
    required this.phoneNumber,
    required this.fullName,
    required this.password,
    this.email,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'phone_number': phoneNumber,
      'full_name': fullName,
      'password': password,
    };

    if (email != null && email!.isNotEmpty) {
      json['email'] = email!;
    }

    return json;
  }
}
