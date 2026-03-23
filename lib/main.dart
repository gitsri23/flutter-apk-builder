import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait + landscape (full APK support)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Edge-to-edge immersive mode
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A237E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MiniBrowserApp());
}

// ─────────────────────────────────────────────
//  COLOR PALETTE  — Deep Navy + Electric Cyan
// ─────────────────────────────────────────────
class AppColors {
  static const primary       = Color(0xFF1A237E); // Deep Indigo
  static const primaryLight  = Color(0xFF283593); // Indigo 800
  static const accent        = Color(0xFF00E5FF); // Electric Cyan
  static const accentDim     = Color(0xFF00B8D4); // Cyan 700
  static const surface       = Color(0xFFF0F4FF); // Icy Blue-White
  static const card          = Color(0xFFFFFFFF);
  static const textPrimary   = Color(0xFF0D1B5E);
  static const textSecondary = Color(0xFF5C6BC0);
  static const danger        = Color(0xFFE53935);
  static const success       = Color(0xFF00C853);
}

// ─────────────────────────────────────────────
//  DATA MODEL — History Entry
// ─────────────────────────────────────────────
class HistoryEntry {
  final String url;
  final String title;
  final DateTime visitedAt;

  HistoryEntry({
    required this.url,
    required this.title,
    required this.visitedAt,
  });

  String get displayTitle => title.isNotEmpty ? title : url;
  String get domain {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }
}

// ─────────────────────────────────────────────
//  APP ROOT
// ─────────────────────────────────────────────
class MiniBrowserApp extends StatelessWidget {
  const MiniBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orbit Browser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.primary,
        ),
      ),
      home: const BrowserScreen(),
    );
  }
}

// ─────────────────────────────────────────────
//  BROWSER SCREEN
// ─────────────────────────────────────────────
class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen>
    with TickerProviderStateMixin {
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();

  final List<HistoryEntry> _history = [];
  bool _isLoading = false;
  double _loadProgress = 0.0;
  String _pageTitle = '';
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isUrlFocused = false;

  // Animation for progress bar
  late AnimationController _progressAnimController;

  static const String _homePage = 'https://google.com';
  static const String _initialUrl = 'https://flutter.dev';

  @override
  void initState() {
    super.initState();

    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _urlFocusNode.addListener(() {
      setState(() => _isUrlFocused = _urlFocusNode.hasFocus);
      if (_urlFocusNode.hasFocus) {
        _urlController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _urlController.text.length,
        );
      }
    });

    _urlController.text = _initialUrl;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.surface)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() => _loadProgress = progress / 100.0);
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _loadProgress = 0.1;
              if (!_urlFocusNode.hasFocus) {
                _urlController.text = url;
              }
            });
            _updateNavButtons();
          },
          onPageFinished: (String url) async {
            final title = await _controller.getTitle() ?? '';
            setState(() {
              _isLoading = false;
              _loadProgress = 1.0;
              _pageTitle = title;
              if (!_urlFocusNode.hasFocus) {
                _urlController.text = url;
              }
              // Add to history (avoid consecutive duplicates)
              if (_history.isEmpty || _history.last.url != url) {
                _history.add(HistoryEntry(
                  url: url,
                  title: title,
                  visitedAt: DateTime.now(),
                ));
              }
            });
            _updateNavButtons();
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation (you can add blocklist here)
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Failed to load page',
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_initialUrl));
  }

  Future<void> _updateNavButtons() async {
    final back = await _controller.canGoBack();
    final fwd = await _controller.canGoForward();
    if (mounted) {
      setState(() {
        _canGoBack = back;
        _canGoForward = fwd;
      });
    }
  }

  void _loadUrl(String url) {
    _urlFocusNode.unfocus();
    url = url.trim();
    if (url.isEmpty) return;

    // Smart URL detection
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // If it looks like a domain, add https. Otherwise, search Google.
      final domainRegex = RegExp(
          r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+');
      if (domainRegex.hasMatch(url)) {
        url = 'https://$url';
      } else {
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
      }
    }

    _controller.loadRequest(Uri.parse(url));
    setState(() => _urlController.text = url);
  }

  void _openHistory() async {
    final result = await Navigator.push<_HistoryAction>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => HistoryScreen(history: _history),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    );

    if (result == null) return;

    if (result.cleared) {
      setState(() => _history.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('History cleared', style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (result.urlToLoad != null) {
      _loadUrl(result.urlToLoad!);
    }
  }

  void _copyUrl() {
    final url = _urlController.text;
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.copy_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('URL copied', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: AppColors.accentDim,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    _progressAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      // ── App Bar ──
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF283593)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x3300E5FF),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // ── URL / Search Bar ──
                  Expanded(
                    child: GestureDetector(
                      onLongPress: _copyUrl,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 42,
                        decoration: BoxDecoration(
                          color: _isUrlFocused
                              ? Colors.white
                              : Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _isUrlFocused
                                ? AppColors.accent
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Icon(
                              _isLoading
                                  ? Icons.autorenew_rounded
                                  : Icons.search_rounded,
                              color: _isUrlFocused
                                  ? AppColors.primary
                                  : Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _urlController,
                                focusNode: _urlFocusNode,
                                style: TextStyle(
                                  color: _isUrlFocused
                                      ? AppColors.textPrimary
                                      : Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search or enter URL...',
                                  hintStyle: TextStyle(
                                    color: _isUrlFocused
                                        ? Colors.grey.shade400
                                        : Colors.white54,
                                    fontSize: 13.5,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                textInputAction: TextInputAction.go,
                                keyboardType: TextInputType.url,
                                autocorrect: false,
                                onSubmitted: _loadUrl,
                              ),
                            ),
                            if (_isUrlFocused)
                              GestureDetector(
                                onTap: () {
                                  _urlController.clear();
                                  _urlFocusNode.requestFocus();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Icon(Icons.cancel_rounded,
                                      color: Colors.grey.shade400, size: 18),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // ── History Button ──
                  _AppBarIconBtn(
                    icon: Icons.history_rounded,
                    tooltip: 'History',
                    badge: _history.length,
                    onPressed: _openHistory,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // ── Body: WebView + Progress ──
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          // Progress Bar (shown only while loading)
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: LinearProgressIndicator(
                  value: _loadProgress,
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accent),
                ),
              ),
            ),
        ],
      ),

      // ── Bottom Navigation Bar ──
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF1E2B8F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x2200E5FF),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: 'Back',
                  enabled: _canGoBack,
                  onPressed: () async {
                    if (await _controller.canGoBack()) {
                      _controller.goBack();
                    }
                  },
                ),
                _NavBtn(
                  icon: Icons.arrow_forward_ios_rounded,
                  tooltip: 'Forward',
                  enabled: _canGoForward,
                  onPressed: () async {
                    if (await _controller.canGoForward()) {
                      _controller.goForward();
                    }
                  },
                ),
                _NavBtn(
                  icon: _isLoading
                      ? Icons.close_rounded
                      : Icons.refresh_rounded,
                  tooltip: _isLoading ? 'Stop' : 'Refresh',
                  enabled: true,
                  onPressed: () {
                    if (_isLoading) {
                      _controller.loadRequest(Uri.parse('about:blank'));
                    } else {
                      _controller.reload();
                    }
                  },
                ),
                _NavBtn(
                  icon: Icons.home_rounded,
                  tooltip: 'Home',
                  enabled: true,
                  onPressed: () => _loadUrl(_homePage),
                ),
                _NavBtn(
                  icon: Icons.share_rounded,
                  tooltip: 'Share',
                  enabled: true,
                  onPressed: () {
                    final url = _urlController.text;
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Link copied to clipboard'),
                        backgroundColor: AppColors.accentDim,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────
class _AppBarIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final int badge;

  const _AppBarIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            if (badge > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  const _NavBtn({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white24,
          size: 22,
        ),
        onPressed: enabled ? onPressed : null,
        splashRadius: 24,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HISTORY ACTION (result from HistoryScreen)
// ─────────────────────────────────────────────
class _HistoryAction {
  final bool cleared;
  final String? urlToLoad;
  _HistoryAction({this.cleared = false, this.urlToLoad});
}

// ─────────────────────────────────────────────
//  HISTORY SCREEN
// ─────────────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  final List<HistoryEntry> history;

  const HistoryScreen({super.key, required this.history});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<HistoryEntry> _filtered;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filtered = widget.history.reversed.toList();
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.history.reversed.toList();
      } else {
        _filtered = widget.history.reversed
            .where((e) =>
                e.url.toLowerCase().contains(query.toLowerCase()) ||
                e.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Search history...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: _search,
              )
            : const Text(
                'History',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchCtrl.clear();
                  _filtered = widget.history.reversed.toList();
                }
              });
            },
          ),
          if (widget.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
              tooltip: 'Clear all',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('Clear History?'),
                    content: const Text(
                        'This will delete all browsing history.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.danger),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(
                              context, _HistoryAction(cleared: true));
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: widget.history.isEmpty
          ? _EmptyState()
          : _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No results found',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final entry = _filtered[index];
                    return _HistoryTile(
                      entry: entry,
                      timeLabel: _formatTime(entry.visitedAt),
                      onTap: () => Navigator.pop(
                          context,
                          _HistoryAction(urlToLoad: entry.url)),
                    );
                  },
                ),
    );
  }
}

// ─────────────────────────────────────────────
//  HISTORY TILE
// ─────────────────────────────────────────────
class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;
  final String timeLabel;
  final VoidCallback onTap;

  const _HistoryTile({
    required this.entry,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1A237E),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.language_rounded,
              color: AppColors.primaryLight, size: 20),
        ),
        title: Text(
          entry.displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          entry.domain,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Text(
          timeLabel,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EMPTY STATE WIDGET
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 2),
            ),
            child: const Icon(
              Icons.history_toggle_off_rounded,
              size: 44,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No browsing history yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pages you visit will appear here',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}