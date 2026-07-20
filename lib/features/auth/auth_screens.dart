part of '../../main.dart';

enum _UserRole { traveller, admin }

class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - value)),
              child: child,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.terrain_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Guidely',
                style: TextStyle(
                  fontSize: 44,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: _primary,
                ),
                onPressed: () => Navigator.of(context).push(
                  PageRouteBuilder<void>(
                    pageBuilder: (_, _, _) =>
                        const _LoginScreen(role: _UserRole.traveller),
                    transitionDuration: const Duration(milliseconds: 320),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) =>
                            SlideTransition(
                              position:
                                  Tween<Offset>(
                                        begin: const Offset(0, 1),
                                        end: Offset.zero,
                                      )
                                      .chain(
                                        CurveTween(curve: Curves.easeOutCubic),
                                      )
                                      .animate(animation),
                              child: child,
                            ),
                  ),
                ),
                child: const Text('Get started'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _GuideRegistrationScreen(),
                  ),
                ),
                child: const Text('Are you a local guide? Register as a guide'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _GuideRegistrationScreen extends StatefulWidget {
  const _GuideRegistrationScreen();

  @override
  State<_GuideRegistrationScreen> createState() =>
      _GuideRegistrationScreenState();
}

class _GuideRegistrationScreenState extends State<_GuideRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _location = TextEditingController();
  final _bio = TextEditingController();
  final _experience = TextEditingController();
  final _languages = <String>{};
  final _categories = <String>{};
  bool _acceptedTerms = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _location.dispose();
    _bio.dispose();
    _experience.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_languages.isEmpty || _categories.isEmpty || !_acceptedTerms) {
      setState(
        () => _error =
            'Choose at least one language and category, then accept the terms.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        data: {
          'full_name': _name.text.trim(),
          'phone': _phone.text.trim(),
          'location': _location.text.trim(),
          'bio': _bio.text.trim(),
          'languages': _languages.toList(),
          'categories': _categories.toList(),
          'years_experience': int.parse(_experience.text),
          'accepted_terms': true,
          'requested_role': 'guide',
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check your email to confirm your guide account.'),
        ),
      );
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: _surface, surfaceTintColor: _surface),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Become a local guide',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start with your contact details. We’ll guide you through verification next.',
            style: TextStyle(color: _muted),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full name',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter your name'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value != null && value.contains('@')
                ? null
                : 'Enter a valid email address',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value != null &&
                    value.replaceAll(RegExp(r'[^0-9]'), '').length >= 7
                ? null
                : 'Enter a valid phone number',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value != null && value.length >= 6
                ? null
                : 'Use at least 6 characters',
          ),
          const SizedBox(height: 24),
          const Text(
            'Guide profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _location,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Primary location',
              hintText: 'e.g. Pokhara',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter your primary location'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _experience,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Years of guiding experience',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                int.tryParse(value ?? '') != null && int.parse(value!) >= 0
                ? null
                : 'Enter your years of experience',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bio,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Short bio',
              hintText: 'Tell travellers about your local experience.',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value != null && value.trim().length >= 20
                ? null
                : 'Write at least 20 characters',
          ),
          const SizedBox(height: 20),
          const Text(
            'Languages',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          Wrap(
            spacing: 8,
            children: ['English', 'नेपाली', 'Hindi', 'Chinese']
                .map(
                  (language) => FilterChip(
                    label: Text(language),
                    selected: _languages.contains(language),
                    onSelected: (selected) => setState(() {
                      selected
                          ? _languages.add(language)
                          : _languages.remove(language);
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Guide categories',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          Wrap(
            spacing: 8,
            children: ['Trekking', 'Culture', 'Adventure', 'Nature', 'Wellness']
                .map(
                  (category) => FilterChip(
                    label: Text(category),
                    selected: _categories.contains(category),
                    onSelected: (selected) => setState(() {
                      selected
                          ? _categories.add(category)
                          : _categories.remove(category);
                    }),
                  ),
                )
                .toList(),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _acceptedTerms,
            onChanged: (value) =>
                setState(() => _acceptedTerms = value ?? false),
            title: const Text(
              'I agree to the Terms of Service and verification requirements.',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: _primary,
            ),
            onPressed: _loading ? null : _register,
            child: Text(
              _loading ? 'Creating account…' : 'Start guide registration',
            ),
          ),
        ],
      ),
    ),
  );
}

class _LoginScreen extends StatefulWidget {
  const _LoginScreen({required this.role});

  final _UserRole role;

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _country = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _createAccount = false;
  bool _acceptedTerms = false;
  String _locale = 'en';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _country.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_createAccount && !_acceptedTerms) {
      setState(
        () => _error = 'Accept the terms and privacy policy to continue.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = _createAccount
          ? await Supabase.instance.client.auth.signUp(
              email: _email.text.trim(),
              password: _password.text,
              data: {
                'full_name': _name.text.trim(),
                'phone': _phone.text.trim(),
                'country': _country.text.trim(),
                'preferred_locale': _locale,
                'accepted_terms': true,
              },
            )
          : await Supabase.instance.client.auth.signInWithPassword(
              email: _email.text.trim(),
              password: _password.text,
            );
      if (_createAccount && response.session == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check your email to confirm your account.'),
            ),
          );
        }
        return;
      }
      final user = response.user;
      if (user == null) {
        throw const AuthException('Sign-in did not return a user.');
      }
      if (widget.role == _UserRole.admin) {
        if (user.appMetadata['role'] != 'admin') {
          await Supabase.instance.client.auth.signOut();
          throw const AuthException('This account is not an administrator.');
        }
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const _SessionGate()),
        (route) => false,
      );
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signInTitle = widget.role == _UserRole.admin
        ? 'Admin sign in'
        : 'Sign in';
    return Scaffold(
      appBar: AppBar(backgroundColor: _surface, surfaceTintColor: _surface),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                _createAccount ? 'Create account' : signInTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              if (_createAccount) ...[
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your full name'
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.mail_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value != null && value.contains('@')
                    ? null
                    : 'Enter a valid email address',
              ),
              const SizedBox(height: 16),
              if (_createAccount) ...[
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value != null &&
                          value.replaceAll(RegExp(r'[^0-9]'), '').length >= 7
                      ? null
                      : 'Enter a valid phone number',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _country,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    prefixIcon: Icon(Icons.public_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your country'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _locale,
                  decoration: const InputDecoration(
                    labelText: 'Preferred language',
                    prefixIcon: Icon(Icons.language_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'ne', child: Text('नेपाली')),
                  ],
                  onChanged: (value) => setState(() => _locale = value!),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value != null && value.length >= 6
                    ? null
                    : 'Use at least 6 characters',
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const _ForgotPasswordScreen(),
                          ),
                        ),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: _primary,
                ),
                onPressed: _loading ? null : _continue,
                child: Text(
                  _loading
                      ? (_createAccount ? 'Creating account…' : 'Signing in…')
                      : (_createAccount ? 'Create account' : 'Sign in'),
                ),
              ),
              if (widget.role == _UserRole.traveller)
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _createAccount = !_createAccount),
                  child: Text(
                    _createAccount
                        ? 'Already have an account? Sign in'
                        : 'New to Guidely? Create an account',
                  ),
                ),
              if (_createAccount)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _acceptedTerms,
                  onChanged: _loading
                      ? null
                      : (value) =>
                            setState(() => _acceptedTerms = value ?? false),
                  title: const Text(
                    'I agree to the Terms of Service and Privacy Policy.',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              const SizedBox(height: 16),
              const Text(
                'By continuing, you agree to Guidely’s terms and privacy policy.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordScreen extends StatefulWidget {
  const _ForgotPasswordScreen();

  @override
  State<_ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<_ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _email.text.trim(),
        redirectTo: kIsWeb ? Uri.base.origin : 'guidely://reset-password',
      );
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: _surface, surfaceTintColor: _surface),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _sent
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: Color(0xFFD9F1EC),
                    child: Icon(
                      Icons.mark_email_read_outlined,
                      color: _primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Check your inbox',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We sent a password reset link to ${_email.text.trim()}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _muted, height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _sending ? null : _send,
                    child: const Text('Resend email'),
                  ),
                ],
              )
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      'Reset password',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your email and we’ll send you a reset link.',
                      style: TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (value) => value != null && value.contains('@')
                          ? null
                          : 'Enter a valid email address',
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _sending ? null : _send,
                      child: Text(_sending ? 'Sending…' : 'Send reset link'),
                    ),
                  ],
                ),
              ),
      ),
    ),
  );
}

class _UpdatePasswordScreen extends StatefulWidget {
  const _UpdatePasswordScreen();

  @override
  State<_UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<_UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _password.text),
      );
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _error;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: _surface, surfaceTintColor: _surface),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Set new password',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            _passwordField(_password, 'New password'),
            const SizedBox(height: 16),
            _passwordField(
              _confirm,
              'Confirm new password',
              confirm: _password,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Updating…' : 'Update password'),
            ),
          ],
        ),
      ),
    ),
  );
}
