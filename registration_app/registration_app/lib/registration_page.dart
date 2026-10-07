import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'user_info_page.dart';
import 'user_storage.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  // Ключ формы - через него запускается validate() для всех полей сразу
  final _formKey = GlobalKey<FormState>();

  // Controller для каждого TextFormField
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _storyController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();

  // FocusNode для каждого TextFormField
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _storyFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();

  // Состояние видимости паролей (obscureText + suffixIcon)
  bool _hidePass = true;
  bool _hideConfirm = true;

  static final _emailRegex =
      RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)*\.[a-zA-Z]{2,}$');
  static final _digitsRegex = RegExp(r'^\d+$');

  @override
  void dispose() {
    // Освобождаем ресурсы
    for (final c in [
      _nameController,
      _phoneController,
      _emailController,
      _storyController,
      _passController,
      _confirmController,
    ]) {
      c.dispose();
    }
    for (final f in [
      _nameFocus,
      _phoneFocus,
      _emailFocus,
      _storyFocus,
      _passFocus,
      _confirmFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  // ---------------- Валидаторы ----------------

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Phone number is required';
    if (!_digitsRegex.hasMatch(phone)) {
      return 'Phone number must contain digits only';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email address is required';
    if (!_emailRegex.hasMatch(email)) {
      return 'Enter a valid email (example: name@mail.com)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm the password';
    if (value != _passController.text) return 'Passwords do not match';
    return null;
  }

  // ---------------- Логика ----------------

  /// Переводит фокус на первое поле с ошибкой.
  void _focusFirstInvalid() {
    final checks = [
      (_nameFocus, _validateName(_nameController.text)),
      (_phoneFocus, _validatePhone(_phoneController.text)),
      (_emailFocus, _validateEmail(_emailController.text)),
      (_passFocus, _validatePassword(_passController.text)),
      (_confirmFocus, _validateConfirm(_confirmController.text)),
    ];
    for (final (focus, error) in checks) {
      if (error != null) {
        focus.requestFocus();
        break;
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _focusFirstInvalid();
      return;
    }

    // Сохраняем данные локально через SharedPreferences
    await UserStorage.save(
      UserData(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        story: _storyController.text.trim(),
      ),
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration successful! Data saved.')),
    );

    // Переходим на вторую страницу. Если там нажали "Delete saved data",
    // вернётся true - тогда очищаем форму.
    final cleared = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const UserInfoPage()),
    );
    if (!mounted) return;
    if (cleared == true) {
      _formKey.currentState?.reset();
      setState(() {
        _hidePass = true;
        _hideConfirm = true;
      });
    }
  }

  // ---------------- Оформление ----------------

  OutlineInputBorder _roundedBorder(Color color, {double width = 1.5}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Красная иконка-корзина для очистки поля
  Widget _clearButton(TextEditingController controller) {
    return IconButton(
      icon: const Icon(Icons.delete_outline, color: Colors.red),
      onPressed: controller.clear,
    );
  }

  /// Скруглённое поле с чёрной рамкой (как Full Name и Phone на скриншоте)
  InputDecoration _roundedDecoration({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: Icon(icon),
      suffixIcon: _clearButton(controller),
      enabledBorder: _roundedBorder(Colors.black),
      focusedBorder: _roundedBorder(Colors.blue, width: 2),
      errorBorder: _roundedBorder(Colors.red),
      focusedErrorBorder: _roundedBorder(Colors.red, width: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Register Form',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              // Full Name
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocus,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                decoration: _roundedDecoration(
                  label: 'Full Name *',
                  icon: Icons.person,
                  controller: _nameController,
                ),
                validator: _validateName,
                onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
              ),
              const SizedBox(height: 16),

              // Phone Number (только цифры)
              TextFormField(
                controller: _phoneController,
                focusNode: _phoneFocus,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _roundedDecoration(
                  label: 'Phone Number *',
                  icon: Icons.phone,
                  controller: _phoneController,
                  helper: 'Phone format: digits only (e.g. 87771234567)',
                ),
                validator: _validatePhone,
                onFieldSubmitted: (_) => _emailFocus.requestFocus(),
              ),
              const SizedBox(height: 16),

              // Email Address
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  prefixIcon: Icon(Icons.mail),
                ),
                validator: _validateEmail,
                onFieldSubmitted: (_) => _storyFocus.requestFocus(),
              ),
              const SizedBox(height: 24),

              // Life Story (необязательное многострочное поле)
              TextFormField(
                controller: _storyController,
                focusNode: _storyFocus,
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Life Story',
                  helperText: 'Keep it short, this is just a demo',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Password (obscureText + suffixIcon для показа/скрытия)
              TextFormField(
                controller: _passController,
                focusNode: _passFocus,
                textInputAction: TextInputAction.next,
                obscureText: _hidePass,
                maxLength: 16,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  prefixIcon: const Icon(Icons.security),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _hidePass ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _hidePass = !_hidePass),
                  ),
                ),
                validator: _validatePassword,
                onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
              ),
              const SizedBox(height: 8),

              // Confirm Password
              TextFormField(
                controller: _confirmController,
                focusNode: _confirmFocus,
                textInputAction: TextInputAction.done,
                obscureText: _hideConfirm,
                maxLength: 16,
                decoration: InputDecoration(
                  labelText: 'Confirm Password *',
                  prefixIcon: const Icon(Icons.border_color),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _hideConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _hideConfirm = !_hideConfirm),
                  ),
                ),
                validator: _validateConfirm,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade400,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _submit,
                  child: const Text(
                    'Submit Form',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
