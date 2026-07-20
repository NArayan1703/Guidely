part of '../../main.dart';

class _GuideHome extends StatefulWidget {
  const _GuideHome();

  @override
  State<_GuideHome> createState() => _GuideHomeState();
}

class _GuideHomeState extends State<_GuideHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: IndexedStack(
        index: _tab,
        children: [
          _GuideDashboard(onSelectTab: (value) => setState(() => _tab = value)),
          const _GuidePackages(),
          const _GuideRequests(),
          const _GuideMoreTab(),
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (value) => setState(() => _tab = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.luggage_outlined),
          selectedIcon: Icon(Icons.luggage),
          label: 'Packages',
        ),
        NavigationDestination(
          icon: Icon(Icons.inbox_outlined),
          selectedIcon: Icon(Icons.inbox),
          label: 'Requests',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_rounded),
          selectedIcon: Icon(Icons.menu),
          label: 'More',
        ),
      ],
    ),
  );
}

class _GuideRequests extends StatefulWidget {
  const _GuideRequests();

  @override
  State<_GuideRequests> createState() => _GuideRequestsState();
}

class _GuideRequestsState extends State<_GuideRequests> {
  late Future<List<Map<String, dynamic>>> _requests;
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    _requests = _loadRequests();
  }

  Future<List<Map<String, dynamic>>> _loadRequests() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    final rows = await Supabase.instance.client
        .from('bookings')
        .select(
          'id, starts_on, headcount, trip_note, status, tour_packages(title)',
        )
        .eq('guide_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _respond(String requestId, String status) async {
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': status})
          .eq('id', requestId);
      if (mounted) setState(() => _requests = _loadRequests());
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _refresh() async {
    setState(() => _requests = _loadRequests());
    await _requests;
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _requests,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: FilledButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final requests = snapshot.data!
          .where((request) => request['status'] == _status)
          .toList();
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Trip requests',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: ['pending', 'accepted', 'completed']
                  .map(
                    (status) => ChoiceChip(
                      label: Text(
                        status[0].toUpperCase() + status.substring(1),
                      ),
                      selected: _status == status,
                      onSelected: (_) => setState(() => _status = status),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            if (requests.isEmpty)
              _EmptyTab(
                icon: Icons.inbox_outlined,
                title: 'No $_status trips',
                message: _status == 'pending'
                    ? 'New traveller requests will appear here.'
                    : 'Trips in this stage will appear here.',
              ),
            ...requests.map((request) {
              final package = request['tour_packages'] as Map<String, dynamic>?;
              return _FadeUp(
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package?['title'] as String? ?? 'Trip package',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 17,
                              color: _muted,
                            ),
                            const SizedBox(width: 6),
                            Text('${request['starts_on']}'),
                            const SizedBox(width: 14),
                            const Icon(
                              Icons.group_outlined,
                              size: 19,
                              color: _muted,
                            ),
                            const SizedBox(width: 5),
                            Text('${request['headcount']} travellers'),
                          ],
                        ),
                        if ((request['trip_note'] as String).isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              request['trip_note'] as String,
                              style: const TextStyle(
                                color: _muted,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (request['status'] == 'pending')
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _respond(
                                    request['id'] as String,
                                    'declined',
                                  ),
                                  child: const Text('Decline'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _respond(
                                    request['id'] as String,
                                    'accepted',
                                  ),
                                  child: const Text('Accept'),
                                ),
                              ),
                            ],
                          )
                        else if (request['status'] == 'accepted')
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => _respond(
                                request['id'] as String,
                                'completed',
                              ),
                              child: const Text('Mark completed'),
                            ),
                          )
                        else
                          const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: _primary),
                              SizedBox(width: 7),
                              Text(
                                'Trip completed',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    },
  );
}

class _GuideDashboard extends StatefulWidget {
  const _GuideDashboard({required this.onSelectTab});

  final ValueChanged<int> onSelectTab;

  @override
  State<_GuideDashboard> createState() => _GuideDashboardState();
}

class _GuideDashboardState extends State<_GuideDashboard> {
  late Future<Map<String, dynamic>> _dashboard;

  @override
  void initState() {
    super.initState();
    _dashboard = _loadDashboard();
  }

  Future<Map<String, dynamic>> _loadDashboard() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return {
        'name': 'Guide',
        'active': 0,
        'drafts': 0,
        'pending': 0,
        'upcoming': 0,
      };
    }
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('full_name')
        .eq('id', user.id)
        .maybeSingle();
    final packages = await Supabase.instance.client
        .from('tour_packages')
        .select('status')
        .eq('guide_id', user.id);
    final bookings = await Supabase.instance.client
        .from('bookings')
        .select('status')
        .eq('guide_id', user.id);
    return {
      'name': profile?['full_name'] as String? ?? 'Guide',
      'active': packages.where((item) => item['status'] == 'active').length,
      'drafts': packages.where((item) => item['status'] == 'draft').length,
      'pending': bookings.where((item) => item['status'] == 'pending').length,
      'upcoming': bookings.where((item) => item['status'] == 'accepted').length,
    };
  }

  Future<void> _refresh() async {
    setState(() => _dashboard = _loadDashboard());
    await _dashboard;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _dashboard,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: FilledButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final data = snapshot.data!;
      final name = (data['name'] as String).trim().split(RegExp(r'\s+')).first;
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Welcome back, $name',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            const Text(
              'Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                _GuideStat(
                  value: data['active'] as int,
                  label: 'Active packages',
                  icon: Icons.explore_rounded,
                ),
                _GuideStat(
                  value: data['pending'] as int,
                  label: 'New requests',
                  icon: Icons.inbox_rounded,
                ),
                _GuideStat(
                  value: data['upcoming'] as int,
                  label: 'Upcoming',
                  icon: Icons.calendar_month_rounded,
                ),
                _GuideStat(
                  value: data['drafts'] as int,
                  label: 'Drafts',
                  icon: Icons.edit_note_rounded,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if ((data['pending'] as int) > 0)
              _GuideAction(
                icon: Icons.inbox_rounded,
                label:
                    'Review ${data['pending']} new request${data['pending'] == 1 ? '' : 's'}',
                onTap: () => widget.onSelectTab(2),
              ),
            const Text(
              'Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _GuideAction(
              icon: Icons.add_rounded,
              label: 'Create package',
              onTap: () => widget.onSelectTab(1),
            ),
            _GuideAction(
              icon: Icons.inbox_outlined,
              label: 'View trip requests',
              onTap: () => widget.onSelectTab(2),
            ),
            _GuideAction(
              icon: Icons.person_outline_rounded,
              label: 'Edit guide profile',
              onTap: () => widget.onSelectTab(3),
            ),
          ],
        ),
      );
    },
  );
}

class _GuideStat extends StatelessWidget {
  const _GuideStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  final int value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _FadeUp(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _primary, size: 20),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      ),
    ),
  );
}

class _GuidePackages extends StatefulWidget {
  const _GuidePackages();

  @override
  State<_GuidePackages> createState() => _GuidePackagesState();
}

class _GuidePackagesState extends State<_GuidePackages> {
  late Future<List<Map<String, dynamic>>> _packages;

  @override
  void initState() {
    super.initState();
    _packages = _loadPackages();
  }

  Future<List<Map<String, dynamic>>> _loadPackages() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    final rows = await Supabase.instance.client
        .from('tour_packages')
        .select(
          'id, title, category, duration_days, capacity, price_npr, status, description, highlights, cover_path',
        )
        .eq('guide_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _createPackage() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const _CreatePackageScreen()),
    );
    if (created == true && mounted) setState(() => _packages = _loadPackages());
  }

  Future<void> _editPackage(Map<String, dynamic> package) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _CreatePackageScreen(package: package)),
    );
    if (changed == true && mounted) setState(() => _packages = _loadPackages());
  }

  Future<void> _deletePackage(Map<String, dynamic> package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete draft?'),
        content: Text('Delete ${package['title']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client
          .from('tour_packages')
          .delete()
          .eq('id', package['id'] as String);
      if (mounted) setState(() => _packages = _loadPackages());
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _createPackage,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Create package'),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _packages,
      builder: (context, snapshot) {
        final children = <Widget>[
          const Text(
            'Your packages',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
        ];
        if (snapshot.hasError) {
          children.add(const Text('Could not load your packages.'));
        } else if (!snapshot.hasData) {
          children.add(const Center(child: CircularProgressIndicator()));
        } else if (snapshot.data!.isEmpty) {
          children.add(
            const Text(
              'Create your first package. It stays a draft until approved.',
            ),
          );
        } else {
          children.addAll(
            snapshot.data!.map(
              (package) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: _primary,
                      child: Icon(Icons.landscape_rounded, color: Colors.white),
                    ),
                    title: Text(
                      package['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${package['duration_days']} days · ${package['capacity']} guests · NPR ${package['price_npr']}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) => value == 'edit'
                          ? _editPackage(package)
                          : _deletePackage(package),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit package'),
                        ),
                        if (package['status'] == 'draft')
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete draft'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return ListView(padding: const EdgeInsets.all(20), children: children);
      },
    ),
  );
}

class _CreatePackageScreen extends StatefulWidget {
  const _CreatePackageScreen({this.package});

  final Map<String, dynamic>? package;

  @override
  State<_CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<_CreatePackageScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _duration;
  late final TextEditingController _capacity;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _highlights;
  String _category = 'trekking';
  String? _coverPath;
  XFile? _cover;
  bool _saving = false;

  bool get _editing => widget.package != null;

  @override
  void initState() {
    super.initState();
    final package = widget.package;
    _title = TextEditingController(text: package?['title'] as String? ?? '');
    _duration = TextEditingController(
      text: '${package?['duration_days'] ?? ''}',
    );
    _capacity = TextEditingController(text: '${package?['capacity'] ?? ''}');
    _price = TextEditingController(text: '${package?['price_npr'] ?? ''}');
    _description = TextEditingController(
      text: package?['description'] as String? ?? '',
    );
    _highlights = TextEditingController(
      text: (package?['highlights'] as List? ?? const [])
          .map((item) => item.toString())
          .join(', '),
    );
    _coverPath = package?['cover_path'] as String?;
    _category = package?['category'] as String? ?? 'trekking';
  }

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    _capacity.dispose();
    _price.dispose();
    _description.dispose();
    _highlights.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw const AuthException('Please sign in again.');
      if (_cover != null) {
        final extension = _cover!.name.contains('.')
            ? _cover!.name.split('.').last
            : 'jpg';
        _coverPath =
            '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$extension';
        await Supabase.instance.client.storage
            .from('package-images')
            .uploadBinary(
              _coverPath!,
              await _cover!.readAsBytes(),
              fileOptions: FileOptions(
                contentType: _cover!.mimeType,
                upsert: true,
              ),
            );
      }
      final values = {
        'guide_id': user.id,
        'title': _title.text.trim(),
        'category': _category,
        'duration_days': int.parse(_duration.text),
        'capacity': int.parse(_capacity.text),
        'price_npr': int.parse(_price.text),
        'description': _description.text.trim(),
        'highlights': _highlights.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .take(8)
            .toList(),
        'cover_path': _coverPath,
      };
      if (_editing) {
        await Supabase.instance.client.rpc(
          'update_guide_package',
          params: {
            'p_package_id': widget.package!['id'],
            'p_title': values['title'],
            'p_category': values['category'],
            'p_duration_days': values['duration_days'],
            'p_capacity': values['capacity'],
            'p_price_npr': values['price_npr'],
            'p_description': values['description'],
            'p_highlights': values['highlights'],
            'p_cover_path': values['cover_path'],
          },
        );
      } else {
        await Supabase.instance.client.from('tour_packages').insert(values);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on StorageException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_editing ? 'Edit package' : 'Create package')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _editing
                ? 'Changes are visible to travellers.'
                : 'Your package will start as a draft.',
            style: TextStyle(color: _muted),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Package title',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().length < 3
                ? 'Enter at least 3 characters'
                : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items:
                const ['trekking', 'adventure', 'nature', 'culture', 'wellness']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
            onChanged: (value) => setState(() => _category = value!),
          ),
          const SizedBox(height: 16),
          _NumberField(
            controller: _duration,
            label: 'Duration (days)',
            max: 30,
          ),
          const SizedBox(height: 16),
          _NumberField(controller: _capacity, label: 'Maximum guests', max: 50),
          const SizedBox(height: 16),
          _NumberField(controller: _price, label: 'Price (NPR)'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            maxLength: 2000,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _highlights,
            decoration: const InputDecoration(
              labelText: 'Highlights',
              hintText: 'Sunrise hike, local lunch, lake walk',
              helperText: 'Separate up to 8 highlights with commas.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _saving
                ? null
                : () async {
                    final cover = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1600,
                      imageQuality: 85,
                    );
                    if (cover != null && mounted) {
                      setState(() => _cover = cover);
                    }
                  },
            icon: const Icon(Icons.photo_outlined),
            label: Text(
              _cover != null || _coverPath != null
                  ? 'Change cover photo'
                  : 'Add cover photo',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(
              _saving
                  ? 'Saving…'
                  : _editing
                  ? 'Save changes'
                  : 'Save draft',
            ),
          ),
        ],
      ),
    ),
  );
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label, this.max});

  final TextEditingController controller;
  final String label;
  final int? max;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: (value) {
      final number = int.tryParse(value ?? '');
      return number == null || number < 1 || (max != null && number > max!)
          ? 'Enter a value from 1${max == null ? '' : ' to $max'}'
          : null;
    },
  );
}

class _GuideMoreTab extends StatelessWidget {
  const _GuideMoreTab();

  void _openProfile(BuildContext context) => _open(
    context,
    Scaffold(
      appBar: AppBar(backgroundColor: _surface, surfaceTintColor: _surface),
      body: SafeArea(child: const _GuideProfileTab()),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = (user?.userMetadata?['full_name'] as String? ?? 'Guide')
        .trim();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'More',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: _ProfileAvatar(
            isGuide: true,
            fallback: name.isEmpty ? 'G' : name[0].toUpperCase(),
            compact: true,
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: const Text('Guide account · View profile'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _openProfile(context),
        ),
        const SizedBox(height: 16),
        _MoreItem(
          icon: Icons.person_outline,
          label: 'Guide profile',
          onTap: () => _openProfile(context),
        ),
        _MoreItem(
          icon: Icons.lock_outline,
          label: 'Change password',
          onTap: () => _open(context, const _ChangePasswordScreen()),
        ),
        _MoreItem(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          subtitle: 'Coming soon',
        ),
        _MoreItem(
          icon: Icons.support_agent_outlined,
          label: 'Contact us',
          onTap: () => _open(context, const _ContactUsScreen()),
        ),
        _MoreItem(
          icon: Icons.quiz_outlined,
          label: 'FAQs / Help Center',
          onTap: () => _open(context, const _FaqScreen()),
        ),
        _MoreItem(
          icon: Icons.info_outline,
          label: 'About Guidely',
          onTap: () => _open(context, const _AboutScreen()),
        ),
        _MoreItem(
          icon: Icons.description_outlined,
          label: 'Terms of Service',
          onTap: () => _open(context, const _LegalScreen(privacy: false)),
        ),
        _MoreItem(
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy Policy',
          onTap: () => _open(context, const _LegalScreen(privacy: true)),
        ),
        _MoreItem(
          icon: Icons.logout_rounded,
          label: 'Sign out',
          onTap: () => _confirmSignOut(context),
        ),
      ],
    );
  }
}

class _GuideProfileTab extends StatefulWidget {
  const _GuideProfileTab();

  @override
  State<_GuideProfileTab> createState() => _GuideProfileTabState();
}

class _GuideProfileTabState extends State<_GuideProfileTab> {
  late Future<Map<String, dynamic>?> _profile;

  @override
  void initState() {
    super.initState();
    _profile = _loadProfile();
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    return Supabase.instance.client
        .from('guides')
        .select(
          'location, bio, languages, categories, years_experience, verification_status, photo_path',
        )
        .eq('user_id', user.id)
        .maybeSingle();
  }

  Future<void> _edit(Map<String, dynamic> profile) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _EditGuideProfileScreen(profile: profile),
      ),
    );
    if (changed == true && mounted) setState(() => _profile = _loadProfile());
  }

  Future<void> _signOut() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await _clearAvatarCache('guide-avatars', user.id);
      } catch (_) {
        // Local cache cleanup must not block logout.
      }
    }
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const _WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: _profile,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      final profile = snapshot.data;
      if (profile == null) {
        return const Center(child: Text('Guide profile unavailable.'));
      }
      final languages = List<String>.from(profile['languages'] as List? ?? []);
      final categories = List<String>.from(
        profile['categories'] as List? ?? [],
      );
      final user = Supabase.instance.client.auth.currentUser;
      final name = (user?.userMetadata?['full_name'] as String? ?? 'Guide')
          .trim();
      final verified = profile['verification_status'] == 'approved';
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Guide profile',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _ProfileAvatar(
                  isGuide: true,
                  fallback: name.isEmpty ? 'G' : name[0].toUpperCase(),
                  initialPath: profile['photo_path'] as String?,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(color: _muted),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            verified
                                ? Icons.verified_rounded
                                : Icons.hourglass_top_rounded,
                            color: verified ? _primary : _accent,
                            size: 17,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            verified
                                ? 'Verified guide'
                                : 'Verification pending',
                            style: TextStyle(
                              color: verified ? _primary : _accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'About',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            profile['bio'] as String? ??
                'Add a short introduction for travellers.',
          ),
          const SizedBox(height: 16),
          Text(
            'Based in ${profile['location'] ?? 'Not set'} · ${profile['years_experience'] ?? 0} years experience',
            style: const TextStyle(color: _muted),
          ),
          const SizedBox(height: 14),
          if (languages.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: languages
                  .map((item) => Chip(label: Text(item)))
                  .toList(),
            ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories
                  .map((item) => Chip(label: Text(item)))
                  .toList(),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _edit(profile),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit profile'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      );
    },
  );
}

class _EditGuideProfileScreen extends StatefulWidget {
  const _EditGuideProfileScreen({required this.profile});

  final Map<String, dynamic> profile;

  @override
  State<_EditGuideProfileScreen> createState() =>
      _EditGuideProfileScreenState();
}

class _EditGuideProfileScreenState extends State<_EditGuideProfileScreen> {
  late final TextEditingController _location;
  late final TextEditingController _bio;
  late final TextEditingController _languages;
  late final TextEditingController _categories;
  late final TextEditingController _experience;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _location = TextEditingController(
      text: widget.profile['location'] as String? ?? '',
    );
    _bio = TextEditingController(text: widget.profile['bio'] as String? ?? '');
    _languages = TextEditingController(
      text: List<String>.from(
        widget.profile['languages'] as List? ?? [],
      ).join(', '),
    );
    _categories = TextEditingController(
      text: List<String>.from(
        widget.profile['categories'] as List? ?? [],
      ).join(', '),
    );
    _experience = TextEditingController(
      text: '${widget.profile['years_experience'] ?? 0}',
    );
  }

  @override
  void dispose() {
    _location.dispose();
    _bio.dispose();
    _languages.dispose();
    _categories.dispose();
    _experience.dispose();
    super.dispose();
  }

  List<String> _items(TextEditingController controller) => controller.text
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  Future<void> _save() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final experience = int.tryParse(_experience.text);
    if (experience == null || experience < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid years of experience.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await Supabase.instance.client
          .from('guides')
          .update({
            'location': _location.text.trim(),
            'bio': _bio.text.trim(),
            'languages': _items(_languages),
            'categories': _items(_categories),
            'years_experience': experience,
          })
          .eq('user_id', user.id);
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit guide profile')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: _location,
          decoration: const InputDecoration(
            labelText: 'Location',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _bio,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Bio',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _languages,
          decoration: const InputDecoration(
            labelText: 'Languages (comma-separated)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _categories,
          decoration: const InputDecoration(
            labelText: 'Categories (comma-separated)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _experience,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Years of experience',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save changes'),
        ),
      ],
    ),
  );
}

class _GuideAction extends StatelessWidget {
  const _GuideAction({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _FadeUp(
    child: Card(
      child: ListTile(
        leading: Icon(icon, color: _primary),
        title: Text(label),
        onTap: onTap,
      ),
    ),
  );
}
