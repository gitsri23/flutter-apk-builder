import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:video_player/video_player.dart';

// ─── ENTRY POINT ──────────────────────────────────────────────────────────────
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ChaiShotsApp());
}

// ─── THEME COLORS ─────────────────────────────────────────────────────────────
class AppColors {
  static const Color red = Color(0xFFE50914);
  static const Color redDim = Color(0x26E50914);
  static const Color bg = Color(0xFF000000);
  static const Color surface = Color(0xFF0F0F0F);
  static const Color surface2 = Color(0xFF1A1A1A);
  static const Color surface3 = Color(0xFF242424);
  static const Color border = Color(0x14FFFFFF);
  static const Color text = Color(0xFFFFFFFF);
  static const Color text2 = Color(0x99FFFFFF);
  static const Color text3 = Color(0x59FFFFFF);
}

// ─── CATEGORY COLORS ─────────────────────────────────────────────────────────
const Map<String, Color> categoryColors = {
  'Technology': Color(0xFF3B82F6),
  'Lifestyle': Color(0xFFF59E0B),
  'Travel': Color(0xFF10B981),
  'Sports': Color(0xFFEF4444),
  'Food': Color(0xFFF97316),
  'Music': Color(0xFF8B5CF6),
  'Gaming': Color(0xFF06B6D4),
  'Fashion': Color(0xFFEC4899),
  'News': Color(0xFFE50914),
  'Education': Color(0xFF14B8A6),
  'Comedy': Color(0xFFFBBF24),
  'Finance': Color(0xFF6366F1),
  'Health': Color(0xFF22C55E),
  'Auto': Color(0xFF64748B),
  'General': Color(0xFF9CA3AF),
};

Color catColor(String? cat) =>
    categoryColors[cat ?? 'General'] ?? const Color(0xFF9CA3AF);

const List<String> categories = [
  'General', 'Technology', 'Lifestyle', 'Travel', 'Sports', 'Food',
  'Music', 'Gaming', 'Fashion', 'News', 'Education', 'Comedy',
  'Finance', 'Health', 'Auto',
];

// ─── GLOBAL HELPER ────────────────────────────────────────────────────────────
String getVideoFormat(String url) {
  final ext = url.split('?').first.split('.').last.toLowerCase();
  const known = ['mp4', 'webm', 'mov', 'mkv', 'm3u8', 'ts', 'gif', 'm3u'];
  return known.contains(ext) ? ext.toUpperCase() : 'URL';
}

// ─── DATA MODEL ───────────────────────────────────────────────────────────────
class FeedItem {
  final String id;
  final String videoUrl;
  final String thumbnail;
  final String title;
  final String description;
  final String category;
  final String author;
  String likes;
  String comments;
  String shares;
  final String duration;

  FeedItem({
    required this.id,
    required this.videoUrl,
    required this.thumbnail,
    required this.title,
    required this.description,
    required this.category,
    required this.author,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.duration,
  });

  FeedItem copyWith({
    String? videoUrl,
    String? thumbnail,
    String? title,
    String? description,
    String? category,
    String? author,
    String? likes,
    String? comments,
    String? shares,
    String? duration,
  }) {
    return FeedItem(
      id: id,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnail: thumbnail ?? this.thumbnail,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      author: author ?? this.author,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      duration: duration ?? this.duration,
    );
  }
}

String _uid() => Random().nextInt(999999).toRadixString(36);

// ─── INITIAL DATA ─────────────────────────────────────────────────────────────
final List<FeedItem> initialFeeds = [
  FeedItem(
    id: '1',
    videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    thumbnail: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80',
    title: 'Future of Tech 🚀',
    description: 'AI is reshaping every industry. From neural interfaces to autonomous agents — the next decade will blow your mind.',
    category: 'Technology',
    author: '@techwave',
    likes: '12.4K',
    comments: '340',
    shares: '1.2K',
    duration: '0:58',
  ),
  FeedItem(
    id: '2',
    videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    thumbnail: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&q=80',
    title: 'Morning Vibes ☕',
    description: 'The perfect pour-over ritual. Slow mornings, quality beans, zero distractions.',
    category: 'Lifestyle',
    author: '@morningco',
    likes: '8.9K',
    comments: '210',
    shares: '890',
    duration: '1:05',
  ),
];

// ─── APP ──────────────────────────────────────────────────────────────────────
class ChaiShotsApp extends StatelessWidget {
  const ChaiShotsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CHAI.SHOTS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(primary: AppColors.red),
        fontFamily: 'sans-serif',
      ),
      home: const AppRoot(),
    );
  }
}

// ─── APP ROOT ─────────────────────────────────────────────────────────────────
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  int _tab = 0;
  bool _isAdmin = false;
  late List<FeedItem> _feeds;

  @override
  void initState() {
    super.initState();
    _feeds = List.from(initialFeeds);
  }

  void _addFeed(FeedItem f) => setState(() => _feeds.insert(0, f));
  void _editFeed(FeedItem f) => setState(() {
        final idx = _feeds.indexWhere((x) => x.id == f.id);
        if (idx >= 0) _feeds[idx] = f;
      });
  void _deleteFeed(String id) => setState(() => _feeds.removeWhere((x) => x.id == id));

  @override
  Widget build(BuildContext context) {
    final screens = [
      FeedScreen(feeds: _feeds),
      DiscoverScreen(feeds: _feeds),
      AdminScreen(
        feeds: _feeds,
        onAdd: _addFeed,
        onEdit: _editFeed,
        onDelete: _deleteFeed,
        isLoggedIn: _isAdmin,
        onLogin: () => setState(() => _isAdmin = true),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          screens[_tab],
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: BottomNavBar(
              activeTab: _tab,
              onTabChanged: (i) => setState(() => _tab = i),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BOTTOM NAV ───────────────────────────────────────────────────────────────
class BottomNavBar extends StatelessWidget {
  final int activeTab;
  final ValueChanged<int> onTabChanged;

  const BottomNavBar({super.key, required this.activeTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    final items = [
      const _NavItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home),
      const _NavItem(label: 'Discover', icon: Icons.search, activeIcon: Icons.search),
      const _NavItem(label: 'Admin', icon: Icons.shield_outlined, activeIcon: Icons.shield),
    ];

    return ClipRect(
      child: Container(
        height: 64 + MediaQuery.of(context).padding.bottom,
        decoration: const BoxDecoration(
          color: Color(0xEB000000),
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final active = activeTab == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTabChanged(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          active ? items[i].activeIcon : items[i].icon,
                          color: active ? Colors.white : const Color(0x73FFFFFF),
                          size: 24,
                        ),
                        if (active)
                          Positioned(
                            bottom: -8,
                            child: Container(
                              width: 4, height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i].label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : const Color(0x59FFFFFF),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem({required this.label, required this.icon, required this.activeIcon});
}

// ─── FEED SCREEN ─────────────────────────────────────────────────────────────
class FeedScreen extends StatefulWidget {
  final List<FeedItem> feeds;
  const FeedScreen({super.key, required this.feeds});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PageController _pageController = PageController();
  int _activeIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.feeds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📭', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('No videos yet', style: TextStyle(color: AppColors.text2, fontWeight: FontWeight.w700, fontSize: 16)),
            SizedBox(height: 4),
            Text('Add videos from Admin panel', style: TextStyle(color: AppColors.text3, fontSize: 13)),
          ],
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: (i) => setState(() => _activeIndex = i),
      itemCount: widget.feeds.length,
      itemBuilder: (ctx, i) => ReelItem(
        feed: widget.feeds[i],
        isActive: i == _activeIndex,
      ),
    );
  }
}

// ─── REEL ITEM ────────────────────────────────────────────────────────────────
class ReelItem extends StatefulWidget {
  final FeedItem feed;
  final bool isActive;
  const ReelItem({super.key, required this.feed, required this.isActive});

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  VideoPlayerController? _controller;
  bool _playing = false;
  bool _liked = false;
  String _likeCount = '';
  double _progress = 0;

  bool get _isVideoUrl {
    final url = widget.feed.videoUrl.toLowerCase().split('?').first;
    return ['mp4', 'webm', 'mov', 'mkv', 'ts'].any((e) => url.endsWith('.$e'));
  }

  @override
  void initState() {
    super.initState();
    _likeCount = widget.feed.likes;
    if (_isVideoUrl) {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.feed.videoUrl),
      )..initialize().then((_) {
          if (mounted) {
            setState(() {});
            if (widget.isActive) _play();
          }
        });
      _controller!.addListener(_onVideoUpdate);
      _controller!.setLooping(true);
    }
  }

  void _onVideoUpdate() {
    if (!mounted) return;
    final c = _controller;
    if (c != null && c.value.isInitialized && c.value.duration.inMilliseconds > 0) {
      setState(() {
        _progress = c.value.position.inMilliseconds / c.value.duration.inMilliseconds;
        _playing = c.value.isPlaying;
      });
    }
  }

  @override
  void didUpdateWidget(ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _play();
      } else {
        _pause();
      }
    }
  }

  void _play() {
    _controller?.play();
    setState(() => _playing = true);
  }

  void _pause() {
    _controller?.pause();
    setState(() => _playing = false);
  }

  void _togglePlay() {
    if (_playing) {
      _pause();
    } else {
      _play();
    }
  }

  void _handleLike() {
    setState(() {
      _liked = !_liked;
      _likeCount = _liked ? '$_likeCount+' : widget.feed.likes;
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoUpdate);
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final thumbLetter = widget.feed.title.isNotEmpty ? widget.feed.title[0] : '?';

    return SizedBox(
      height: size.height,
      width: size.width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Container(color: const Color(0xFF111111)),

          // Video or thumbnail
          if (_isVideoUrl && _controller != null && _controller!.value.isInitialized)
            GestureDetector(
              onTap: _togglePlay,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else if (widget.feed.thumbnail.isNotEmpty)
            Image.network(
              widget.feed.thumbnail,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackBg(thumbLetter),
            )
          else
            _fallbackBg(thumbLetter),

          // Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x59000000),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xBF000000),
                  Color(0xF2000000),
                ],
                stops: [0.0, 0.3, 0.5, 0.8, 1.0],
              ),
            ),
          ),

          // Play/pause overlay (video only)
          if (_isVideoUrl && !_playing)
            GestureDetector(
              onTap: _togglePlay,
              child: Center(
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                ),
              ),
            ),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16, right: 16, bottom: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'CHAI',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: '.',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.red,
                          ),
                        ),
                        TextSpan(
                          text: 'SHOTS',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        letterSpacing: 1, color: Colors.white,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Video format indicator
          if (_isVideoUrl)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  getVideoFormat(widget.feed.videoUrl),
                  style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: Colors.white, fontFamily: 'monospace',
                  ),
                ),
              ),
            ),

          // Right action buttons
          Positioned(
            right: 12,
            bottom: 110,
            child: Column(
              children: [
                // Avatar
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: AppColors.surface3,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.feed.author.length > 1 ? widget.feed.author[1].toUpperCase() : 'A',
                        style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900,
                          color: Color(0x80FFFFFF),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -8, left: 14,
                      child: Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: const Text('+', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w900, height: 1)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Like
                _ActionButton(
                  onTap: _handleLike,
                  active: _liked,
                  icon: _liked
                      ? const Icon(Icons.favorite, color: AppColors.red, size: 22)
                      : const Icon(Icons.favorite_border, color: Colors.white, size: 22),
                  label: _likeCount,
                ),
                const SizedBox(height: 20),

                // Comment
                _ActionButton(
                  onTap: () {},
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 22),
                  label: widget.feed.comments,
                ),
                const SizedBox(height: 20),

                // Share
                _ActionButton(
                  onTap: () {},
                  icon: const Icon(Icons.share, color: Colors.white, size: 22),
                  label: widget.feed.shares,
                ),
              ],
            ),
          ),

          // Bottom info
          Positioned(
            left: 14, right: 72, bottom: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: catColor(widget.feed.category),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (widget.feed.category).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      letterSpacing: 1.2, color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.feed.author.isNotEmpty ? widget.feed.author : '@creator',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xBFFFFFFF)),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.feed.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.feed.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Color(0xB3FFFFFF), height: 1.5),
                ),
              ],
            ),
          ),

          // Progress bar
          if (_isVideoUrl)
            Positioned(
              left: 0, right: 0, bottom: 64,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.red),
                minHeight: 2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallbackBg(String letter) {
    return Container(
      color: const Color(0xFF1A1A1A),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 80, color: Color(0x1AFFFFFF),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget icon;
  final String label;
  final bool active;

  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 180), vsync: this);
    _scale = Tween<double>(begin: 1, end: 0.75).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: widget.active
                    ? const Color(0x40E50914)
                    : Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.active
                      ? const Color(0x80E50914)
                      : Colors.white.withOpacity(0.15),
                ),
              ),
              child: Center(child: widget.icon),
            ),
            const SizedBox(height: 5),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DISCOVER SCREEN ─────────────────────────────────────────────────────────
class DiscoverScreen extends StatefulWidget {
  final List<FeedItem> feeds;
  const DiscoverScreen({super.key, required this.feeds});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _activeCat = 'All';

  List<String> get _allCats => ['All', ...{...widget.feeds.map((f) => f.category)}];

  List<FeedItem> get _filtered {
    return widget.feeds.where((f) {
      final matchCat = _activeCat == 'All' || f.category == _activeCat;
      final matchQ = _query.isEmpty ||
          f.title.toLowerCase().contains(_query.toLowerCase()) ||
          f.description.toLowerCase().contains(_query.toLowerCase());
      return matchCat && matchQ;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DISCOVER',
                  style: TextStyle(
                    fontSize: 36, fontWeight: FontWeight.w900,
                    letterSpacing: 2, color: Colors.white,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0x66FFFFFF), size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: const InputDecoration(
                            hintText: 'Search videos, categories...',
                            hintStyle: TextStyle(color: AppColors.text3),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        GestureDetector(
                          onTap: () { _searchCtrl.clear(); setState(() => _query = ''); },
                          child: const Text('×', style: TextStyle(color: AppColors.text3, fontSize: 20)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Category chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _allCats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final cat = _allCats[i];
                final active = _activeCat == cat;
                return GestureDetector(
                  onTap: () => setState(() => _activeCat = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: active
                          ? (cat == 'All' ? AppColors.red : catColor(cat))
                          : AppColors.surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? Colors.transparent : AppColors.border,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.text2,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Grid
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🔍', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('No results found', style: TextStyle(color: AppColors.text2, fontWeight: FontWeight.w700, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('Try a different search or category', style: TextStyle(color: AppColors.text3, fontSize: 13)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 9 / 16,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _GridCard(feed: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final FeedItem feed;
  const _GridCard({required this.feed});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          feed.thumbnail.isNotEmpty
              ? Image.network(feed.thumbnail, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surface3,
                    alignment: Alignment.center,
                    child: Text(
                      feed.title.isNotEmpty ? feed.title[0] : '?',
                      style: const TextStyle(fontSize: 40, color: Color(0x26FFFFFF), fontWeight: FontWeight.w900),
                    ),
                  ))
              : Container(
                  color: AppColors.surface3,
                  alignment: Alignment.center,
                  child: Text(
                    feed.title.isNotEmpty ? feed.title[0] : '?',
                    style: const TextStyle(fontSize: 40, color: Color(0x26FFFFFF), fontWeight: FontWeight.w900),
                  ),
                ),

          // Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xD9000000)],
                stops: [0.5, 1.0],
              ),
            ),
          ),

          // Overlay info
          Positioned(
            left: 10, right: 10, bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: catColor(feed.category),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    feed.category,
                    style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      letterSpacing: 1, fontFamily: 'monospace', color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  feed.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3),
                ),
                const SizedBox(height: 3),
                Text(
                  '${feed.likes} likes · ${feed.author}',
                  style: const TextStyle(fontSize: 10, color: Color(0x80FFFFFF)),
                ),
              ],
            ),
          ),

          // Duration badge
          Positioned(
            top: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                feed.duration.isNotEmpty ? feed.duration : getVideoFormat(feed.videoUrl),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ADMIN SCREEN ─────────────────────────────────────────────────────────────
class AdminScreen extends StatefulWidget {
  final List<FeedItem> feeds;
  final void Function(FeedItem) onAdd;
  final void Function(FeedItem) onEdit;
  final void Function(String) onDelete;
  final bool isLoggedIn;
  final VoidCallback onLogin;

  const AdminScreen({
    super.key,
    required this.feeds,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.isLoggedIn,
    required this.onLogin,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tabIndex = 0;
  FeedItem? _editTarget;
  FeedItem? _deleteTarget;
  String _toastMsg = '';
  String _toastType = '';

  void _showToast(String msg, String type) {
    setState(() { _toastMsg = msg; _toastType = type; });
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) setState(() { _toastMsg = ''; _toastType = ''; });
    });
  }

  void _handleAdd(FeedItem f) {
    widget.onAdd(f);
    _showToast('✅ Video published to feed!', 'success');
  }

  void _handleEdit(FeedItem f) {
    widget.onEdit(f);
    setState(() => _editTarget = null);
    _showToast('✏️ Video updated!', 'success');
  }

  void _handleDelete() {
    if (_deleteTarget != null) {
      widget.onDelete(_deleteTarget!.id);
      setState(() => _deleteTarget = null);
      _showToast('🗑️ Video deleted', 'error');
    }
  }

  int get _totalLikes {
    return widget.feeds.fold(0, (a, f) => a + (int.tryParse(f.likes.replaceAll(RegExp(r'[^\d]'), '')) ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) {
      return LoginScreen(onLogin: widget.onLogin);
    }

    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ADMIN', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2, fontFamily: 'serif')),
                        SizedBox(height: 2),
                        Text('Content Dashboard', style: TextStyle(fontSize: 12, color: AppColors.text3, fontFamily: 'monospace')),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.redDim,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0x4DE50914)),
                      ),
                      child: const Text('● LIVE', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.red, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              // Stats bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    _StatChip(num: '${widget.feeds.length}', label: 'VIDEOS'),
                    const SizedBox(width: 8),
                    _StatChip(
                      num: _totalLikes > 999 ? '${(_totalLikes / 1000).toStringAsFixed(1)}K' : '$_totalLikes',
                      label: 'LIKES',
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      num: '${widget.feeds.map((f) => f.category).toSet().length}',
                      label: 'CATS',
                    ),
                  ],
                ),
              ),

              // Tabs
              Row(
                children: [
                  _AdminTab(label: 'Upload New', active: _tabIndex == 0, onTap: () => setState(() => _tabIndex = 0)),
                  _AdminTab(label: 'Manage (${widget.feeds.length})', active: _tabIndex == 1, onTap: () => setState(() => _tabIndex = 1)),
                ],
              ),

              // Content
              Expanded(
                child: _tabIndex == 0
                    ? VideoFormScreen(
                        onSubmit: (form) => _handleAdd(FeedItem(
                          id: _uid(),
                          videoUrl: form['videoUrl']!,
                          thumbnail: form['thumbnail']!,
                          title: form['title']!,
                          description: form['description']!,
                          category: form['category']!,
                          author: form['author']!,
                          likes: form['likes']!.isEmpty ? '0' : form['likes']!,
                          comments: form['comments']!.isEmpty ? '0' : form['comments']!,
                          shares: '0',
                          duration: form['duration']!,
                        )),
                      )
                    : _ManageTab(
                        feeds: widget.feeds,
                        onEdit: (f) => setState(() => _editTarget = f),
                        onDelete: (f) => setState(() => _deleteTarget = f),
                      ),
              ),
            ],
          ),
        ),

        // Edit modal
        if (_editTarget != null)
          EditModal(
            feed: _editTarget!,
            onSave: _handleEdit,
            onClose: () => setState(() => _editTarget = null),
          ),

        // Delete modal
        if (_deleteTarget != null)
          DeleteModal(
            feed: _deleteTarget!,
            onConfirm: _handleDelete,
            onClose: () => setState(() => _deleteTarget = null),
          ),

        // Toast
        if (_toastMsg.isNotEmpty)
          Positioned(
            bottom: 90, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface3,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _toastType == 'success'
                        ? const Color(0x6622C55E)
                        : const Color(0x66E50914),
                  ),
                ),
                child: Text(
                  _toastMsg,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: _toastType == 'success' ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String num;
  final String label;
  const _StatChip({required this.num, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(num, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'serif')),
            const SizedBox(height: 1),
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.text3, fontFamily: 'monospace', letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class _AdminTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _AdminTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.red : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.text3,
            ),
          ),
        ),
      ),
    );
  }
}

class _ManageTab extends StatelessWidget {
  final List<FeedItem> feeds;
  final void Function(FeedItem) onEdit;
  final void Function(FeedItem) onDelete;

  const _ManageTab({required this.feeds, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (feeds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📭', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('No videos added', style: TextStyle(color: AppColors.text2, fontWeight: FontWeight.w700, fontSize: 16)),
            SizedBox(height: 4),
            Text('Go to Upload tab to add videos', style: TextStyle(color: AppColors.text3, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: feeds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final feed = feeds[i];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumb
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 80, height: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      feed.thumbnail.isNotEmpty
                          ? Image.network(feed.thumbnail, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.surface3,
                                alignment: Alignment.center,
                                child: Text(feed.title.isNotEmpty ? feed.title[0] : '?',
                                    style: const TextStyle(fontSize: 28, color: Color(0x26FFFFFF), fontWeight: FontWeight.w900)),
                              ))
                          : Container(
                              color: AppColors.surface3,
                              alignment: Alignment.center,
                              child: Text(feed.title.isNotEmpty ? feed.title[0] : '?',
                                  style: const TextStyle(fontSize: 28, color: Color(0x26FFFFFF), fontWeight: FontWeight.w900)),
                            ),
                      Positioned(
                        bottom: 4, left: 4, right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            getVideoFormat(feed.videoUrl),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: catColor(feed.category),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(feed.category,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, fontFamily: 'monospace', color: Colors.white)),
                          ),
                          if (feed.duration.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(feed.duration, style: const TextStyle(fontSize: 10, color: AppColors.text3, fontFamily: 'monospace')),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feed.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feed.description.isNotEmpty ? feed.description : 'No description',
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.text2, height: 1.5),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => onEdit(feed),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0x263B82F6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0x403B82F6)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.edit, size: 12, color: Color(0xFF60A5FA)),
                                    SizedBox(width: 6),
                                    Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF60A5FA))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => onDelete(feed),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0x1FE50914),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0x40E50914)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_outline, size: 12, color: Color(0xFFF87171)),
                                    SizedBox(width: 6),
                                    Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF87171))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── VIDEO FORM ───────────────────────────────────────────────────────────────
class VideoFormScreen extends StatefulWidget {
  final void Function(Map<String, String>) onSubmit;
  final Map<String, String>? initial;
  final String? submitLabel;
  final VoidCallback? onCancel;

  const VideoFormScreen({
    super.key,
    required this.onSubmit,
    this.initial,
    this.submitLabel,
    this.onCancel,
  });

  @override
  State<VideoFormScreen> createState() => _VideoFormScreenState();
}

class _VideoFormScreenState extends State<VideoFormScreen> {
  final Map<String, TextEditingController> _ctrls = {};
  String _category = 'General';

  final _fields = [
    ('videoUrl', 'VIDEO URL *', 'https://example.com/video.mp4'),
    ('thumbnail', 'THUMBNAIL URL', 'https://example.com/thumb.jpg'),
    ('title', 'TITLE *', 'Enter video title...'),
    ('description', 'DESCRIPTION', "What's this video about?"),
    ('author', 'AUTHOR', '@handle'),
    ('likes', 'LIKES', '0'),
    ('comments', 'COMMENTS', '0'),
    ('duration', 'DURATION', '1:30'),
  ];

  @override
  void initState() {
    super.initState();
    for (final f in _fields) {
      _ctrls[f.$1] = TextEditingController(text: widget.initial?[f.$1] ?? '');
    }
    _category = widget.initial?['category'] ?? 'General';
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canSubmit =>
      _ctrls['videoUrl']!.text.trim().isNotEmpty &&
      _ctrls['title']!.text.trim().isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;
    widget.onSubmit({
      for (final f in _fields) f.$1: _ctrls[f.$1]!.text.trim(),
      'category': _category,
    });
    // Reset if no initial (add form)
    if (widget.initial == null) {
      for (final c in _ctrls.values) {
        c.clear();
      }
      setState(() => _category = 'General');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        for (final f in _fields) ...[
          _FieldLabel(f.$2),
          const SizedBox(height: 6),
          if (f.$1 == 'description')
            _buildInput(f.$1, f.$3, maxLines: 3)
          else
            _buildInput(f.$1, f.$3),
          const SizedBox(height: 14),
        ],

        // Category
        const _FieldLabel('CATEGORY'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _category,
              dropdownColor: AppColors.surface2,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'sans-serif'),
              iconEnabledColor: Colors.grey,
              isExpanded: true,
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Buttons
        Row(
          children: [
            if (widget.onCancel != null) ...[
              Expanded(
                child: GestureDetector(
                  onTap: widget.onCancel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text2)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _canSubmit ? _submit : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _canSubmit ? AppColors.red : AppColors.red.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _canSubmit
                        ? [const BoxShadow(color: Color(0x59E50914), blurRadius: 24, offset: Offset(0, 4))]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upload, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        widget.submitLabel ?? 'PUBLISH TO FEED',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInput(String key, String hint, {int maxLines = 1}) {
    return TextField(
      controller: _ctrls[key],
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.text3),
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1,
        color: AppColors.text3, fontFamily: 'monospace',
      ),
    );
  }
}

// ─── EDIT MODAL ───────────────────────────────────────────────────────────────
class EditModal extends StatelessWidget {
  final FeedItem feed;
  final void Function(FeedItem) onSave;
  final VoidCallback onClose;

  const EditModal({super.key, required this.feed, required this.onSave, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {}, // Prevent closing when tapping inside
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: AppColors.border),
                left: BorderSide(color: AppColors.border),
                right: BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(top: 14),
                  decoration: BoxDecoration(color: AppColors.surface3, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('EDIT', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontFamily: 'serif')),
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          alignment: Alignment.center,
                          child: const Text('✕', style: TextStyle(color: AppColors.text2, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: VideoFormScreen(
                    initial: {
                      'videoUrl': feed.videoUrl,
                      'thumbnail': feed.thumbnail,
                      'title': feed.title,
                      'description': feed.description,
                      'category': feed.category,
                      'author': feed.author,
                      'likes': feed.likes,
                      'comments': feed.comments,
                      'duration': feed.duration,
                    },
                    onSubmit: (form) => onSave(FeedItem(
                      id: feed.id,
                      videoUrl: form['videoUrl']!,
                      thumbnail: form['thumbnail']!,
                      title: form['title']!,
                      description: form['description']!,
                      category: form['category']!,
                      author: form['author']!,
                      likes: form['likes']!,
                      comments: form['comments']!,
                      shares: feed.shares,
                      duration: form['duration']!,
                    )),
                    onCancel: onClose,
                    submitLabel: 'SAVE CHANGES',
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

// ─── DELETE MODAL ─────────────────────────────────────────────────────────────
class DeleteModal extends StatelessWidget {
  final FeedItem feed;
  final VoidCallback onConfirm;
  final VoidCallback onClose;

  const DeleteModal({super.key, required this.feed, required this.onConfirm, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {}, // Prevent closing when tapping inside
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: AppColors.border),
                left: BorderSide(color: AppColors.border),
                right: BorderSide(color: AppColors.border),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: AppColors.surface3, borderRadius: BorderRadius.circular(2)),
                ),
                const Text('🗑️', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                const Text('DELETE VIDEO', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1, fontFamily: 'serif')),
                const SizedBox(height: 8),
                Text(
                  'Remove "${feed.title}" from the feed? This cannot be undone.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.text2, fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onClose,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          alignment: Alignment.center,
                          child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text2)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: onConfirm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text('Delete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── LOGIN SCREEN ─────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _error = '';
  bool _loading = false;

  void _login() {
    if (_userCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Enter credentials');
      return;
    }
    setState(() { _loading = true; _error = ''; });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_userCtrl.text == 'admin' && _passCtrl.text == '1234') {
        widget.onLogin();
      } else {
        if (mounted) setState(() { _error = 'Invalid credentials'; _loading = false; });
      }
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(text: 'CHAI', style: TextStyle(fontFamily: 'serif', fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 4)),
                  TextSpan(text: '.', style: TextStyle(fontFamily: 'serif', fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.red)),
                  TextSpan(text: 'SHOTS', style: TextStyle(fontFamily: 'serif', fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 4)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('ADMIN PANEL', style: TextStyle(fontSize: 13, color: AppColors.text3, fontFamily: 'monospace')),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const _FieldLabel('USERNAME'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _userCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: _inputDecoration('admin'),
                    onChanged: (_) => setState(() => _error = ''),
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 14),
                  const _FieldLabel('PASSWORD'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: _inputDecoration('••••'),
                    onChanged: (_) => setState(() => _error = ''),
                    onSubmitted: (_) => _login(),
                  ),
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('⚠️ $_error', style: const TextStyle(color: Color(0xFFF87171), fontSize: 12, fontFamily: 'monospace')),
                  ],
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _loading ? null : _login,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [BoxShadow(color: Color(0x59E50914), blurRadius: 24, offset: Offset(0, 4))],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _loading ? 'Authenticating...' : 'LOGIN →',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('ID: admin · PASS: 1234', style: TextStyle(fontSize: 11, color: AppColors.text3, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.text3),
      filled: true,
      fillColor: AppColors.surface3,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.red)),
    );
  }
}