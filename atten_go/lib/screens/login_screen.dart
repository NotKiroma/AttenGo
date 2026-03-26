import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/dark_page_route.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Заполните все поля');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await AuthService.login(email: email, password: password);

    if (mounted) {
      setState(() => _isLoading = false);
      if (!result.success) {
        setState(() => _error = result.error);
      }
      // При успешном входе AuthWrapper сам переключит экран
    }
  }

  void _goToRegister() {
    Navigator.push(context, DarkPageRoute(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final fs = w.clamp(320.0, 430.0);

    return Scaffold(
      backgroundColor: const Color(0xFF101C22),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: w * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: h * 0.1),
              // Заголовок
              Center(
                child: Column(
                  children: [
                    Container(
                      width: fs * 0.2,
                      height: fs * 0.2,
                      decoration: const BoxDecoration(color: Color(0xFF0D59F2), shape: BoxShape.circle),
                      child: Icon(Icons.school_rounded, color: Colors.white, size: fs * 0.1),
                    ),
                    SizedBox(height: h * 0.025),
                    Text(
                      'Добро пожаловать',
                      style: TextStyle(color: Colors.white, fontSize: fs * 0.065, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: h * 0.008),
                    Text(
                      'Войдите в свой аккаунт',
                      style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.038),
                    ),
                  ],
                ),
              ),

              SizedBox(height: h * 0.05),

              // Email
              _label(fs, 'Почта'),
              SizedBox(height: h * 0.008),
              _inputField(
                fs: fs,
                controller: _emailCtrl,
                hint: 'example@mail.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),

              SizedBox(height: h * 0.02),

              // Пароль
              _label(fs, 'Пароль'),
              SizedBox(height: h * 0.008),
              _inputField(
                fs: fs,
                controller: _passwordCtrl,
                hint: 'Введите пароль',
                icon: Icons.lock_outline,
                obscure: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF7D92B1), size: fs * 0.05),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              // Ошибка
              if (_error != null) ...[
                SizedBox(height: h * 0.015),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(fs * 0.03),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF87171).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(fs * 0.03),
                    border: Border.all(color: const Color(0xFFF87171).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: const Color(0xFFF87171), size: fs * 0.045),
                      SizedBox(width: fs * 0.02),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: const Color(0xFFF87171), fontSize: fs * 0.033),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: h * 0.035),

              // Кнопка входа
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D59F2),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF0D59F2).withValues(alpha: 0.5),
                    padding: EdgeInsets.symmetric(vertical: h * 0.02),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs * 0.04)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: fs * 0.055,
                          height: fs * 0.055,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Войти',
                          style: TextStyle(fontSize: fs * 0.042, fontWeight: FontWeight.w600),
                        ),
                ),
              ),

              SizedBox(height: h * 0.03),

              // Ссылка на регистрацию
              Center(
                child: GestureDetector(
                  onTap: _goToRegister,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Нет аккаунта? ',
                          style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036),
                        ),
                        TextSpan(
                          text: 'Зарегистрироваться',
                          style: TextStyle(color: const Color(0xFF0D59F2), fontSize: fs * 0.036, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: h * 0.04),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(double fs, String text) {
    return Text(
      text,
      style: TextStyle(color: Colors.white, fontSize: fs * 0.038, fontWeight: FontWeight.w600),
    );
  }

  Widget _inputField({
    required double fs,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(fs * 0.04),
        border: Border.all(color: const Color(0xFF455664), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: TextStyle(color: Colors.white, fontSize: fs * 0.038),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.035),
          prefixIcon: Icon(icon, color: const Color(0xFF7D92B1), size: fs * 0.05),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.038),
        ),
      ),
    );
  }
}
