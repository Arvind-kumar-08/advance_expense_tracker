import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../state/providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.sendPasswordResetEmail(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() => _emailSent = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Please check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Failed to send reset email',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final primary = theme.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: ForgotGridPainter(
              color: Colors.white.withOpacity(0.055),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        AppStrings.forgotPassword,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 22),

                          Center(
                            child: Container(
                              height: 108,
                              width: 108,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF111827),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              child: Icon(
                                Icons.lock_reset_rounded,
                                size: 58,
                                color: primary,
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          Text(
                            AppStrings.resetPassword,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 14),

                          Text(
                            'Enter your email address and we\'ll send you instructions to reset your password.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.65),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 34),

                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111827),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.10),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: !_emailSent
                                ? Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                              children: [
                                CustomTextField(
                                  label: AppStrings.email,
                                  hint: 'Enter your email',
                                  controller: _emailController,
                                  keyboardType:
                                  TextInputType.emailAddress,
                                  prefixIcon: Icons.email_outlined,
                                  validator: Validators.validateEmail,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) =>
                                      _handleResetPassword(),
                                ),

                                const SizedBox(height: 28),

                                CustomButton(
                                  text: authProvider.isLoading
                                      ? 'Sending...'
                                      : 'Send Reset Link',
                                  onPressed: _handleResetPassword,
                                  isLoading: authProvider.isLoading,
                                ),
                              ],
                            )
                                : Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.12),
                                    borderRadius:
                                    BorderRadius.circular(18),
                                    border: Border.all(
                                      color:
                                      Colors.green.withOpacity(0.55),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.green,
                                        size: 50,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Email Sent!',
                                        style: theme
                                            .textTheme.headlineSmall
                                            ?.copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'We\'ve sent password reset instructions to ${_emailController.text}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: Colors.white
                                              .withOpacity(0.65),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 28),

                                CustomButton(
                                  text: 'Back to Login',
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  isOutlined: true,
                                ),

                                const SizedBox(height: 16),

                                TextButton(
                                  onPressed: () {
                                    setState(() => _emailSent = false);
                                  },
                                  child: const Text('Resend Email'),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 34),

                          Text(
                            'Powered by Firebase',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.40),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ForgotGridPainter extends CustomPainter {
  final Color color;

  ForgotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const spacing = 38.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant ForgotGridPainter oldDelegate) => false;
}