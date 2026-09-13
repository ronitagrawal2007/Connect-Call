import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_provider.dart';
import '../../providers/users_provider.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/common_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _formError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _formError = null);
    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(email: _email.text, password: _password.text);
    if (!mounted) return;
    if (!ok) {
      setState(() => _formError = auth.error ?? 'Could not log in. Try again.');
      return;
    }
    final user = auth.currentUser!;
    context.read<UsersProvider>().setSelfUid(user.uid);
    context.read<UsersProvider>().fetchUsers();
    context.read<CallProvider>().bindLocalUser(user);
    Navigator.pushReplacementNamed(context, AppConstants.routeHome);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                BrandMark(iconSize: 56, dark: isDark),
                const SizedBox(height: 24),
                Text('Welcome Back',
                    style: text.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Sign in to continue',
                    style: text.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (_formError != null) setState(() => _formError = null);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Email or Phone',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your email or phone';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {},
                    child: Text('Forgot password?',
                        style: text.bodySmall?.copyWith(color: scheme.primary)),
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<AuthProvider>(
                  builder: (_, auth, __) => CommonButton(
                    text: 'Login',
                    isLoading: auth.isLoading,
                    onPressed: _login,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR',
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                CommonButton(
                  text: 'Create Account',
                  isOutlined: true,
                  onPressed: () => Navigator.pushNamed(context, AppConstants.routeRegister),
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_formError!,
                        style: text.bodySmall?.copyWith(color: scheme.onErrorContainer)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
