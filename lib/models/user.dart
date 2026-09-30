enum LoginType { dummyJson, firebase }

class User {
  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.image,
    required this.accessToken,
    required this.refreshToken,
    this.age = 0,
    this.contactNo = '',
    this.loginType = LoginType.dummyJson,
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String image;
  final String accessToken;
  final String refreshToken;
  final int age;
  final String contactNo;
  final LoginType loginType;

  String get fullName => '$firstName $lastName'.trim();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      image: json['image'] as String? ?? '',
      accessToken:
          json['accessToken'] as String? ?? json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      contactNo: json['contactNo'] as String? ?? '',
      loginType: json['loginType'] == LoginType.firebase.name
          ? LoginType.firebase
          : LoginType.dummyJson,
    );
  }

  User copyWith({
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? image,
    String? accessToken,
    String? refreshToken,
    int? age,
    String? contactNo,
    LoginType? loginType,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender,
      image: image ?? this.image,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      age: age ?? this.age,
      contactNo: contactNo ?? this.contactNo,
      loginType: loginType ?? this.loginType,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'gender': gender,
    'image': image,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'age': age,
    'contactNo': contactNo,
    'loginType': loginType.name,
  };
}
