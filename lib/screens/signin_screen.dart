import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';
import '../models/user.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'emilys');
  final _passwordController = TextEditingController(text: 'emilyspass');
  bool _isLoading = false;
  bool _obscurePassword = true;
  LoginType _loginType = LoginType.dummyJson;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ENHANCEMENT 2: validate input, use UserService, and persist the session.
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_loginType == LoginType.dummyJson) {
        await UserService().loginUser(
          _usernameController.text.trim(),
          _passwordController.text,
        );
      } else {
        await UserService().signIn(
          _usernameController.text.trim(),
          _passwordController.text,
        );
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF123B7A);
    const gold = Color(0xFFFFC107);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.r),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/nuicon.jpeg',
                      width: 108.w,
                      height: 108.w,
                    ),
                  ),
                  SizedBox(height: 22.h),
                  Text(
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: blue,
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Sign in to continue buying and selling.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.sp),
                  ),
                  SizedBox(height: 30.h),
                  SegmentedButton<LoginType>(
                    segments: const [
                      ButtonSegment(
                        value: LoginType.dummyJson,
                        label: Text('DummyJSON'),
                        icon: Icon(Icons.science_outlined),
                      ),
                      ButtonSegment(
                        value: LoginType.firebase,
                        label: Text('Firebase'),
                        icon: Icon(Icons.lock_outline),
                      ),
                    ],
                    selected: {_loginType},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _loginType = selection.first;
                        if (_loginType == LoginType.dummyJson) {
                          _usernameController.text = 'emilys';
                          _passwordController.text = 'emilyspass';
                        } else {
                          _usernameController.clear();
                          _passwordController.clear();
                        }
                      });
                    },
                  ),
                  SizedBox(height: 18.h),
                  TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    keyboardType: _loginType == LoginType.firebase
                        ? TextInputType.emailAddress
                        : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: _loginType == LoginType.firebase
                          ? 'Email address'
                          : 'Username',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _loginType == LoginType.firebase
                            ? 'Enter your email address'
                            : 'Enter your username';
                      }
                      if (_loginType == LoginType.firebase &&
                          !RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(value.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15.h),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onFieldSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your password'
                        : null,
                  ),
                  SizedBox(height: 22.h),
                  FilledButton(
                    onPressed: _isLoading ? null : _login,
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
                        : const Text('Sign In'),
                  ),
                  SizedBox(height: 16.h),
                  if (_loginType == LoginType.dummyJson)
                    Text(
                      'Demo account: emilys / emilyspass',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      child: const Text('New here? Create a Firebase account'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
