import 'dart:math';

class ForgedIdentity {
  final String fullName;
  final String dob;
  final String ssn;
  final String address;
  final String phone;
  final String email;
  final String passport;
  final String creditCard;
  final String bitcoinWallet;
  final String nationality;

  ForgedIdentity({
    required this.fullName, required this.dob, required this.ssn,
    required this.address, required this.phone, required this.email,
    required this.passport, required this.creditCard, required this.bitcoinWallet,
    required this.nationality,
  });
}

class IdentityForgery {
  final List<ForgedIdentity> _generatedIdentities = [];
  final Random _random = Random();

  List<ForgedIdentity> get generatedIdentities => _generatedIdentities;

  ForgedIdentity generateUSIdentity() {
    final firstNames = ['James', 'John', 'Robert', 'Michael', 'William', 'David', 'Richard', 'Joseph', 'Thomas', 'Charles'];
    final lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez'];
    final streets = ['123 Main St', '456 Oak Ave', '789 Pine Rd', '321 Elm Dr', '654 Maple Ln', '987 Cedar Blvd', '147 Birch Ct', '258 Walnut Way'];
    final cities = ['New York, NY', 'Los Angeles, CA', 'Chicago, IL', 'Houston, TX', 'Phoenix, AZ', 'Philadelphia, PA', 'San Antonio, TX', 'San Diego, CA'];
    final domains = ['gmail.com', 'outlook.com', 'protonmail.com', 'tutanota.com', 'yahoo.com'];

    final firstName = firstNames[_random.nextInt(firstNames.length)];
    final lastName = lastNames[_random.nextInt(lastNames.length)];
    final year = 1950 + _random.nextInt(50);
    final month = (_random.nextInt(12) + 1).toString().padLeft(2, '0');
    final day = (_random.nextInt(28) + 1).toString().padLeft(2, '0');
    final ssn = '${_random.nextInt(900) + 100}-${_random.nextInt(90) + 10}-${_random.nextInt(9000) + 1000}';
    final street = streets[_random.nextInt(streets.length)];
    final city = cities[_random.nextInt(cities.length)];
    final zip = '${_random.nextInt(90000) + 10000}';
    final phone = '+1 (${_random.nextInt(900) + 100}) ${_random.nextInt(900) + 100}-${_random.nextInt(9000) + 1000}';
    final email = '${firstName.toLowerCase()}.${lastName.toLowerCase()}${_random.nextInt(999)}@${domains[_random.nextInt(domains.length)]}';
    final passport = '${_random.nextInt(900000000) + 100000000}';
    final cc = '${_random.nextInt(4) + 4}${List.generate(15, (_) => _random.nextInt(10)).join()}';
    final btc = 'bc1${List.generate(38, (_) => 'abcdef0123456789'[_random.nextInt(16)]).join()}';

    final identity = ForgedIdentity(
      fullName: '$firstName $lastName',
      dob: '$month/$day/$year',
      ssn: ssn,
      address: '$street, $city $zip',
      phone: phone,
      email: email,
      passport: passport,
      creditCard: cc,
      bitcoinWallet: btc,
      nationality: 'United States',
    );

    _generatedIdentities.add(identity);
    return identity;
  }

  ForgedIdentity generateEUIdentity() {
    final identity = generateUSIdentity();
    final euCountries = ['United Kingdom', 'Germany', 'France', 'Italy', 'Spain', 'Netherlands', 'Sweden', 'Poland'];
    // تعديل بسيط للجنسية
    _generatedIdentities.remove(identity);
    final euIdentity = ForgedIdentity(
      fullName: identity.fullName,
      dob: identity.dob,
      ssn: identity.ssn,
      address: identity.address,
      phone: identity.phone,
      email: identity.email,
      passport: identity.passport,
      creditCard: identity.creditCard,
      bitcoinWallet: identity.bitcoinWallet,
      nationality: euCountries[_random.nextInt(euCountries.length)],
    );
    _generatedIdentities.add(euIdentity);
    return euIdentity;
  }

  Map<String, dynamic> generateFullPackage() {
    final identity = generateUSIdentity();
    return {
      'identity': identity,
      'digital_fingerprint': _generateDigitalFingerprint(),
      'social_media': _generateSocialMedia(identity.fullName),
      'documents': _generateDocumentList(),
    };
  }

  Map<String, dynamic> _generateDigitalFingerprint() {
    return {
      'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0',
      'screen_resolution': '1920x1080',
      'timezone': 'America/New_York',
      'language': 'en-US',
    };
  }

  List<Map<String, String>> _generateSocialMedia(String name) {
    final username = name.toLowerCase().replaceAll(' ', '.');
    return [
      {'platform': 'Twitter', 'url': 'https://twitter.com/$username'},
      {'platform': 'LinkedIn', 'url': 'https://linkedin.com/in/$username'},
      {'platform': 'GitHub', 'url': 'https://github.com/$username'},
    ];
  }

  List<String> _generateDocumentList() {
    return [
      'Passport (Scanned)',
      'Driver License (Scanned)',
      'Utility Bill (PDF)',
      'Bank Statement (PDF)',
      'Social Security Card (Scanned)',
      'Credit Card (Front/Back)',
    ];
  }
}
