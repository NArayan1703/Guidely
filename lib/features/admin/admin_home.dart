part of '../../main.dart';

class _AdminHome extends StatefulWidget {
  const _AdminHome();

  @override
  State<_AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<_AdminHome> {
  int _page = 0;

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Guidely admin'),
      backgroundColor: _surface,
      surfaceTintColor: _surface,
      actions: [
        IconButton(
          tooltip: 'Sign out',
          onPressed: _signOut,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    ),
    body: IndexedStack(
      index: _page,
      children: const [
        _AdminOverview(),
        _AdminPage(title: 'Guide verification', child: _GuideReviewList()),
        _AdminPage(
          title: 'Package moderation',
          child: _PackageModerationList(),
        ),
        _AdminPage(title: 'Bookings', child: _AdminBookings()),
        _AdminPage(title: 'Support inbox', child: _AdminSupportInbox()),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _page,
      onDestinationSelected: (value) => setState(() => _page = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Overview',
        ),
        NavigationDestination(
          icon: Icon(Icons.verified_user_outlined),
          selectedIcon: Icon(Icons.verified_user),
          label: 'Guides',
        ),
        NavigationDestination(
          icon: Icon(Icons.luggage_outlined),
          selectedIcon: Icon(Icons.luggage),
          label: 'Packages',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Bookings',
        ),
        NavigationDestination(
          icon: Icon(Icons.support_agent_outlined),
          selectedIcon: Icon(Icons.support_agent),
          label: 'Support',
        ),
      ],
    ),
  );
}

class _AdminOverview extends StatefulWidget {
  const _AdminOverview();

  @override
  State<_AdminOverview> createState() => _AdminOverviewState();
}

class _AdminOverviewState extends State<_AdminOverview> {
  late Future<_AdminStats> _stats;

  @override
  void initState() {
    super.initState();
    _stats = _loadStats();
  }

  Future<_AdminStats> _loadStats() async {
    if (!_supabaseReady) return const _AdminStats();
    final guides = await Supabase.instance.client
        .from('guide_applications')
        .select('user_id')
        .eq('status', 'pending');
    final packages = await Supabase.instance.client
        .from('tour_packages')
        .select('id')
        .eq('status', 'draft');
    final bookings = await Supabase.instance.client
        .from('bookings')
        .select('id')
        .eq('status', 'pending');
    final support = await Supabase.instance.client
        .from('contact_requests')
        .select('id')
        .eq('status', 'open');
    return _AdminStats(
      pendingGuides: guides.length,
      draftPackages: packages.length,
      pendingBookings: bookings.length,
      openSupport: support.length,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_AdminStats>(
    future: _stats,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final stats = snapshot.data!;
      final needsAttention = stats.pendingGuides + stats.openSupport;
      return RefreshIndicator(
        onRefresh: () async => setState(() => _stats = _loadStats()),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Marketplace overview',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Review what needs attention and keep trips moving.',
              style: TextStyle(color: _muted),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: needsAttention == 0
                    ? const Color(0xFFD9F1EC)
                    : const Color(0xFFFFE7DC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    needsAttention == 0
                        ? Icons.check_circle_outline
                        : Icons.priority_high_rounded,
                    color: _primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      needsAttention == 0
                          ? 'All caught up. No guide reviews or open support tickets.'
                          : '$needsAttention items need attention today.',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _DashboardMetric(
                    width: (constraints.maxWidth - 12) / 2,
                    icon: Icons.verified_user_outlined,
                    value: stats.pendingGuides,
                    label: 'Guide reviews',
                  ),
                  _DashboardMetric(
                    width: (constraints.maxWidth - 12) / 2,
                    icon: Icons.luggage_outlined,
                    value: stats.draftPackages,
                    label: 'Package drafts',
                  ),
                  _DashboardMetric(
                    width: (constraints.maxWidth - 12) / 2,
                    icon: Icons.calendar_month_outlined,
                    value: stats.pendingBookings,
                    label: 'Pending trips',
                  ),
                  _DashboardMetric(
                    width: (constraints.maxWidth - 12) / 2,
                    icon: Icons.support_agent_outlined,
                    value: stats.openSupport,
                    label: 'Open support',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick guide',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Approve guides before activating their packages. Check bookings and support tickets daily.',
              style: TextStyle(color: _muted, height: 1.45),
            ),
          ],
        ),
      );
    },
  );
}

class _AdminStats {
  const _AdminStats({
    this.pendingGuides = 0,
    this.draftPackages = 0,
    this.pendingBookings = 0,
    this.openSupport = 0,
  });

  final int pendingGuides;
  final int draftPackages;
  final int pendingBookings;
  final int openSupport;
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
  });

  final double width;
  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primary),
          const SizedBox(height: 14),
          Text(
            '$value',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          Text(label, style: const TextStyle(color: _muted)),
        ],
      ),
    ),
  );
}

class _AdminPage extends StatelessWidget {
  const _AdminPage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 18),
      child,
    ],
  );
}

class _GuideReviewList extends StatefulWidget {
  const _GuideReviewList();

  @override
  State<_GuideReviewList> createState() => _GuideReviewListState();
}

class _GuideReviewListState extends State<_GuideReviewList> {
  late Future<List<Map<String, dynamic>>> _applications;

  @override
  void initState() {
    super.initState();
    _applications = _loadApplications();
  }

  Future<List<Map<String, dynamic>>> _loadApplications() async {
    if (!_supabaseReady) return [];
    final rows = await Supabase.instance.client
        .from('guide_applications')
        .select('user_id, profiles(full_name)')
        .eq('status', 'pending')
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _review(String userId, bool approve) async {
    try {
      await Supabase.instance.client.rpc(
        'review_guide_application',
        params: {'application_user_id': userId, 'approve': approve},
      );
      if (mounted) setState(() => _applications = _loadApplications());
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _applications,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator();
          if (snapshot.data!.isEmpty) {
            return const Text('No guides awaiting review.');
          }
          return Column(
            children: snapshot.data!.map((application) {
              final profile = application['profiles'] as Map<String, dynamic>?;
              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.verified_user_outlined,
                    color: _primary,
                  ),
                  title: Text(
                    profile?['full_name'] as String? ?? 'Unnamed guide',
                  ),
                  subtitle: const Text('Guide application pending'),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Reject',
                        onPressed: () =>
                            _review(application['user_id'] as String, false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      IconButton(
                        tooltip: 'Approve',
                        onPressed: () =>
                            _review(application['user_id'] as String, true),
                        icon: const Icon(Icons.check_rounded, color: _primary),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      );
}

class _PackageModerationList extends StatefulWidget {
  const _PackageModerationList();

  @override
  State<_PackageModerationList> createState() => _PackageModerationListState();
}

class _PackageModerationListState extends State<_PackageModerationList> {
  late Future<List<Map<String, dynamic>>> _packages;

  @override
  void initState() {
    super.initState();
    _packages = _loadPackages();
  }

  Future<List<Map<String, dynamic>>> _loadPackages() async {
    if (!_supabaseReady) return [];
    final rows = await Supabase.instance.client
        .from('tour_packages')
        .select('id, title, status')
        .neq('status', 'inactive')
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _setStatus(String packageId, String status) async {
    try {
      await Supabase.instance.client
          .from('tour_packages')
          .update({'status': status})
          .eq('id', packageId);
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
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _packages,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator();
          if (snapshot.data!.isEmpty) {
            return const Text('No packages need moderation.');
          }
          return Column(
            children: snapshot.data!
                .map(
                  (package) => Card(
                    child: ListTile(
                      title: Text(package['title'] as String),
                      subtitle: Text('Status: ${package['status']}'),
                      trailing: IconButton(
                        tooltip: package['status'] == 'active'
                            ? 'Deactivate'
                            : 'Activate',
                        onPressed: () => _setStatus(
                          package['id'] as String,
                          package['status'] == 'active' ? 'inactive' : 'active',
                        ),
                        icon: Icon(
                          package['status'] == 'active'
                              ? Icons.visibility_off_outlined
                              : Icons.publish_rounded,
                          color: _primary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      );
}

class _AdminBookings extends StatefulWidget {
  const _AdminBookings();

  @override
  State<_AdminBookings> createState() => _AdminBookingsState();
}

class _AdminBookingsState extends State<_AdminBookings> {
  late Future<List<Map<String, dynamic>>> _bookings;

  @override
  void initState() {
    super.initState();
    _bookings = _loadBookings();
  }

  Future<List<Map<String, dynamic>>> _loadBookings() async {
    if (!_supabaseReady) return [];
    final rows = await Supabase.instance.client
        .from('bookings')
        .select('id, starts_on, headcount, status, tour_packages(title)')
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _bookings,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const LinearProgressIndicator();
      if (snapshot.data!.isEmpty) return const Text('No bookings yet.');
      return Column(
        children: snapshot.data!.map((booking) {
          final package = booking['tour_packages'] as Map<String, dynamic>?;
          return Card(
            child: ListTile(
              leading: const Icon(
                Icons.calendar_month_outlined,
                color: _primary,
              ),
              title: Text(package?['title'] as String? ?? 'Trip package'),
              subtitle: Text(
                '${booking['starts_on']} · ${booking['headcount']} travellers',
              ),
              trailing: Text(
                booking['status'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _primary,
                ),
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}

class _AdminSupportInbox extends StatefulWidget {
  const _AdminSupportInbox();

  @override
  State<_AdminSupportInbox> createState() => _AdminSupportInboxState();
}

class _AdminSupportInboxState extends State<_AdminSupportInbox> {
  late Future<List<Map<String, dynamic>>> _requests;

  @override
  void initState() {
    super.initState();
    _requests = _loadRequests();
  }

  Future<List<Map<String, dynamic>>> _loadRequests() async {
    if (!_supabaseReady) return [];
    final rows = await Supabase.instance.client
        .from('contact_requests')
        .select('id, reason, message, status, created_at')
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _setStatus(int requestId, String status) async {
    try {
      await Supabase.instance.client
          .from('contact_requests')
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

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _requests,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final requests = snapshot.data!;
          if (requests.isEmpty) return const Text('No support requests yet.');
          return Column(
            children: requests
                .map(
                  (request) => Card(
                    child: ListTile(
                      title: Text(request['reason'] as String),
                      subtitle: Text(
                        '${request['message']}\nStatus: ${request['status']}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Change status',
                        onSelected: (status) =>
                            _setStatus(request['id'] as int, status),
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'open', child: Text('Open')),
                          PopupMenuItem(
                            value: 'in_progress',
                            child: Text('In progress'),
                          ),
                          PopupMenuItem(value: 'closed', child: Text('Closed')),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      );
}
