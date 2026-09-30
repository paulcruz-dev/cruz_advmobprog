import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  // ENHANCEMENT 1: restore a saved session before showing the app shell.
  Future<void> _checkAuthentication() async {
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    final loggedIn = await _userService.isLoggedIn();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, loggedIn ? '/home' : '/signin');
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF123B7A);
    const gold = Color(0xFFFFC107);
    return Scaffold(
      backgroundColor: blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(18.r),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Image.asset('assets/images/nuicon.jpeg', width: 96.w, height: 96.w),
            ),
            SizedBox(height: 24.h),
            Text(
              'NU BD EXCHANGE',
              style: TextStyle(color: Colors.white, fontSize: 25.sp, fontWeight: FontWeight.w800, letterSpacing: 1.4),
            ),
            SizedBox(height: 8.h),
            Text('Campus marketplace', style: TextStyle(color: gold, fontSize: 14.sp)),
            SizedBox(height: 34.h),
            const CircularProgressIndicator(color: gold),
          ],
        ),
      ),
    );
  }
}
