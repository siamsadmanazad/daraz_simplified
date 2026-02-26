/// user_model.dart
///
/// Immutable data models for authentication and user profile responses from
/// the Fakestore API.
///
/// Auth endpoint  : POST https://fakestoreapi.com/auth/login
///   → returns    : { "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." }
///
/// Profile endpoint: GET https://fakestoreapi.com/users/{id}
///   → returns full user object (see User below)
///
/// Test credentials (hardcoded in Fakestore):
///   username: mor_2314   password: 83r5^_

// ─── LoginResponse ──────────────────────────────────────────────────────────

/// Wraps the token string returned by POST /auth/login.
/// We only need the token — the userId is obtained separately.
class LoginResponse {
  final String token;

  const LoginResponse({required this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(token: json['token'] as String);
  }
}

// ─── Address ────────────────────────────────────────────────────────────────

/// Nested geolocation — not displayed in the UI, but present in the JSON.
class GeoLocation {
  final String lat;
  final String long;

  const GeoLocation({required this.lat, required this.long});

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      lat: json['lat'] as String? ?? '0',
      long: json['long'] as String? ?? '0',
    );
  }
}

/// Full postal address for a user — shown on the Profile screen.
class Address {
  final String street;
  final String suite;
  final String city;
  final String zipcode;
  final GeoLocation geolocation;

  const Address({
    required this.street,
    required this.suite,
    required this.city,
    required this.zipcode,
    required this.geolocation,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] as String? ?? '',
      // 'suite' is absent from some Fakestore users — default to empty string.
      suite: json['suite'] as String? ?? '',
      city: json['city'] as String? ?? '',
      zipcode: json['zipcode'] as String? ?? '',
      geolocation: GeoLocation.fromJson(
        json['geolocation'] as Map<String, dynamic>,
      ),
    );
  }

  /// Human-readable one-liner displayed on the profile card.
  /// Suite is omitted when empty (some Fakestore users don't have one).
  String get fullAddress {
    final parts = [street, if (suite.isNotEmpty) suite, '$city $zipcode'];
    return parts.join(', ');
  }
}

// ─── Name ───────────────────────────────────────────────────────────────────

/// Split first/last name as stored in the Fakestore schema.
class UserName {
  final String firstname;
  final String lastname;

  const UserName({required this.firstname, required this.lastname});

  factory UserName.fromJson(Map<String, dynamic> json) {
    return UserName(
      firstname: json['firstname'] as String,
      lastname: json['lastname'] as String,
    );
  }

  /// Full display name — e.g. "John Doe"
  String get fullName =>
      '${firstname[0].toUpperCase()}${firstname.substring(1)} '
      '${lastname[0].toUpperCase()}${lastname.substring(1)}';
}

// ─── User ───────────────────────────────────────────────────────────────────

/// Top-level user object returned by GET /users/{id}.
class User {
  final int id;
  final String email;
  final String username;
  final String password; // kept for completeness but never displayed
  final UserName name;
  final String phone;
  final Address address;

  const User({
    required this.id,
    required this.email,
    required this.username,
    required this.password,
    required this.name,
    required this.phone,
    required this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      name: UserName.fromJson(json['name'] as Map<String, dynamic>),
      phone: json['phone'] as String,
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
    );
  }
}
