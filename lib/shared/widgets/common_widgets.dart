part of '../../main.dart';

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: _primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: _muted),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    ),
  );
}

class _FadeUp extends StatelessWidget {
  const _FadeUp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}

Future<File> _avatarCacheFile(String bucket, String path) async {
  if (kIsWeb) throw UnsupportedError('Web does not use a file cache.');
  final directory = await getApplicationSupportDirectory();
  return File('${directory.path}/$bucket-${path.replaceAll('/', '-')}');
}

Future<void> _clearAvatarCache(String bucket, String userId) async {
  if (kIsWeb) return;
  final directory = await getApplicationSupportDirectory();
  final prefix = '$bucket-$userId-';
  await for (final file in directory.list()) {
    if (file is File && file.path.split('/').last.startsWith(prefix)) {
      await file.delete();
    }
  }
}

class _ProfileAvatar extends StatefulWidget {
  const _ProfileAvatar({
    required this.isGuide,
    required this.fallback,
    this.initialPath,
    this.compact = false,
  });

  final bool isGuide;
  final String fallback;
  final String? initialPath;
  final bool compact;

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  ImageProvider? _image;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadStoredImage();
  }

  @override
  void didUpdateWidget(covariant _ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPath != oldWidget.initialPath) _loadStoredImage();
  }

  Future<void> _loadStoredImage() async {
    if (!_supabaseReady) return;
    final path = widget.initialPath;
    if (path == null || path.isEmpty) return;
    final bucket = widget.isGuide ? 'guide-avatars' : 'user-avatars';
    try {
      if (kIsWeb) {
        final bytes = await Supabase.instance.client.storage
            .from(bucket)
            .download(path);
        if (mounted) setState(() => _image = MemoryImage(bytes));
        return;
      }
      final file = await _avatarCacheFile(bucket, path);
      if (!await file.exists()) {
        final bytes = await Supabase.instance.client.storage
            .from(bucket)
            .download(path);
        await file.writeAsBytes(bytes, flush: true);
      }
      if (mounted) setState(() => _image = FileImage(file));
    } catch (_) {
      // Keep the initials fallback when an avatar cannot be loaded.
    }
  }

  Future<void> _pickPhoto() async {
    if (!_supabaseReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile photos are unavailable until the app is initialized.',
          ),
        ),
      );
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in before uploading a photo.')),
      );
      return;
    }
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final extension = file.name.contains('.')
          ? file.name.split('.').last
          : 'jpg';
      final bucket = widget.isGuide ? 'guide-avatars' : 'user-avatars';
      final path = '${user.id}/avatar.$extension';
      final bytes = await file.readAsBytes();
      await Supabase.instance.client.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: file.mimeType, upsert: true),
          );
      await Supabase.instance.client
          .from(widget.isGuide ? 'guides' : 'profiles')
          .update({widget.isGuide ? 'photo_path' : 'avatar_path': path})
          .eq(widget.isGuide ? 'user_id' : 'id', user.id);
      if (mounted) {
        if (kIsWeb) {
          setState(() => _image = MemoryImage(bytes));
        } else {
          final cacheFile = await _avatarCacheFile(bucket, path);
          await cacheFile.writeAsBytes(bytes, flush: true);
          setState(() => _image = FileImage(cacheFile));
        }
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
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      CircleAvatar(
        radius: widget.compact ? 22 : 34,
        backgroundColor: _primary,
        backgroundImage: _image,
        child: _image == null
            ? Text(
                widget.fallback,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.compact ? 15 : 24,
                  fontWeight: FontWeight.w800,
                ),
              )
            : null,
      ),
      if (!widget.compact)
        Positioned(
          right: -4,
          bottom: -4,
          child: IconButton.filled(
            tooltip: 'Change profile photo',
            onPressed: _uploading ? null : _pickPhoto,
            icon: Icon(
              _uploading
                  ? Icons.hourglass_top_rounded
                  : Icons.camera_alt_outlined,
              size: 18,
            ),
          ),
        ),
    ],
  );
}
