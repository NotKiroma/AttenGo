import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    // Валидация
    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Заполните все обязательные поля');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Пароль должен содержать минимум 6 символов');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Пароли не совпадают');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await AuthService.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result.success) {
        // Автоматически входим после регистрации
        final loginResult = await AuthService.login(email: email, password: password);
        if (mounted) {
          if (loginResult.success) {
            // AuthWrapper переключит экран автоматически
            Navigator.popUntil(context, (route) => route.isFirst);
          } else {
            // Регистрация успешна, но вход не удался — возвращаем на логин
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Аккаунт создан. Войдите с вашим email и паролем.'),
                backgroundColor: Color(0xFF10232C),
              ),
            );
          }
        }
      } else {
        setState(() => _error = result.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final fs = w.clamp(320.0, 430.0);

    return Scaffold(
      backgroundColor: const Color(0xFF101C22),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF101C22),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: w * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: h * 0.02),

              // Заголовок
              Text(
                'Создать аккаунт',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fs * 0.065,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: h * 0.008),
              Text(
                'Заполните данные для регистрации',
                style: TextStyle(
                  color: const Color(0xFF7D92B1),
                  fontSize: fs * 0.038,
                ),
              ),

              SizedBox(height: h * 0.035),

              // Имя
              _label(fs, 'Имя'),
              SizedBox(height: h * 0.008),
              _inputField(
                fs: fs,
                controller: _firstNameCtrl,
                hint: 'Введите имя',
                icon: Icons.person_outline,
              ),

              SizedBox(height: h * 0.018),

              // Фамилия
              _label(fs, 'Фамилия'),
              SizedBox(height: h * 0.008),
              _inputField(
                fs: fs,
                controller: _lastNameCtrl,
                hint: 'Введите фамилию',
                icon: Icons.person_outline,
              ),

              SizedBox(height: h * 0.018),

              // Email
              _label(fs, 'Почта'),
              SizedBox(height: h * 0.008),
              _inputField(
                fs: fs,
                controller: _emailCtrl,
                hint: 'example@mail.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              SizedBox(height: h * 0.018),

              // Пароль
              _label(fs, 'Пароль'),
              SizedBox(height: h * 0.008),
              _inputField(
                fs: fs,
                controller: _passwordCtrl,
                hint: 'Минимум 6 символов',
                icon: Icons.lock_outline,
                obscure: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF7D92B1),
                    size: fs * 0.05,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              SizedBox(height: h * 0.018),

              // Подтверждение пароля
              _label(fs, 'Подтвердите пароль'),
              SizedBox(height: h * 0.008),
              _inputField(
                fs: fs,
                controller: _confirmCtrl,
                hint: 'Повторите пароль',
                icon: Icons.lock_outline,
                obscure: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF7D92B1),
                    size: fs * 0.05,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),

              // Ошибка
              if (_error != null) ...[
                SizedBox(height: h * 0.015),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(fs * 0.03),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF87171).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(fs * 0.03),
                    border: Border.all(color: const Color(0xFFF87171).withOpacity(0.3)),
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

              // Кнопка регистрации
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D59F2),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF0D59F2).withOpacity(0.5),
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
                      : Text('Зарегистрироваться', style: TextStyle(fontSize: fs * 0.042, fontWeight: FontWeight.w600)),
                ),
              ),

              SizedBox(height: h * 0.025),

              // Ссылка на логин
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Уже есть аккаунт? ',
                          style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036),
                        ),
                        TextSpan(
                          text: 'Войти',
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
