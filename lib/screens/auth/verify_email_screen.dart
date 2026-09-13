import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    // Poll every 3 seconds to check if user clicked the verification link
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await context.read<AuthProvider>().checkEmailVerified();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    final success = await context
        .read<AuthProvider>()
        .resendVerificationEmail();
    if (mounted) {
      setState(() => _isResending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Verification email sent' : 'Failed to send email',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread, size: 64),
            const SizedBox(height: 16),
            const Text(
              'We sent a verification link to your email. '
              'Please click it to continue.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isResending ? null : _resend,
              child: _isResending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Resend Email'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.read<AuthProvider>().signOut(),
              child: const Text('Cancel / Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
