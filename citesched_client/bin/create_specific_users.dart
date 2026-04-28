import 'package:citesched_client/citesched_client.dart';

const _defaultServerUrl = 'http://localhost:8083/';

class _AdminSeedAccount {
  const _AdminSeedAccount({
    required this.userName,
    required this.email,
    required this.password,
    required this.facultyId,
  });

  final String userName;
  final String email;
  final String password;
  final String facultyId;
}

const _adminAccounts = <_AdminSeedAccount>[
  _AdminSeedAccount(
    userName: 'Admin Test Account',
    email: 'admin.user@jmc.edu.ph',
    password: 'password123',
    facultyId: '12345',
  ),
  _AdminSeedAccount(
    userName: 'Admin Support Account',
    email: 'admin.support@jmc.edu.ph',
    password: 'password123',
    facultyId: '54321',
  ),
];

void main(List<String> args) async {
  final serverUrl = _resolveServerUrl(args);
  var client = Client(serverUrl);
  client.connectivityMonitor = null;

  try {
    print('--------------------------------------------------');
    print('Creating admin accounts via $serverUrl');
    print('--------------------------------------------------');

    for (final account in _adminAccounts) {
      final success = await client.setup.createAccount(
        userName: account.userName,
        email: account.email,
        password: account.password,
        role: 'admin',
        facultyId: account.facultyId,
      );

      if (success) {
        print(
          'SUCCESS: Created ${account.userName} with ID ${account.facultyId}',
        );
      } else {
        print('WARNING: Could not create ${account.userName}.');
        print(
          'Reason: ID ${account.facultyId} or email ${account.email} might already be taken.',
        );
      }

      print('--------------------------------------------------');
    }
  } catch (e) {
    print('Error: $e');
  }
}

String _resolveServerUrl(List<String> args) {
  for (final argument in args) {
    if (argument.startsWith('--server=')) {
      return _normalizeServerUrl(argument.substring('--server='.length));
    }
  }

  final definedServerUrl = const String.fromEnvironment('CITESCHED_SERVER_URL');
  if (definedServerUrl.isNotEmpty) {
    return _normalizeServerUrl(definedServerUrl);
  }

  return _normalizeServerUrl(_defaultServerUrl);
}

String _normalizeServerUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.endsWith('/')) return trimmed;
  return '$trimmed/';
}
