import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class TestUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  bool emailVerified;
  @override
  String? displayName;
  @override
  String? photoURL;
  @override
  String? get phoneNumber => null;
  @override
  List<UserInfo> get providerData => [TestUserInfo()];
  Object? sendError;
  Object? profileError;
  Object? reauthError;
  Object? passwordError;
  int sends = 0;
  final calls = <String>[];
  TestUser({
    this.uid = 'test-user',
    this.email = 'person@example.com',
    this.emailVerified = true,
    this.displayName = 'Sample Person',
    this.photoURL,
  });
  @override
  Future<void> sendEmailVerification([
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    sends++;
    if (sendError != null) throw sendError!;
  }

  @override
  Future<void> reload() async {}
  @override
  Future<void> updateDisplayName(String? name) async {
    if (profileError != null) throw profileError!;
    displayName = name;
  }

  @override
  Future<void> updatePhotoURL(String? url) async {
    if (profileError != null) throw profileError!;
    photoURL = url;
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    calls.add('reauthenticate');
    if (reauthError != null) throw reauthError!;
    return TestCredential(this);
  }

  @override
  Future<void> updatePassword(String password) async {
    calls.add('updatePassword');
    if (passwordError != null) throw passwordError!;
  }
}

class TestUserInfo extends Fake implements UserInfo {
  @override
  String get providerId => 'password';
}

class TestCredential extends Fake implements UserCredential {
  @override
  final User user;
  TestCredential(this.user);
}

class TestAuth extends Fake implements FirebaseAuth {
  @override
  User? currentUser;
  Object? signInError;
  int signInCalls = 0;
  TestAuth(this.currentUser);
  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    if (signInError != null) throw signInError!;
    return TestCredential(currentUser!);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) => signInWithEmailAndPassword(email: email, password: password);
  @override
  Future<void> signOut() async {
    currentUser = null;
  }
}
