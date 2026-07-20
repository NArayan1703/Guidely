part of '../../main.dart';

class _ChangePasswordScreen extends StatefulWidget {
  const _ChangePasswordScreen();

  @override
  State<_ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<_ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || !_supabaseReady) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user?.email == null) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: user!.email!,
        password: _current.text,
      );
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _next.text),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => _MorePage(
    title: 'Change password',
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          _passwordField(_current, 'Current password'),
          _passwordField(_next, 'New password'),
          _passwordField(_confirm, 'Confirm new password', confirm: _next),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Updating…' : 'Update password'),
          ),
        ],
      ),
    ),
  );
}

Widget _passwordField(
  TextEditingController controller,
  String label, {
  TextEditingController? confirm,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: TextFormField(
    controller: controller,
    obscureText: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: (value) {
      if (value == null || value.length < 6) {
        return 'Use at least 6 characters';
      }
      if (confirm != null && value != confirm.text) {
        return 'Passwords do not match';
      }
      return null;
    },
  ),
);

class _ContactUsScreen extends StatefulWidget {
  const _ContactUsScreen({this.report = false});
  final bool report;

  @override
  State<_ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<_ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  final _contact = TextEditingController();
  String _reason = 'general_inquiry';
  XFile? _screenshot;
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    if (widget.report) _reason = 'report';
  }

  @override
  void dispose() {
    _message.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_supabaseReady) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _sending = true);
    try {
      String? screenshotPath;
      if (_screenshot != null) {
        final file = _screenshot!;
        final extension = file.name.contains('.')
            ? file.name.split('.').last
            : 'jpg';
        screenshotPath =
            '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$extension';
        await Supabase.instance.client.storage
            .from('support-attachments')
            .uploadBinary(
              screenshotPath,
              await file.readAsBytes(),
              fileOptions: FileOptions(contentType: file.mimeType),
            );
      }
      await Supabase.instance.client.from('contact_requests').insert({
        'user_id': user.id,
        'reason': _reason,
        'message': _message.text.trim(),
        'contact_details': _contact.text.trim().isEmpty
            ? null
            : _contact.text.trim(),
        'screenshot_path': screenshotPath,
      });
      if (mounted) {
        setState(() => _sent = true);
      }
    } on StorageException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return _MorePage(title: 'Request sent', child: const _SentConfirmation());
    }
    return _MorePage(
      title: widget.report ? 'Report a problem' : 'Contact us',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (!widget.report)
              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'booking_issue',
                    child: Text('Booking Issue'),
                  ),
                  DropdownMenuItem(
                    value: 'guide_complaint',
                    child: Text('Guide Complaint'),
                  ),
                  DropdownMenuItem(
                    value: 'general_inquiry',
                    child: Text('General Inquiry'),
                  ),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _reason = value!),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _message,
              minLines: 5,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a message'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contact,
              decoration: const InputDecoration(
                labelText: 'Email or phone (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (widget.report) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final image = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (mounted && image != null) {
                    setState(() => _screenshot = image);
                  }
                },
                icon: const Icon(Icons.attach_file),
                label: Text(
                  _screenshot == null
                      ? 'Attach screenshot (optional)'
                      : 'Screenshot attached',
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _sending ? null : _submit,
              child: Text(_sending ? 'Sending…' : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SentConfirmation extends StatelessWidget {
  const _SentConfirmation();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.only(top: 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: _primary),
          SizedBox(height: 16),
          Text(
            "We'll get back to you within 24 hours",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class _FaqScreen extends StatelessWidget {
  const _FaqScreen();
  static const _items = {
    'How do I book a guide?':
        'Open a package and send a booking request. Your guide will review it before it is confirmed.',
    'How do I pay the guide?':
        'Payment arrangements are agreed directly with your guide. Guidely does not process payments.',
    'What if my guide cancels?':
        'Use Contact us so our team can help you find another available guide.',
    'How do reviews work?':
        'After a completed trip, travellers can share an honest review of their guide.',
    'Is my personal data safe?':
        'We use your account details to run the marketplace and protect access with Supabase authentication and database policies.',
  };

  @override
  Widget build(BuildContext context) => _MorePage(
    title: 'Help Center',
    child: Column(
      children: _items.entries
          .map(
            (entry) => ExpansionTile(
              title: Text(entry.key),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(entry.value),
                ),
              ],
            ),
          )
          .toList(),
    ),
  );
}

class _AboutScreen extends StatelessWidget {
  const _AboutScreen();
  @override
  Widget build(BuildContext context) => const _MorePage(
    title: 'About Guidely',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Guidely 1.0.0',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 16),
        Text('Connecting tourists with trusted local guides across Nepal.'),
        SizedBox(height: 16),
        Text('Contact: hello@guidely.app'),
      ],
    ),
  );
}

class _LegalScreen extends StatelessWidget {
  const _LegalScreen({required this.privacy});
  final bool privacy;
  @override
  Widget build(BuildContext context) => _MorePage(
    title: privacy ? 'Privacy Policy' : 'Terms of Service',
    child: Text(
      privacy
          ? 'Guidely collects account details, profile information, trip requests, and guide verification documents to operate the marketplace. We limit access using authentication and database policies. We do not sell personal data.'
          : 'Guidely connects travellers with local guides. Guides and tourists arrange payment directly. Guidely does not process, hold, or guarantee tourist-guide payments.',
    ),
  );
}

class _MorePage extends StatelessWidget {
  const _MorePage({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(padding: const EdgeInsets.all(20), children: [child]),
  );
}
