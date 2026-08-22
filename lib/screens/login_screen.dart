import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  static const String route = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _obscurePassword = true;
  final TextEditingController _emailController =
      TextEditingController(text: 'dental.assistant@danb.org');
  final TextEditingController _passwordController =
      TextEditingController(text: 'password123');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return AppScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: CircleIconButton(
                icon: Icons.close_rounded,
                background: colors.surface,
                iconColor: colors.primary,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Welcome to PrepMaster',
              textAlign: TextAlign.center,
              style: textStyles.h2,
            ),
            const SizedBox(height: 28),
            _SegmentedToggle(
              isLogin: _isLogin,
              onChanged: (v) => setState(() => _isLogin = v),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const _FieldLabel('Email Address'),
            const SizedBox(height: AppSpacing.sm),
            _RoundedTextField(
              controller: _emailController,
              hintText: 'dental.assistant@danb.org',
            ),
            const SizedBox(height: 18),
            const _FieldLabel('Password'),
            const SizedBox(height: AppSpacing.sm),
            _RoundedTextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: colors.onSurfaceVariant,
                  size: AppIconSize.medium,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: colors.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Get Started',
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed(HomeScreen.route),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text('or connect with', style: textStyles.bodySmall),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SocialButton(
                    icon: Icons.g_mobiledata_rounded,
                    label: 'Google',
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SocialButton(
                    icon: Icons.apple_rounded,
                    label: 'Apple',
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.colors.onSurface,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }
}

class _RoundedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  final Widget? suffixIcon;

  const _RoundedTextField({
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Fill color, border and hint style come from the app-wide
    // InputDecorationTheme (see AppTheme) so every text field stays
    // consistent; only content that varies per field is passed here.
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(
          color: context.colors.onSurface, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onChanged;

  const _SegmentedToggle({required this.isLogin, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        children: [
          Expanded(
              child:
                  _segment(context, 'Log In', isLogin, () => onChanged(true))),
          Expanded(
              child: _segment(
                  context, 'Sign Up', !isLogin, () => onChanged(false))),
        ],
      ),
    );
  }

  Widget _segment(
      BuildContext context, String label, bool selected, VoidCallback onTap) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? colors.surfaceContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: selected
              ? [
                  // Shadow color is intentionally invariant black across
                  // themes: it represents physical light occlusion, not a
                  // surface/text/icon role.
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colors.onSurface : colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton(
      {required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.surfaceContainer,
          foregroundColor: colors.onSurface,
          side: BorderSide(color: colors.outline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppIconSize.medium, color: colors.onSurface),
            const SizedBox(width: AppSpacing.sm),
            Text(label,
                style: TextStyle(
                    color: colors.onSurface, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
