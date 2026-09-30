import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class UserService {
  static const _baseUrl = 'https://dummyjson.com/auth';
  static const _sessionKey = 'user_session';

  final firebase.FirebaseAuth _firebaseAuth;

  UserService({
    firebase.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<User> loginUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Incorrect username or password.');
    }

    final user = User.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    await saveUserData(user);
    return user;
  }

  /// Signs in with Firebase email/password and stores a refreshable session.
  Future<User> signIn(String emailAddress, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: emailAddress,
      password: password,
    );
    final savedUser = await getUserData();
    final user = await _firebaseUserToAppUser(
      credential.user!,
      existingUser: savedUser.loginType == LoginType.firebase
          ? savedUser
          : null,
    );
    await _syncFirebaseChatProfile(credential.user!, user);
    await saveUserData(user);
    return user;
  }

  /// Creates the Firebase account. Firebase Auth stores email/password and
  /// display name; the remaining lab profile fields are stored locally.
  Future<User> createAccount({
    required String firstName,
    required String lastName,
    required int age,
    required String contactNo,
    required String username,
    required String emailAddress,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: emailAddress,
      password: password,
    );
    final firebaseUser = credential.user!;
    await firebaseUser.updateDisplayName(username);
    await firebaseUser.reload();
    final user = await _firebaseUserToAppUser(
      _firebaseAuth.currentUser!,
      existingUser: User(
        id: 0,
        username: username,
        email: emailAddress,
        firstName: firstName,
        lastName: lastName,
        gender: '',
        image: '',
        accessToken: '',
        refreshToken: '',
        age: age,
        contactNo: contactNo,
        loginType: LoginType.firebase,
      ),
    );
    await _syncFirebaseChatProfile(_firebaseAuth.currentUser!, user);
    await saveUserData(user);
    return user;
  }

  // ENHANCEMENT 1: persist the complete authenticated user for future launches.
  Future<void> saveUserData(User user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionKey, jsonEncode(user.toJson()));
  }

  Future<User> getUser() async {
    final preferences = await SharedPreferences.getInstance();
    final rawSession = preferences.getString(_sessionKey);
    if (rawSession == null || rawSession.isEmpty) {
      return User.fromJson(const {});
    }
    return User.fromJson(jsonDecode(rawSession) as Map<String, dynamic>);
  }

  /// Required by the profile screen; named separately for the lab API.
  Future<User> getUserData() => getUser();

  // ENHANCEMENT 1: splash uses this to restore a persisted login session.
  Future<bool> isLoggedIn() async {
    final user = await getUser();
    if (user.loginType == LoginType.firebase) {
      return _firebaseAuth.currentUser != null;
    }
    return user.accessToken.isNotEmpty;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
  }

  Future<void> logout() => signOut();

  Future<User> updateUsername(String username) async {
    final currentUser = await getUserData();
    if (currentUser.loginType == LoginType.firebase) {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw Exception('Your Firebase session has expired.');
      }
      await firebaseUser.updateDisplayName(username);
      await firebaseUser.reload();
    }
    final updatedUser = currentUser.copyWith(username: username);
    if (currentUser.loginType == LoginType.firebase) {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await _syncFirebaseChatProfile(firebaseUser, updatedUser);
      }
    }
    await saveUserData(updatedUser);
    return updatedUser;
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw Exception(
        'Password changes are available for Firebase accounts only.',
      );
    }
    final emailAddress = firebaseUser.email;
    if (emailAddress == null) {
      throw Exception('This account has no email address.');
    }
    final credential = firebase.EmailAuthProvider.credential(
      email: emailAddress,
      password: currentPassword,
    );
    await firebaseUser.reauthenticateWithCredential(credential);
    await firebaseUser.updatePassword(newPassword);
  }

  Future<void> deleteAccount() async {
    final currentUser = await getUserData();
    if (currentUser.loginType == LoginType.firebase) {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw Exception('Your Firebase session has expired.');
      }
      await _firestore.collection('users').doc(firebaseUser.uid).delete();
      await firebaseUser.delete();
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
  }

  Future<User> _firebaseUserToAppUser(
    firebase.User firebaseUser, {
    User? existingUser,
  }) async {
    final token = await firebaseUser.getIdToken(true) ?? '';
    return User(
      id: firebaseUser.uid.hashCode & 0x7fffffff,
      username:
          firebaseUser.displayName ??
          existingUser?.username ??
          firebaseUser.email?.split('@').first ??
          '',
      email: firebaseUser.email ?? existingUser?.email ?? '',
      firstName: existingUser?.firstName ?? '',
      lastName: existingUser?.lastName ?? '',
      gender: existingUser?.gender ?? '',
      image: firebaseUser.photoURL ?? existingUser?.image ?? '',
      accessToken: token,
      refreshToken: '',
      age: existingUser?.age ?? 0,
      contactNo: existingUser?.contactNo ?? '',
      loginType: LoginType.firebase,
    );
  }

  Future<void> _syncFirebaseChatProfile(firebase.User firebaseUser, User user) {
    final displayName = user.username.isNotEmpty
        ? user.username
        : firebaseUser.displayName ??
              firebaseUser.email?.split('@').first ??
              'User';
    return _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set({
          'displayName': displayName,
          'displayNameLower': displayName.toLowerCase(),
          'email': firebaseUser.email ?? user.email,
          'photoUrl': firebaseUser.photoURL ?? user.image,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => throw Exception(
            'Firestore did not respond. Create the Firestore database and publish its lab rules, then try again.',
          ),
        );
  }
}
