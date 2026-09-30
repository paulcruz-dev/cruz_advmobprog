import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onSignedOut});

  final VoidCallback onSignedOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = UserService().getUserData();
  }

  // ENHANCEMENT 3: profile is rendered directly from the saved User model.
  Future<void> _logout() async {
    await UserService().signOut();
    if (!mounted) return;
    widget.onSignedOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
  }

  Future<void> _editUsername(User user) async {
    final controller = TextEditingController(text: user.username);
    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update username'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (username == null || username.length < 3) {
      if (username != null && mounted) {
        _showMessage('Username must have at least 3 characters.');
      }
      return;
    }
    try {
      final updatedUser = await UserService().updateUsername(username);
      if (mounted) setState(() => _userFuture = Future.value(updatedUser));
    } catch (error) {
      if (mounted) _showMessage(_messageFor(error));
    }
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final values = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password (6+ characters)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, [
              currentPasswordController.text,
              newPasswordController.text,
            ]),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    currentPasswordController.dispose();
    newPasswordController.dispose();
    if (values == null) return;
    if (values[0].isEmpty || values[1].length < 6) {
      _showMessage(
        'Enter your current password and a new password with at least 6 characters.',
      );
      return;
    }
    try {
      await UserService().resetPasswordFromCurrentPassword(
        currentPassword: values[0],
        newPassword: values[1],
      );
      if (mounted) _showMessage('Password updated.');
    } catch (error) {
      if (mounted) _showMessage(_messageFor(error));
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes a Firebase account. DummyJSON accounts only have their local session removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await UserService().deleteAccount();
      if (!mounted) return;
      widget.onSignedOut();
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/signin', (route) => false);
    } catch (error) {
      if (mounted) {
        _showMessage(
          '${_messageFor(error)} Re-enter your password by signing in again, then retry.',
        );
      }
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  String _messageFor(Object error) => error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('firebase_auth/', '');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data!;
        return ListView(
          padding: EdgeInsets.all(20.r),
          children: [
            Center(
              child: CircleAvatar(
                radius: 49.r,
                backgroundColor: const Color(0xFFFFC107),
                backgroundImage: user.image.isEmpty
                    ? null
                    : NetworkImage(user.image),
                child: user.image.isEmpty
                    ? Icon(Icons.person, size: 48.sp, color: Colors.black87)
                    : null,
              ),
            ),
            SizedBox(height: 14.h),
            CustomText(
              text: user.fullName.isEmpty ? user.username : user.fullName,
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            CustomText(
              text: '@${user.username}',
              fontSize: 13.sp,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            _profileTile(Icons.email_outlined, 'Email', user.email),
            _profileTile(
              Icons.login_outlined,
              'Login type',
              user.loginType == LoginType.firebase
                  ? 'Firebase Authentication'
                  : 'DummyJSON',
            ),
            _profileTile(Icons.badge_outlined, 'User ID', '${user.id}'),
            _profileTile(
              Icons.person_outline,
              'Gender',
              user.gender.isEmpty ? 'Not specified' : user.gender,
            ),
            if (user.age > 0)
              _profileTile(Icons.cake_outlined, 'Age', '${user.age}'),
            if (user.contactNo.isNotEmpty)
              _profileTile(
                Icons.phone_outlined,
                'Contact number',
                user.contactNo,
              ),
            SizedBox(height: 14.h),
            OutlinedButton.icon(
              onPressed: () => _editUsername(user),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Update username'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
              ),
            ),
            if (user.loginType == LoginType.firebase)
              OutlinedButton.icon(
                onPressed: _changePassword,
                icon: const Icon(Icons.password_outlined),
                label: const Text('Change password'),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 14.h,
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _deleteAccount,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete account'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _profileTile(IconData icon, String label, String value) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF123B7A)),
        title: CustomText(text: label, fontSize: 12.sp),
        subtitle: CustomText(
          text: value,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
