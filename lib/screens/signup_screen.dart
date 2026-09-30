import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _contactNoController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await UserService().createAccount(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        contactNo: _contactNoController.text.trim(),
        username: _usernameController.text.trim(),
        emailAddress: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(error))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _required(String? value, String label) {
    return value == null || value.trim().isEmpty ? 'Enter your $label' : null;
  }

  String _messageFor(Object error) => error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('firebase_auth/', '');

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF123B7A);
    const gold = Color(0xFFFFC107);
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join NU BD Exchange',
                  style: TextStyle(
                    color: blue,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6.h),
                const Text(
                  'Your email and password are secured by Firebase Authentication.',
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        _firstNameController,
                        'First name',
                        validator: (value) => _required(value, 'first name'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _textField(
                        _lastNameController,
                        'Last name',
                        validator: (value) => _required(value, 'last name'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                _textField(
                  _ageController,
                  'Age',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final age = int.tryParse(value?.trim() ?? '');
                    return age == null || age < 13 || age > 120
                        ? 'Enter an age from 13 to 120'
                        : null;
                  },
                ),
                SizedBox(height: 14.h),
                _textField(
                  _contactNoController,
                  'Contact number',
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      RegExp(r'^[0-9+ -]{7,20}$').hasMatch(value?.trim() ?? '')
                      ? null
                      : 'Enter a valid contact number',
                ),
                SizedBox(height: 14.h),
                _textField(
                  _usernameController,
                  'Username',
                  validator: (value) => (value?.trim().length ?? 0) >= 3
                      ? null
                      : 'Use at least 3 characters',
                ),
                SizedBox(height: 14.h),
                _textField(
                  _emailController,
                  'Email address',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(value?.trim() ?? '')
                      ? null
                      : 'Enter a valid email address',
                ),
                SizedBox(height: 14.h),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) => (value?.length ?? 0) >= 6
                      ? null
                      : 'Use at least 6 characters',
                  onFieldSubmitted: (_) => _createAccount(),
                ),
                SizedBox(height: 24.h),
                FilledButton(
                  onPressed: _isLoading ? null : _createAccount,
                  style: FilledButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: Colors.black87,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                  child: _isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: blue,
                          ),
                        )
                      : const Text('Create Firebase account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
