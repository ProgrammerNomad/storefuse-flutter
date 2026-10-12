import 'json_helpers.dart';

class Address {
  const Address({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.address1,
    this.address2,
    this.city,
    this.state,
    this.postcode,
    this.country,
  });

  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? address1;
  final String? address2;
  final String? city;
  final String? state;
  final String? postcode;
  final String? country;

  factory Address.fromJson(JsonMap json) {
    return Address(
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      address1: json['address_1']?.toString(),
      address2: json['address_2']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      postcode: json['postcode']?.toString(),
      country: json['country']?.toString(),
    );
  }

  JsonMap toJson() => {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (address1 != null) 'address_1': address1,
        if (address2 != null) 'address_2': address2,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (postcode != null) 'postcode': postcode,
        if (country != null) 'country': country,
      };

  String get formattedLines {
    final parts = <String>[
      if (firstName != null || lastName != null)
        '${firstName ?? ''} ${lastName ?? ''}'.trim(),
      if (address1 != null && address1!.isNotEmpty) address1!,
      if (address2 != null && address2!.isNotEmpty) address2!,
      if (city != null || state != null || postcode != null)
        [city, state, postcode].where((e) => e != null && e.isNotEmpty).join(', '),
      if (country != null && country!.isNotEmpty) country!,
      if (email != null && email!.isNotEmpty) email!,
      if (phone != null && phone!.isNotEmpty) phone!,
    ];
    return parts.join('\n');
  }
}
