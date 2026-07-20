part of '../../main.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int _tab = 0;
  String _category = 'All trips';
  String _search = '';
  int? _maxPrice;
  int? _maxDuration;
  bool _hasBooking = false;
  Set<String> _savedPackageIds = {};
  int _savedVersion = 0;
  String _firstName = 'Traveller';
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSavedPackages();
  }

  Future<void> _loadSavedPackages() async {
    if (!_supabaseReady) return;
    try {
      final rows = await Supabase.instance.client
          .from('saved_packages')
          .select('package_id');
      if (mounted) {
        setState(
          () => _savedPackageIds = {
            for (final row in rows) row['package_id'] as String,
          },
        );
      }
    } on PostgrestException {
      // Saving remains unavailable until the database migration is applied.
    }
  }

  Future<void> _setPackageSaved(String packageId, bool saved) async {
    if (!_supabaseReady) {
      setState(() {
        _savedPackageIds = {..._savedPackageIds};
        saved
            ? _savedPackageIds.add(packageId)
            : _savedPackageIds.remove(packageId);
        _savedVersion++;
      });
      return;
    }
    try {
      final saves = Supabase.instance.client.from('saved_packages');
      if (saved) {
        await saves.insert({'package_id': packageId});
      } else {
        await saves.delete().eq('package_id', packageId);
      }
      if (mounted) {
        setState(() {
          saved
              ? _savedPackageIds.add(packageId)
              : _savedPackageIds.remove(packageId);
          _savedVersion++;
        });
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _loadProfile() async {
    if (!_supabaseReady) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name, avatar_path')
          .eq('id', user.id)
          .maybeSingle();
      final name = profile?['full_name'] as String?;
      final accountName = user.userMetadata?['full_name'] as String?;
      final fallback = user.email?.split('@').first;
      final firstName =
          (name?.trim().isNotEmpty == true
                  ? name
                  : accountName?.trim().isNotEmpty == true
                  ? accountName
                  : fallback)
              ?.trim()
              .split(RegExp(r'\s+'))
              .first;
      if (mounted && firstName != null && firstName.isNotEmpty) {
        setState(() {
          _firstName = firstName;
          _avatarPath = profile?['avatar_path'] as String?;
        });
      }
    } on PostgrestException {
      // Explore remains usable if the profile record is temporarily unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            _ExploreContent(
              category: _category,
              onCategoryChanged: (value) => setState(() => _category = value),
              search: _search,
              onSearchChanged: (value) => setState(() => _search = value),
              maxPrice: _maxPrice,
              maxDuration: _maxDuration,
              onFiltersChanged: (price, duration) => setState(() {
                _maxPrice = price;
                _maxDuration = duration;
              }),
              savedPackageIds: _savedPackageIds,
              onSavedChanged: _setPackageSaved,
              onRequestSent: () => setState(() => _hasBooking = true),
              firstName: _firstName,
              onProfilePressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _ProfileScreen()),
                );
                _loadProfile();
              },
              avatarPath: _avatarPath,
            ),
            _BookingsTab(hasBooking: _hasBooking),
            _SavedTab(
              version: _savedVersion,
              onSavedChanged: _setPackageSaved,
              onExplore: () => setState(() => _tab = 0),
            ),
            _MoreTab(
              firstName: _firstName,
              avatarPath: _avatarPath,
              onProfilePressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _ProfileScreen()),
                );
                _loadProfile();
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Saved',
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
}

class _ExploreContent extends StatelessWidget {
  const _ExploreContent({
    required this.category,
    required this.onCategoryChanged,
    required this.search,
    required this.onSearchChanged,
    required this.maxPrice,
    required this.maxDuration,
    required this.onFiltersChanged,
    required this.savedPackageIds,
    required this.onSavedChanged,
    required this.onRequestSent,
    required this.firstName,
    required this.avatarPath,
    required this.onProfilePressed,
  });

  final String category;
  final ValueChanged<String> onCategoryChanged;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final int? maxPrice;
  final int? maxDuration;
  final void Function(int? price, int? duration) onFiltersChanged;
  final Set<String> savedPackageIds;
  final Future<void> Function(String packageId, bool saved) onSavedChanged;
  final VoidCallback onRequestSent;
  final String firstName;
  final String? avatarPath;
  final VoidCallback onProfilePressed;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  IconButton(
                    tooltip: 'Profile',
                    onPressed: onProfilePressed,
                    icon: _ProfileAvatar(
                      isGuide: false,
                      fallback: firstName.substring(0, 1).toUpperCase(),
                      initialPath: avatarPath,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $firstName',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 24),
              _SearchBar(
                onSearchChanged: onSearchChanged,
                maxPrice: maxPrice,
                maxDuration: maxDuration,
                onFiltersChanged: onFiltersChanged,
              ),
              const SizedBox(height: 25),
              const _SectionTitle(title: 'Explore by experience'),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      [
                            'All trips',
                            'Trekking',
                            'Culture',
                            'Adventure',
                            'Nature',
                          ]
                          .map(
                            (label) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(label),
                                selected: category == label,
                                onSelected: (_) => onCategoryChanged(label),
                                selectedColor: const Color(0xFFD9F1EC),
                                side: BorderSide(
                                  color: category == label
                                      ? _primary
                                      : const Color(0xFFE0E5E3),
                                ),
                                labelStyle: TextStyle(
                                  color: category == label ? _primary : _ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
              const SizedBox(height: 30),
              const _SectionTitle(title: 'Popular packages', action: 'See all'),
              const SizedBox(height: 14),
              _PublicPackageList(
                category: category,
                search: search,
                maxPrice: maxPrice,
                maxDuration: maxDuration,
                savedPackageIds: savedPackageIds,
                onSavedChanged: onSavedChanged,
                onRequestSent: onRequestSent,
              ),
              const SizedBox(height: 30),
              const _SectionTitle(title: 'Why travel with Guidely'),
              const SizedBox(height: 12),
              const _TrustCard(),
            ]),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.onSearchChanged,
    required this.maxPrice,
    required this.maxDuration,
    required this.onFiltersChanged,
  });

  final ValueChanged<String> onSearchChanged;
  final int? maxPrice;
  final int? maxDuration;
  final void Function(int? price, int? duration) onFiltersChanged;

  Future<void> _showFilters(BuildContext context) async {
    var price = maxPrice;
    var duration = maxDuration;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Maximum price',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Wrap(
                  spacing: 8,
                  children: [null, 5000, 15000, 30000]
                      .map(
                        (value) => ChoiceChip(
                          label: Text(
                            value == null ? 'Any' : 'NPR ${value ~/ 1000}k',
                          ),
                          selected: price == value,
                          onSelected: (_) => setSheetState(() => price = value),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Maximum duration',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Wrap(
                  spacing: 8,
                  children: [null, 1, 3, 7]
                      .map(
                        (value) => ChoiceChip(
                          label: Text(
                            value == null
                                ? 'Any'
                                : '$value day${value == 1 ? '' : 's'}',
                          ),
                          selected: duration == value,
                          onSelected: (_) =>
                              setSheetState(() => duration = value),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      onFiltersChanged(price, duration);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Show packages'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: _muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: const Key('package-search'),
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search trips or guides',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Filter packages',
            onPressed: () => _showFilters(context),
            style: IconButton.styleFrom(
              backgroundColor: maxPrice != null || maxDuration != null
                  ? _primary
                  : const Color(0xFFE7EFED),
            ),
            icon: Icon(
              Icons.tune_rounded,
              color: maxPrice != null || maxDuration != null
                  ? Colors.white
                  : _primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicPackageList extends StatefulWidget {
  const _PublicPackageList({
    required this.category,
    required this.search,
    required this.maxPrice,
    required this.maxDuration,
    required this.savedPackageIds,
    required this.onSavedChanged,
    required this.onRequestSent,
  });

  final String category;
  final String search;
  final int? maxPrice;
  final int? maxDuration;
  final Set<String> savedPackageIds;
  final Future<void> Function(String packageId, bool saved) onSavedChanged;
  final VoidCallback onRequestSent;

  @override
  State<_PublicPackageList> createState() => _PublicPackageListState();
}

class _PublicPackageListState extends State<_PublicPackageList> {
  late Future<List<Map<String, dynamic>>> _packages;

  @override
  void initState() {
    super.initState();
    _packages = _supabaseReady ? _loadPackages() : Future.value([]);
  }

  Future<List<Map<String, dynamic>>> _loadPackages() async {
    final rows = await Supabase.instance.client
        .from('public_tour_packages')
        .select()
        .order('title');
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Widget build(BuildContext context) {
    if (!_supabaseReady) return _samplePackages();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _packages,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Could not load packages.');
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final packages = snapshot.data!.where(_matchesPackage).toList();
        if (packages.isEmpty) {
          return const Text('No packages match those filters.');
        }
        return Column(
          children: packages
              .map(
                (package) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _PackageCard(
                    title: package['title'] as String,
                    guide: package['guide_name'] as String,
                    packageId: package['id'] as String,
                    saveId: package['id'] as String,
                    capacity: package['capacity'] as int,
                    rating: 0,
                    reviewCount: 0,
                    duration: '${package['duration_days']} days',
                    price: 'NPR ${package['price_npr']}',
                    color: _packageColor(package['category'] as String),
                    icon: _packageIcon(package['category'] as String),
                    description: package['description'] as String?,
                    highlights: (package['highlights'] as List? ?? const [])
                        .map((item) => item.toString())
                        .toList(),
                    coverPath: package['cover_path'] as String?,
                    saved: widget.savedPackageIds.contains(package['id']),
                    onSavedChanged: widget.onSavedChanged,
                    onRequestSent: widget.onRequestSent,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  bool _matchesPackage(Map<String, dynamic> package) => _matches(
    title: package['title'] as String,
    guide: package['guide_name'] as String,
    category: package['category'] as String,
    duration: package['duration_days'] as int,
    price: package['price_npr'] as int,
  );

  bool _matches({
    required String title,
    required String guide,
    required String category,
    required int duration,
    required int price,
  }) {
    final search = widget.search.trim().toLowerCase();
    return (widget.category == 'All trips' ||
            category == widget.category.toLowerCase()) &&
        (search.isEmpty || '$title $guide'.toLowerCase().contains(search)) &&
        (widget.maxPrice == null || price <= widget.maxPrice!) &&
        (widget.maxDuration == null || duration <= widget.maxDuration!);
  }

  Widget _samplePackages() {
    final cards = <Widget>[
      if (_matches(
        title: 'Sunrise at Poon Hill',
        guide: 'Maya Gurung',
        category: 'trekking',
        duration: 4,
        price: 18500,
      ))
        _PackageCard(
          title: 'Sunrise at Poon Hill',
          guide: 'Maya Gurung',
          rating: 4.9,
          reviewCount: 38,
          duration: '4 days',
          price: 'NPR 18,500',
          color: const Color(0xFF486C60),
          icon: Icons.landscape_rounded,
          saveId: 'sample-poon-hill',
          saved: widget.savedPackageIds.contains('sample-poon-hill'),
          onSavedChanged: widget.onSavedChanged,
          onRequestSent: widget.onRequestSent,
        ),
      if (_matches(
        title: 'Old Pokhara, slow and local',
        guide: 'Sujan Shrestha',
        category: 'culture',
        duration: 1,
        price: 3500,
      ))
        _PackageCard(
          title: 'Old Pokhara, slow and local',
          guide: 'Sujan Shrestha',
          rating: 4.8,
          reviewCount: 24,
          duration: '1 day',
          price: 'NPR 3,500',
          color: const Color(0xFF9C5E3B),
          icon: Icons.account_balance_rounded,
          saveId: 'sample-old-pokhara',
          saved: widget.savedPackageIds.contains('sample-old-pokhara'),
          onSavedChanged: widget.onSavedChanged,
          onRequestSent: widget.onRequestSent,
        ),
    ];
    if (cards.isEmpty) return const Text('No packages match those filters.');
    return Column(
      children: cards
          .map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: card,
            ),
          )
          .toList(),
    );
  }

  Color _packageColor(String category) => switch (category) {
    'culture' => const Color(0xFF9C5E3B),
    'adventure' => const Color(0xFFE66F3A),
    'nature' => const Color(0xFF43767A),
    'wellness' => const Color(0xFF7E6CA8),
    _ => const Color(0xFF486C60),
  };

  IconData _packageIcon(String category) => switch (category) {
    'culture' => Icons.account_balance_rounded,
    'adventure' => Icons.paragliding_rounded,
    'nature' => Icons.forest_rounded,
    'wellness' => Icons.spa_rounded,
    _ => Icons.landscape_rounded,
  };
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action});
  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      const Spacer(),
      if (action != null)
        Text(
          action!,
          style: const TextStyle(color: _primary, fontWeight: FontWeight.w700),
        ),
    ],
  );
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.title,
    required this.guide,
    this.packageId,
    this.saveId,
    this.capacity = 50,
    required this.rating,
    required this.reviewCount,
    required this.duration,
    required this.price,
    required this.color,
    required this.icon,
    required this.saved,
    required this.onSavedChanged,
    required this.onRequestSent,
    this.description,
    this.highlights = const [],
    this.coverPath,
  });
  final String title;
  final String guide;
  final String? packageId;
  final String? saveId;
  final int capacity;
  final double rating;
  final int reviewCount;
  final String duration;
  final String price;
  final Color color;
  final IconData icon;
  final bool saved;
  final Future<void> Function(String packageId, bool saved) onSavedChanged;
  final VoidCallback onRequestSent;
  final String? description;
  final List<String> highlights;
  final String? coverPath;

  @override
  Widget build(BuildContext context) {
    return _FadeUp(
      child: Semantics(
        button: true,
        label:
            '$title with verified guide $guide, rated $rating from $reviewCount reviews, $duration, $price',
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final requested = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => _PackageDetailScreen(
                  title: title,
                  guide: guide,
                  packageId: packageId,
                  capacity: capacity,
                  rating: rating,
                  reviewCount: reviewCount,
                  duration: duration,
                  price: price,
                  color: color,
                  icon: icon,
                  description: description,
                  highlights: highlights,
                  coverPath: coverPath,
                ),
              ),
            );
            if (requested == true) onRequestSent();
          },
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PackageImage(
                  height: 150,
                  color: color,
                  icon: icon,
                  coverPath: coverPath,
                  child: Stack(
                    children: [
                      Positioned(
                        right: 22,
                        bottom: 18,
                        child: Icon(
                          icon,
                          size: 92,
                          color: Colors.white.withValues(alpha: .32),
                        ),
                      ),
                      Positioned(
                        top: 13,
                        right: 13,
                        child: IconButton.filledTonal(
                          tooltip: saved ? 'Remove from saved' : 'Save package',
                          onPressed: saveId == null
                              ? null
                              : () => onSavedChanged(saveId!, !saved),
                          icon: Icon(
                            saved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: _ink,
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 14,
                        bottom: 13,
                        child: _VerifiedBadge(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            'with $guide',
                            style: const TextStyle(color: _muted),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: _accent,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$rating',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            ' ($reviewCount)',
                            style: const TextStyle(color: _muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            size: 18,
                            color: _muted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            duration,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            price,
                            style: const TextStyle(
                              color: _accent,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
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
        ),
      ),
    );
  }
}

class _PackageDetailScreen extends StatelessWidget {
  const _PackageDetailScreen({
    required this.title,
    required this.guide,
    this.packageId,
    required this.capacity,
    required this.rating,
    required this.reviewCount,
    required this.duration,
    required this.price,
    required this.color,
    required this.icon,
    this.description,
    this.highlights = const [],
    this.coverPath,
  });

  final String title;
  final String guide;
  final String? packageId;
  final int capacity;
  final double rating;
  final int reviewCount;
  final String duration;
  final String price;
  final Color color;
  final IconData icon;
  final String? description;
  final List<String> highlights;
  final String? coverPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: _surface, surfaceTintColor: _surface),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            minimumSize: const Size.fromHeight(54),
          ),
          onPressed: () async {
            final requested = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => _RequestTripScreen(
                  title: title,
                  price: price,
                  packageId: packageId,
                  capacity: capacity,
                ),
              ),
            );
            if (context.mounted && requested == true) {
              Navigator.of(context).pop(true);
            }
          },
          child: const Text('Request this trip'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          _PackageImage(
            height: 215,
            color: color,
            icon: icon,
            coverPath: coverPath,
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              height: 1.12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _GuideProfileScreen(
                  name: guide,
                  rating: rating,
                  reviewCount: reviewCount,
                  color: color,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  child: Text(
                    guide[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guide,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const _VerifiedBadge(),
                    ],
                  ),
                ),
                const Icon(Icons.star_rounded, color: _accent),
                Text(
                  '$rating ($reviewCount)',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Icon(Icons.chevron_right_rounded, color: _muted),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.schedule_outlined, color: _primary),
              const SizedBox(width: 7),
              Text(
                duration,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                price,
                style: const TextStyle(
                  color: _accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Divider(height: 40),
          Text(
            description?.trim().isNotEmpty == true
                ? description!.trim()
                : 'Your guide will share the route, pace, and meeting details after reviewing your request.',
            style: TextStyle(fontSize: 16, color: _muted, height: 1.5),
          ),
          const SizedBox(height: 26),
          const Text(
            'Highlights',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (highlights.isEmpty)
            const _IncludedItem(
              icon: Icons.map_outlined,
              text: 'Trip details will be confirmed with your guide.',
            )
          else
            ...highlights.map(
              (highlight) => _IncludedItem(
                icon: Icons.check_circle_outline_rounded,
                text: highlight,
              ),
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD9F1EC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: _primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Requesting does not confirm your trip or take payment. Your guide will review your dates first.',
                    style: TextStyle(height: 1.4),
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

class _PackageImage extends StatelessWidget {
  const _PackageImage({
    required this.height,
    required this.color,
    required this.icon,
    this.coverPath,
    this.child,
  });

  final double height;
  final Color color;
  final IconData icon;
  final String? coverPath;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final coverUrl = !_supabaseReady || coverPath == null || coverPath!.isEmpty
        ? null
        : Supabase.instance.client.storage
              .from('package-images')
              .getPublicUrl(coverPath!);
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: .65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverUrl != null)
            Image.network(
              coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(),
            ),
          if (coverUrl != null)
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .18),
              ),
            ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Icon(
                icon,
                size: height > 180 ? 126 : 92,
                color: Colors.white.withValues(alpha: .3),
              ),
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

class _IncludedItem extends StatelessWidget {
  const _IncludedItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, color: _primary, size: 20),
        const SizedBox(width: 10),
        Text(text),
      ],
    ),
  );
}

class _RequestTripScreen extends StatefulWidget {
  const _RequestTripScreen({
    required this.title,
    required this.price,
    this.packageId,
    required this.capacity,
  });
  final String title;
  final String price;
  final String? packageId;
  final int capacity;

  @override
  State<_RequestTripScreen> createState() => _RequestTripScreenState();
}

class _RequestTripScreenState extends State<_RequestTripScreen> {
  DateTime? _date;
  int _travellers = 2;
  final _note = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _travellers = widget.capacity < 2 ? 1 : 2;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _sendRequest() async {
    if (_date == null) return;
    setState(() => _sending = true);
    try {
      if (widget.packageId != null) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          throw const AuthException('Please sign in to request a trip.');
        }
        await Supabase.instance.client.rpc(
          'create_booking_request',
          params: {
            'p_package_id': widget.packageId,
            'p_starts_on': _date!.toIso8601String().split('T').first,
            'p_headcount': _travellers,
            'p_trip_note': _note.text.trim(),
          },
        );
      }
      if (!mounted) return;
      final sent = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => _RequestSentScreen(title: widget.title),
        ),
      );
      if (mounted && sent == true) Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
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
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _date == null
        ? 'Choose a start date'
        : '${_date!.day}/${_date!.month}/${_date!.year}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request your trip'),
        backgroundColor: _surface,
        surfaceTintColor: _surface,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            minimumSize: const Size.fromHeight(54),
          ),
          onPressed: _date == null
              ? null
              : _sending
              ? null
              : _sendRequest,
          child: Text(_sending ? 'Sending…' : 'Send request'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          Text(
            widget.price,
            style: const TextStyle(color: _accent, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 26),
          const Text(
            'When would you like to go?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(dateText),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Travellers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _travellers > 1
                    ? () => setState(() => _travellers--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '$_travellers',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                onPressed: _travellers < widget.capacity
                    ? () => setState(() => _travellers++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Trip note (optional)',
              hintText: 'Anything your guide should know?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE7DC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'This is a request, not a payment or confirmed booking. You will coordinate directly with your guide after they accept.',
              style: TextStyle(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestSentScreen extends StatelessWidget {
  const _RequestSentScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xFFD9F1EC),
              child: Icon(Icons.check_rounded, color: _primary, size: 42),
            ),
            const SizedBox(height: 24),
            const Text(
              'Request sent',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              'Your guide will review your request for $title. This is not a payment or confirmed booking yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, height: 1.45),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Back to Explore'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GuideProfileScreen extends StatelessWidget {
  const _GuideProfileScreen({
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.color,
  });

  final String name;
  final double rating;
  final int reviewCount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: _surface,
            surfaceTintColor: _surface,
            title: const Text('Guide profile'),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: color,
                        child: Text(
                          name.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const _VerifiedBadge(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: _accent,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$rating',
                          style: const TextStyle(
                            fontSize: 29,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Guide rating\nfrom $reviewCount verified reviews',
                          style: const TextStyle(color: _muted, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'About',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A verified local guide creating thoughtful experiences around Pokhara.',
                    style: TextStyle(color: _muted, height: 1.5, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_rounded, color: _primary, size: 16),
        SizedBox(width: 4),
        Text(
          'Verified guide',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: _primary,
          ),
        ),
      ],
    ),
  );
}

class _TrustCard extends StatelessWidget {
  const _TrustCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFD9F1EC),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.handshake_outlined, color: _primary, size: 28),
        SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meet the person behind your trip',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'Every public package is hosted by a verified local guide.',
                style: TextStyle(color: _ink, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BookingsTab extends StatefulWidget {
  const _BookingsTab({required this.hasBooking});

  final bool hasBooking;

  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  late Future<List<Map<String, dynamic>>> _bookings;

  @override
  void initState() {
    super.initState();
    _bookings = _supabaseReady ? _loadBookings() : Future.value([]);
  }

  Future<List<Map<String, dynamic>>> _loadBookings() async {
    final rows = await Supabase.instance.client
        .from('my_booking_summaries')
        .select()
        .order('starts_on');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _refresh() async {
    setState(() => _bookings = _loadBookings());
    await _bookings;
  }

  Future<void> _leaveReview(String bookingId, String title) async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _ReviewScreen(bookingId: bookingId, title: title),
      ),
    );
    if (submitted == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!_supabaseReady && !widget.hasBooking) {
      return const _EmptyTab(
        icon: Icons.calendar_month_outlined,
        title: 'No booking requests yet',
        message: 'Your trip requests will appear here.',
      );
    }
    if (!_supabaseReady) return _sampleBooking();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _bookings,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const _EmptyTab(
            icon: Icons.calendar_month_outlined,
            title: 'No booking requests yet',
            message: 'Your trip requests will appear here.',
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Your bookings',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              ...snapshot.data!.map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BookingCard(
                    title: booking['package_title'] as String,
                    guide: booking['guide_name'] as String,
                    startsOn: booking['starts_on'] as String,
                    headcount: booking['headcount'] as int,
                    status: booking['status'] as String,
                    reviewed: booking['reviewed'] as bool,
                    onReview: () => _leaveReview(
                      booking['id'] as String,
                      booking['package_title'] as String,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sampleBooking() => const _BookingCard(
    title: 'Sunrise at Poon Hill',
    guide: 'Maya Gurung',
    startsOn: 'Your chosen date',
    headcount: 2,
    status: 'pending',
  );
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.title,
    required this.guide,
    required this.startsOn,
    required this.headcount,
    required this.status,
    this.reviewed = false,
    this.onReview,
  });

  final String title;
  final String guide;
  final String startsOn;
  final int headcount;
  final String status;
  final bool reviewed;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _VerifiedBadge(),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'with $guide · $startsOn · $headcount travellers',
          style: const TextStyle(color: _muted),
        ),
        const SizedBox(height: 12),
        Text(
          status == 'pending'
              ? 'Request pending. Your guide will review your dates.'
              : 'Request ${status.toUpperCase()}. Pull down to refresh updates.',
          style: const TextStyle(height: 1.4),
        ),
        if (status == 'completed' && !reviewed) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onReview,
            icon: const Icon(Icons.star_outline_rounded),
            label: const Text('Leave a review'),
          ),
        ],
      ],
    ),
  );
}

class _ReviewScreen extends StatefulWidget {
  const _ReviewScreen({required this.bookingId, required this.title});

  final String bookingId;
  final String title;

  @override
  State<_ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<_ReviewScreen> {
  final _comment = TextEditingController();
  int _rating = 5;
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw const AuthException('Please sign in again.');
      await Supabase.instance.client.from('reviews').insert({
        'booking_id': widget.bookingId,
        'tourist_id': user.id,
        'rating': _rating,
        'comment': _comment.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
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
    appBar: AppBar(title: const Text('Leave a review')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),
        const Text(
          'Your rating',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: List.generate(
            5,
            (index) => ChoiceChip(
              label: Text('${index + 1}'),
              selected: _rating == index + 1,
              onSelected: (_) => setState(() => _rating = index + 1),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _comment,
          maxLength: 1000,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Comment (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Submitting…' : 'Submit review'),
        ),
      ],
    ),
  );
}

class _SavedTab extends StatefulWidget {
  const _SavedTab({
    required this.version,
    required this.onSavedChanged,
    required this.onExplore,
  });

  final int version;
  final Future<void> Function(String packageId, bool saved) onSavedChanged;
  final VoidCallback onExplore;

  @override
  State<_SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends State<_SavedTab> {
  late Future<List<Map<String, dynamic>>> _savedPackages;

  @override
  void initState() {
    super.initState();
    _savedPackages = _loadSavedPackages();
  }

  @override
  void didUpdateWidget(covariant _SavedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.version != widget.version) {
      setState(() => _savedPackages = _loadSavedPackages());
    }
  }

  Future<List<Map<String, dynamic>>> _loadSavedPackages() async {
    if (!_supabaseReady) return [];
    final rows = await Supabase.instance.client
        .from('my_saved_packages')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _savedPackages,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load saved trips.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final packages = snapshot.data!;
        if (packages.isEmpty) {
          return _EmptyTab(
            icon: Icons.bookmark_border_rounded,
            title: 'Save trips you love',
            message: 'Tap the bookmark on any package to keep it here.',
            action: TextButton(
              onPressed: widget.onExplore,
              child: const Text('Explore trips'),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Saved trips',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            ...packages.map(
              (package) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: _primary,
                    child: Icon(Icons.bookmark_rounded, color: Colors.white),
                  ),
                  title: Text(
                    package['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${package['duration_days']} days · NPR ${package['price_npr']} · ${package['guide_name']}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove from saved',
                    icon: const Icon(Icons.bookmark_remove_outlined),
                    onPressed: () => widget.onSavedChanged(
                      package['package_id'] as String,
                      false,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MoreTab extends StatelessWidget {
  const _MoreTab({
    required this.firstName,
    required this.avatarPath,
    required this.onProfilePressed,
  });

  final String firstName;
  final String? avatarPath;
  final VoidCallback onProfilePressed;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'More',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 18),
      ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _ProfileAvatar(
          isGuide: false,
          fallback: firstName.substring(0, 1).toUpperCase(),
          initialPath: avatarPath,
          compact: true,
        ),
        title: Text(firstName, style: TextStyle(fontWeight: FontWeight.w800)),
        subtitle: const Text('Traveller account · View profile'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onProfilePressed,
      ),
      const SizedBox(height: 16),
      _MoreItem(
        icon: Icons.logout_rounded,
        label: 'Sign out',
        onTap: () => _confirmSignOut(context),
      ),
      _MoreItem(
        icon: Icons.settings_outlined,
        label: 'Profile settings',
        onTap: onProfilePressed,
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
        icon: Icons.report_problem_outlined,
        label: 'Report a problem',
        onTap: () => _open(context, const _ContactUsScreen(report: true)),
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
    ],
  );
}

void _open(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

Future<void> _confirmSignOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
  if (confirmed != true || !_supabaseReady) return;
  final user = Supabase.instance.client.auth.currentUser;
  if (user != null) {
    try {
      await _clearAvatarCache('user-avatars', user.id);
    } catch (_) {
      // Local cache cleanup must not block logout.
    }
  }
  await Supabase.instance.client.auth.signOut();
  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const _WelcomeScreen()),
      (route) => false,
    );
  }
}

class _ProfileScreen extends StatefulWidget {
  const _ProfileScreen();

  @override
  State<_ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<_ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _country = TextEditingController();
  String _locale = 'en';
  String? _avatarPath;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _country.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (!_supabaseReady) {
      setState(() => _loading = false);
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name, phone, country, preferred_locale, avatar_path')
          .eq('id', user.id)
          .single();
      if (!mounted) return;
      setState(() {
        _name.text = profile['full_name'] as String? ?? '';
        _phone.text = profile['phone'] as String? ?? '';
        _country.text = profile['country'] as String? ?? '';
        _locale = profile['preferred_locale'] as String? ?? 'en';
        _avatarPath = profile['avatar_path'] as String?;
      });
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _supabaseReady
        ? Supabase.instance.client.auth.currentUser
        : null;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'full_name': _name.text.trim(),
            'phone': _phone.text.trim(),
            'country': _country.text.trim(),
            'preferred_locale': _locale,
          })
          .eq('id', user.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
      }
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await _clearAvatarCache('user-avatars', user.id);
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
  Widget build(BuildContext context) {
    final user = _supabaseReady
        ? Supabase.instance.client.auth.currentUser
        : null;
    return Scaffold(
      appBar: AppBar(backgroundColor: _surface, surfaceTintColor: _surface),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : user == null
          ? const _EmptyTab(
              icon: Icons.lock_outline,
              title: 'Sign in to view your profile',
              message: 'Your account details are available after sign-in.',
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Your profile',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: _ProfileAvatar(
                      isGuide: false,
                      fallback: _name.text.isEmpty
                          ? 'T'
                          : _name.text[0].toUpperCase(),
                      initialPath: _avatarPath,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      user.email ?? '',
                      style: const TextStyle(color: _muted),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your full name'
                        : null,
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
                    controller: _country,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nationality',
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
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'ne', child: Text('नेपाली')),
                    ],
                    onChanged: (value) => setState(() => _locale = value!),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: _primary,
                    ),
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save changes'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  const _MoreItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _FadeUp(
    child: Card(
      child: ListTile(
        leading: Icon(icon, color: _primary),
        title: Text(label),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: onTap == null
            ? null
            : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    ),
  );
}
