import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:serverpod_auth_idp_server/src/generated/providers/google/models/google_account.dart'
    as auth_google;
import '../generated/protocol.dart';

class DebugEndpoint extends Endpoint {
  @override
  bool get requireLogin => false; // Allow public access to debug why auth fails

  Future<String> getSessionInfo(Session session) async {
    final authInfo = session.authenticated;
    final userId = authInfo?.userIdentifier;
    final scopes = authInfo?.scopes.map((s) => s.name).toList();

    UserInfo? userInfo;
    UserRole? userRole;
    auth_core.UserProfile? authCoreProfile;
    auth_google.GoogleAccount? googleAccount;

    if (userId != null) {
      final userIdentifier = userId.toString();
      final legacyUserInfoId = int.tryParse(userIdentifier);
      UuidValue? authUserId;
      try {
        authUserId = UuidValue.withValidation(userIdentifier);
      } catch (_) {
        authUserId = null;
      }

      if (legacyUserInfoId != null) {
        userInfo = await UserInfo.db.findById(session, legacyUserInfoId);
      }

      if (authUserId != null) {
        authCoreProfile = await auth_core.UserProfile.db.findFirstRow(
          session,
          where: (t) => t.authUserId.equals(authUserId),
        );
        googleAccount = await auth_google.GoogleAccount.db.findFirstRow(
          session,
          where: (t) => t.authUserId.equals(authUserId),
        );
      }

      userInfo ??= await UserInfo.db.findFirstRow(
        session,
        where: (t) => t.userIdentifier.equals(userIdentifier),
      );

      userInfo ??= await UserInfo.db.findFirstRow(
        session,
        where: (t) => t.email.equals(userIdentifier.toLowerCase()),
      );

      if (userInfo == null && authCoreProfile?.email != null) {
        userInfo = await UserInfo.db.findFirstRow(
          session,
          where: (t) => t.email.equals(authCoreProfile!.email!.toLowerCase()),
        );
      }

      if (userInfo == null && googleAccount?.email != null) {
        userInfo = await UserInfo.db.findFirstRow(
          session,
          where: (t) => t.email.equals(googleAccount!.email.toLowerCase()),
        );
      }

      if (userInfo?.id != null) {
        userRole = await UserRole.db.findFirstRow(
          session,
          where: (t) => t.userId.equals(userInfo!.id!.toString()),
        );
      }

      userRole ??= await UserRole.db.findFirstRow(
        session,
        where: (t) => t.userId.equals(userIdentifier),
      );
    }

    final resolvedEmail =
        userInfo?.email ?? authCoreProfile?.email ?? googleAccount?.email;
    final resolvedUserName =
        userInfo?.userName ??
        authCoreProfile?.fullName ??
        resolvedEmail?.split('@').first;
    final resolvedScopeNames = userInfo?.scopeNames ?? scopes ?? const [];

    final info = {
      'authenticatedUserId': userId?.toString(),
      'scopes': scopes ?? const <String>[],
      'authCoreProfileEmail': authCoreProfile?.email,
      'authCoreProfileFullName': authCoreProfile?.fullName,
      'googleAccountEmail': googleAccount?.email,
      'userInfoId': userInfo?.id,
      'email': resolvedEmail,
      'userName': resolvedUserName,
      'scopeNames': resolvedScopeNames,
      'resolvedRole': userRole?.role,
      'userRoleTableEntry': userRole?.toString(),
      'sessionDetails':
          'Session is ${authInfo == null ? "NOT" : ""} authenticated',
    };

    return SerializationManager.encode(info);
  }
}
