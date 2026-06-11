import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/session_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscure = true, _obscureConfirm = true, _agreed = false, _loading = false;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  void _register() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your name and email')));
      return;
    }
    if (!_emailCtrl.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email')));
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to Terms & Privacy Policy')));
      return;
    }
    setState(() => _loading = true);
    await SessionService.instance
        .register(_nameCtrl.text, _emailCtrl.text, _phoneCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pushReplacementNamed(context, '/user/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios, size: 20),
            ),
            const SizedBox(height: 28),
            Center(child: Column(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('🏛️', style: TextStyle(fontSize: 28))),
              ),
              const SizedBox(height: 14),
              const Text('Create account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Register to book event venues',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            ])),
            const SizedBox(height: 28),
            _field('Full name', 'Ahmad Hassan', Icons.person_outline, _nameCtrl),
            const SizedBox(height: 14),
            _field('Email address', 'you@example.com', Icons.email_outlined, _emailCtrl,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _field('Phone number', '+60 12 345 6789', Icons.phone_outlined, _phoneCtrl,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            _passField('Password', _passCtrl, _obscure, () => setState(() => _obscure = !_obscure)),
            const SizedBox(height: 14),
            _passField('Confirm password', _confirmCtrl, _obscureConfirm,
                () => setState(() => _obscureConfirm = !_obscureConfirm)),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Checkbox(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v!),
                activeColor: AppTheme.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 6),
              Expanded(child: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  children: [
                    TextSpan(text: 'I agree to the '),
                    TextSpan(text: 'Terms of Service', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w500)),
                    TextSpan(text: ' & '),
                    TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w500)),
                  ],
                ),
              )),
            ]),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create Account'),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Already have an account? ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Login', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _field(String label, String hint, IconData icon, TextEditingController ctrl,
      {TextInputType keyboardType = TextInputType.text}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, size: 18)),
        ),
      ]);

  Widget _passField(String label, TextEditingController ctrl, bool obscure, VoidCallback toggle) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline, size: 18),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
              onPressed: toggle,
            ),
          ),
        ),
      ]);
}
