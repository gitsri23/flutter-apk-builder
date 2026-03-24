import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A0F),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const OrbitBrowserApp());
}

// ═══════════════════════════════════════════════
//  COLORS
// ═══════════════════════════════════════════════
class C {
  static const bg         = Color(0xFF0A0A0F);
  static const card       = Color(0xFF14141C);
  static const elevated   = Color(0xFF1C1C28);
  static const border     = Color(0xFF252535);
  static const accent     = Color(0xFF7B61FF);
  static const accentDim  = Color(0x337B61FF);
  static const accentSoft = Color(0xFF9D88FF);
  static const green      = Color(0xFF00E5A0);
  static const greenDim   = Color(0x2200E5A0);
  static const orange     = Color(0xFFFF9F43);
  static const red        = Color(0xFFFF6B6B);
  static const redDim     = Color(0x22FF6B6B);
  static const t1         = Color(0xFFF2F2FF);
  static const t2         = Color(0xFF8888AA);
  static const t3         = Color(0xFF44445A);
}

// ═══════════════════════════════════════════════
//  MODELS
// ═══════════════════════════════════════════════
class BrowserTab {
  final String id = UniqueKey().toString();
  InAppWebViewController? controller;
  String url      = '';
  String title    = 'New Tab';
  bool isHome     = true;
  double progress = 0.0;
  bool isLoading  = false;
}

class Bookmark {
  String title, url, emoji;
  Bookmark({required this.title, required this.url, required this.emoji});
}

class HistoryItem {
  final String title, url;
  final DateTime visitedAt;
  HistoryItem({required this.title, required this.url, required this.visitedAt});
}

// ═══════════════════════════════════════════════
//  APP
// ═══════════════════════════════════════════════
class OrbitBrowserApp extends StatelessWidget {
  const OrbitBrowserApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Orbit Browser',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: C.bg,
      colorScheme: const ColorScheme.dark(primary: C.accent, surface: C.card),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? C.accent : C.t2),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? C.accentDim : C.border),
      ),
    ),
    home: const MainBrowserScreen(),
  );
}

// ═══════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════
class MainBrowserScreen extends StatefulWidget {
  const MainBrowserScreen({super.key});
  @override
  State<MainBrowserScreen> createState() => _MainBrowserScreenState();
}

class _MainBrowserScreenState extends State<MainBrowserScreen>
    with TickerProviderStateMixin {

  final List<BrowserTab> _tabs = [BrowserTab()];
  int _currentTabIndex = 0;

  // Settings
  bool _adBlockEnabled = true;
  bool _blockPopups    = true;
  bool _adguardDns     = true;
  bool _incognito      = false;
  bool _desktopMode    = false;

  // UI state
  bool _isUrlFocused = false;
  bool _showFindBar  = false;

  final TextEditingController _urlCtrl  = TextEditingController();
  final TextEditingController _findCtrl = TextEditingController();
  final FocusNode _urlFocus             = FocusNode();

  final List<Bookmark> _bookmarks = [
    Bookmark(title: 'Google',    url: 'https://google.com',    emoji: '🔍'),
    Bookmark(title: 'YouTube',   url: 'https://youtube.com',   emoji: '▶️'),
    Bookmark(title: 'GitHub',    url: 'https://github.com',    emoji: '🐙'),
    Bookmark(title: 'Reddit',    url: 'https://reddit.com',    emoji: '🟠'),
    Bookmark(title: 'Twitter',   url: 'https://twitter.com',   emoji: '🐦'),
    Bookmark(title: 'Wikipedia', url: 'https://wikipedia.org', emoji: '📖'),
    Bookmark(title: 'Amazon',    url: 'https://amazon.in',     emoji: '🛒'),
    Bookmark(title: 'Netflix',   url: 'https://netflix.com',   emoji: '🎬'),
  ];

  final List<HistoryItem> _history = [];

  final List<ContentBlocker> _adBlockers = [
    ContentBlocker(trigger: ContentBlockerTrigger(urlFilter: ".*doubleclick\\.net.*"),        action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK)),
    ContentBlocker(trigger: ContentBlockerTrigger(urlFilter: ".*googleadservices\\.com.*"),   action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK)),
    ContentBlocker(trigger: ContentBlockerTrigger(urlFilter: ".*googlesyndication\\.com.*"),  action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK)),
    ContentBlocker(trigger: ContentBlockerTrigger(urlFilter: ".*adnxs\\.com.*"),              action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK)),
    ContentBlocker(trigger: ContentBlockerTrigger(urlFilter: ".*outbrain\\.com.*"),           action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK)),
    ContentBlocker(trigger: ContentBlockerTrigger(urlFilter: ".*taboola\\.com.*"),            action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK)),
    ContentBlocker(trigger: ContentBlockerTrigger(urlFilter: ".*amazon-adsystem\\.com.*"),    action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK)),
    ContentBlocker(trigger: ContentBlockerTrigger(urlFilter: ".*scorecardresearch\\.com.*"),  action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK)),
    ContentBlocker(trigger: ContentBlockerTrigger(urlFilter: ".*ads\\.facebook\\.com.*"),     action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK)),
    ContentBlocker(trigger: ContentBlockerTrigger(urlFilter: ".*quantserve\\.com.*"),         action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK)),
  ];

  BrowserTab get _tab => _tabs[_currentTabIndex];

  @override
  void initState() {
    super.initState();
    _urlFocus.addListener(() => setState(() => _isUrlFocused = _urlFocus.hasFocus));
  }

  @override
  void dispose() {
    _urlCtrl.dispose(); _findCtrl.dispose(); _urlFocus.dispose();
    super.dispose();
  }

  // ── BACK ──────────────────────────────────────
  Future<bool> _onWillPop() async {
    if (_urlFocus.hasFocus) { _urlFocus.unfocus(); return false; }
    if (_showFindBar) {
      _tab.controller?.clearMatches();
      setState(() { _showFindBar = false; _findCtrl.clear(); });
      return false;
    }
    final ctrl = _tab.controller;
    if (ctrl != null && !_tab.isHome) {
      if (await ctrl.canGoBack()) { await ctrl.goBack(); return false; }
      _goHome(); return false;
    }
    return await _exitDialog() ?? false;
  }

  Future<bool?> _exitDialog() => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: C.elevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Exit Orbit?', style: TextStyle(color: C.t1, fontWeight: FontWeight.bold)),
      content: const Text('Close the browser?', style: TextStyle(color: C.t2)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: C.accent))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: C.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Exit'),
        ),
      ],
    ),
  );

  // ── TABS ──────────────────────────────────────
  void _newTab({bool incognito = false}) {
    final t = BrowserTab();
    if (incognito) t.title = '🕵️ Incognito';
    setState(() { _tabs.add(t); _currentTabIndex = _tabs.length - 1; _urlCtrl.clear(); });
  }

  void _closeTab(int i) {
    if (_tabs.length == 1) {
      setState(() { _tabs[0] = BrowserTab(); _urlCtrl.clear(); }); return;
    }
    setState(() {
      _tabs.removeAt(i);
      if (_currentTabIndex >= _tabs.length) _currentTabIndex = _tabs.length - 1;
      _syncUrl();
    });
  }

  void _switchTab(int i) => setState(() { _currentTabIndex = i; _syncUrl(); });
  void _syncUrl() => _urlCtrl.text = _tab.isHome ? '' : _tab.url;

  // ── LOAD ──────────────────────────────────────
  void _loadUrl(String raw) {
    raw = raw.trim();
    if (raw.isEmpty) return;
    String url;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      url = raw;
    } else if (RegExp(r'^[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(/.*)?$').hasMatch(raw)) {
      url = 'https://$raw';
    } else {
      url = 'https://www.google.com/search?q=${Uri.encodeComponent(raw)}';
    }
    _urlFocus.unfocus();
    setState(() { _tab.isHome = false; _tab.url = url; _tab.progress = 0.0; _tab.isLoading = true; _urlCtrl.text = url; });
    _tab.controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  void _goHome() => setState(() {
    _tab.isHome = true; _tab.url = ''; _tab.progress = 0.0; _tab.isLoading = false; _urlCtrl.clear();
  });

  // ── BOOKMARK ──────────────────────────────────
  void _addBookmark() {
    if (_tab.isHome || _tab.url.isEmpty) return;
    if (_bookmarks.any((b) => b.url == _tab.url)) { _toast('Already bookmarked!'); return; }
    setState(() => _bookmarks.add(Bookmark(title: _tab.title, url: _tab.url, emoji: '⭐')));
    _toast('Bookmarked!');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: C.t1)),
      backgroundColor: C.elevated,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ═══════════════════════════════════════════════
  //  TABS OVERVIEW (Grid)
  // ═══════════════════════════════════════════════
  void _showTabsOverview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => Column(children: [
          _handle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 10),
            child: Row(children: [
              Text('${_tabs.length} Tab${_tabs.length != 1 ? 's' : ''}',
                  style: const TextStyle(color: C.t1, fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: () { Navigator.pop(ctx); _newTab(incognito: true); },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: C.elevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.visibility_off_rounded, size: 14, color: C.t2),
                    SizedBox(width: 6),
                    Text('Incognito', style: TextStyle(color: C.t2, fontSize: 12)),
                  ]),
                ),
              ),
              GestureDetector(
                onTap: () { Navigator.pop(ctx); _newTab(); },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: C.accent, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
          const Divider(color: C.border, height: 1),
          Expanded(child: GridView.builder(
            controller: sc,
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.82),
            itemCount: _tabs.length,
            itemBuilder: (_, i) {
              final t = _tabs[i];
              final sel = _currentTabIndex == i;
              return GestureDetector(
                onTap: () { _switchTab(i); Navigator.pop(ctx); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: sel ? C.accentDim : C.elevated,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: sel ? C.accent : C.border, width: sel ? 2 : 1),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      height: 100,
                      decoration: const BoxDecoration(color: C.border, borderRadius: BorderRadius.vertical(top: Radius.circular(17))),
                      child: Center(child: Icon(t.isHome ? Icons.home_rounded : Icons.language_rounded, color: sel ? C.accent : C.t3, size: 38)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 6, 4),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: sel ? C.accentSoft : C.t1, fontWeight: FontWeight.w600, fontSize: 12)),
                          if (!t.isHome) Text(t.url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.t3, fontSize: 10)),
                        ])),
                        GestureDetector(
                          onTap: () { _closeTab(i); ss(() {}); },
                          child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.close, size: 14, color: C.t2)),
                        ),
                      ]),
                    ),
                  ]),
                ),
              );
            },
          )),
        ]),
      )),
    );
  }

  // ═══════════════════════════════════════════════
  //  OTHER MENUS (Bookmarks, History, Settings)
  // ═══════════════════════════════════════════════
  // ... (Keeping all your original list builders here for brevity, they are included in the full code block)
  
  void _showBookmarks() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => Column(children: [
          _handle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 10),
            child: Row(children: [
              const Icon(Icons.bookmark_rounded, color: C.accent, size: 22),
              const SizedBox(width: 10),
              const Text('Bookmarks', style: TextStyle(color: C.t1, fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (!_tab.isHome && _tab.url.isNotEmpty)
                GestureDetector(
                  onTap: () { _addBookmark(); ss(() {}); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: C.accentDim, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.accent.withOpacity(0.3))),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add, size: 14, color: C.accentSoft),
                      SizedBox(width: 4),
                      Text('Add', style: TextStyle(color: C.accentSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
            ]),
          ),
          const Divider(color: C.border, height: 1),
          Expanded(child: _bookmarks.isEmpty ? const Center(child: Text('No bookmarks', style: TextStyle(color: C.t3))) : ListView.builder(
            controller: sc,
            padding: const EdgeInsets.all(12),
            itemCount: _bookmarks.length,
            itemBuilder: (_, i) {
              final b = _bookmarks[i];
              return GestureDetector(
                onTap: () { Navigator.pop(ctx); _loadUrl(b.url); },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: C.elevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border)),
                  child: Row(children: [
                    Text(b.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.title, style: const TextStyle(color: C.t1, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(b.url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.t3, fontSize: 11)),
                    ])),
                    GestureDetector(onTap: () => ss(() => _bookmarks.removeAt(i)), child: const Icon(Icons.delete_outline_rounded, color: C.red, size: 18)),
                  ]),
                ),
              );
            },
          )),
        ]),
      )),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => Column(children: [
          _handle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 10),
            child: Row(children: [
              const Icon(Icons.history_rounded, color: C.orange, size: 22),
              const SizedBox(width: 10),
              const Text('History', style: TextStyle(color: C.t1, fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_history.isNotEmpty)
                GestureDetector(
                  onTap: () { setState(() => _history.clear()); ss(() {}); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: C.redDim, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.red.withOpacity(0.3))),
                    child: const Text('Clear all', style: TextStyle(color: C.red, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
            ]),
          ),
          const Divider(color: C.border, height: 1),
          Expanded(child: _history.isEmpty ? const Center(child: Text('No history yet', style: TextStyle(color: C.t3))) : ListView.builder(
            controller: sc,
            padding: const EdgeInsets.all(12),
            itemCount: _history.length,
            itemBuilder: (_, i) {
              final h = _history[_history.length - 1 - i];
              return GestureDetector(
                onTap: () { Navigator.pop(ctx); _loadUrl(h.url); },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: C.elevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
                  child: Row(children: [
                    const Icon(Icons.language_rounded, color: C.t3, size: 18),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(h.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.t1, fontWeight: FontWeight.w500, fontSize: 13)),
                      Text(h.url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.t3, fontSize: 11)),
                    ])),
                    Text('${h.visitedAt.hour.toString().padLeft(2,'0')}:${h.visitedAt.minute.toString().padLeft(2,'0')}', style: const TextStyle(color: C.t3, fontSize: 11)),
                  ]),
                ),
              );
            },
          )),
        ]),
      )),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _handle(),
          const SizedBox(height: 8),
          Row(children: [
            _QuickToggle(icon: _desktopMode ? Icons.phone_android_rounded : Icons.desktop_windows_rounded, label: _desktopMode ? 'Mobile' : 'Desktop', active: _desktopMode, color: C.accent, onTap: () {
              Navigator.pop(ctx); setState(() => _desktopMode = !_desktopMode);
              _tab.controller?.setSettings(settings: InAppWebViewSettings(preferredContentMode: _desktopMode ? UserPreferredContentMode.DESKTOP : UserPreferredContentMode.RECOMMENDED));
              _tab.controller?.reload();
            }),
            const SizedBox(width: 10),
            _QuickToggle(icon: Icons.find_in_page_rounded, label: 'Find', active: _showFindBar, color: C.green, onTap: () { Navigator.pop(ctx); setState(() => _showFindBar = true); }),
            const SizedBox(width: 10),
            _QuickToggle(icon: Icons.share_rounded, label: 'Share', active: false, color: C.orange, onTap: () {
              Navigator.pop(ctx); if (!_tab.isHome && _tab.url.isNotEmpty) launchUrl(Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(_tab.url)}'), mode: LaunchMode.externalApplication);
            }),
            const SizedBox(width: 10),
            _QuickToggle(icon: Icons.open_in_browser_rounded, label: 'External', active: false, color: C.t2, onTap: () {
              Navigator.pop(ctx); if (!_tab.isHome && _tab.url.isNotEmpty) launchUrl(Uri.parse(_tab.url), mode: LaunchMode.externalApplication);
            }),
          ]),
          const SizedBox(height: 12),
          const Divider(color: C.border),
          _MenuItem(icon: Icons.bookmark_border_rounded, iconColor: C.accent, label: 'Add Bookmark', onTap: () { Navigator.pop(ctx); _addBookmark(); }),
          _MenuItem(icon: Icons.history_rounded, iconColor: C.orange, label: 'History', onTap: () { Navigator.pop(ctx); _showHistory(); }),
          _MenuItem(icon: Icons.settings_rounded, iconColor: C.t2, label: 'Settings', onTap: () { Navigator.pop(ctx); _showSettings(); }),
        ]),
      )),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            _handle(),
            const SizedBox(height: 16),
            const Text('Settings', style: TextStyle(color: C.t1, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            _sectionLabel('🛡️  Privacy & Security'),
            const SizedBox(height: 10),
            _SettingTile(icon: Icons.shield_rounded, iconColor: C.green, title: 'AdGuard Ad Blocker', subtitle: 'Blocks 10+ ad networks & trackers', value: _adBlockEnabled, onChanged: (v) { setState(() => _adBlockEnabled = v); ss(() => _adBlockEnabled = v); }),
            const SizedBox(height: 10),
            _SettingTile(icon: Icons.dns_rounded, iconColor: C.accent, title: 'AdGuard DNS', subtitle: 'Server: 94.140.14.14', value: _adguardDns, onChanged: (v) { setState(() => _adguardDns = v); ss(() => _adguardDns = v); _toast(_adguardDns ? 'AdGuard DNS enabled' : 'AdGuard DNS disabled'); }),
            const SizedBox(height: 10),
            _SettingTile(icon: Icons.block_rounded, iconColor: C.orange, title: 'Block Popups', subtitle: 'Prevent websites from opening windows', value: _blockPopups, onChanged: (v) { setState(() => _blockPopups = v); ss(() => _blockPopups = v); }),
            const SizedBox(height: 20),
            _sectionLabel('🌐  Browsing'),
            const SizedBox(height: 10),
            _SettingTile(icon: Icons.desktop_windows_rounded, iconColor: C.accent, title: 'Desktop Mode', subtitle: 'Load full desktop version', value: _desktopMode, onChanged: (v) { setState(() => _desktopMode = v); ss(() => _desktopMode = v); _tab.controller?.setSettings(settings: InAppWebViewSettings(preferredContentMode: v ? UserPreferredContentMode.DESKTOP : UserPreferredContentMode.RECOMMENDED)); _tab.controller?.reload(); }),
          ],
        ),
      )),
    );
  }

  // ═══════════════════════════════════════════════
  //  BUILD & UI COMPONENTS
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: _incognito ? const Color(0xFF0A0A14) : C.bg,
        body: SafeArea(child: Column(children: [
          _buildTopBar(),
          if (!_tab.isHome && _tab.progress > 0 && _tab.progress < 1.0)
            SizedBox(height: 2, child: LinearProgressIndicator(value: _tab.progress, backgroundColor: C.border, valueColor: const AlwaysStoppedAnimation<Color>(C.accent))),
          if (_showFindBar) _buildFindBar(),
          Expanded(child: IndexedStack(index: _currentTabIndex, children: _tabs.map((t) => t.isHome ? _buildHomePage() : _buildWebView(t)).toList())),
          _buildBottomBar(),
        ])),
      ),
    );
  }

  Widget _buildTopBar() => Container(
    color: C.bg, padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
    child: Row(children: [
      Expanded(child: GestureDetector(
        onTap: () { _urlFocus.requestFocus(); _urlCtrl.selectAll(); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), height: 46,
          decoration: BoxDecoration(color: _isUrlFocused ? C.elevated : C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _isUrlFocused ? C.accent.withOpacity(0.6) : C.border, width: 1.5)),
          child: Row(children: [
            const SizedBox(width: 12),
            Icon(_tab.isHome ? Icons.search_rounded : Icons.lock_rounded, size: _tab.isHome ? 16 : 13, color: _tab.isHome ? C.t3 : C.green),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _urlCtrl, focusNode: _urlFocus, textInputAction: TextInputAction.go, onSubmitted: _loadUrl, style: const TextStyle(color: C.t1, fontSize: 14, fontWeight: FontWeight.w500), decoration: const InputDecoration(hintText: 'Search or enter URL…', hintStyle: TextStyle(color: C.t3, fontSize: 14), border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true))),
            if (!_tab.isHome) GestureDetector(onTap: () => _tab.controller?.reload(), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: _tab.isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: C.accent)) : const Icon(Icons.refresh_rounded, size: 18, color: C.t2))),
          ]),
        ),
      )),
      const SizedBox(width: 8),
      GestureDetector(onTap: _showTabsOverview, child: Container(width: 46, height: 46, decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)), child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(border: Border.all(color: C.t2, width: 1.5), borderRadius: BorderRadius.circular(5)), child: Text('${_tabs.length}', style: const TextStyle(color: C.t1, fontSize: 12, fontWeight: FontWeight.bold)))))),
      const SizedBox(width: 8),
      GestureDetector(onTap: _showMenu, child: Container(width: 46, height: 46, decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)), child: const Icon(Icons.more_vert_rounded, color: C.t2, size: 20))),
    ]),
  );

  Widget _buildBottomBar() => Container(
    color: C.bg, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _BottomBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: () async { if (_tab.controller != null && !_tab.isHome) { if (await _tab.controller!.canGoBack()) { await _tab.controller!.goBack(); } else { _goHome(); } } }),
      _BottomBtn(icon: Icons.arrow_forward_ios_rounded, onTap: () async { if (_tab.controller != null && await _tab.controller!.canGoForward()) await _tab.controller!.goForward(); }),
      _BottomBtn(icon: Icons.home_rounded, onTap: _goHome, active: _tab.isHome),
      _BottomBtn(icon: Icons.bookmark_border_rounded, onTap: _showBookmarks),
      _BottomBtn(icon: Icons.tab_rounded, onTap: _showTabsOverview, badge: '${_tabs.length}'),
    ]),
  );

  Widget _buildHomePage() => ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
    const SizedBox(height: 40),
    Center(child: Column(children: [
      Container(width: 68, height: 68, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7B61FF), Color(0xFF9D88FF)]), borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: C.accent.withOpacity(0.35), blurRadius: 28, spreadRadius: 4)]), child: const Icon(Icons.language_rounded, color: Colors.white, size: 36)),
      const SizedBox(height: 14),
      const Text('Orbit Browser', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: C.t1)),
      const SizedBox(height: 10),
      Row(mainAxisSize: MainAxisSize.min, children: [
        _MiniChip(label: 'Ad-free', color: C.green, active: _adBlockEnabled),
        const SizedBox(width: 8),
        _MiniChip(label: 'DNS Guard', color: C.accent, active: _adguardDns),
      ]),
    ])),
    const SizedBox(height: 36),
    GridView.count(crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: _bookmarks.take(8).map((b) => _QuickLink(emoji: b.emoji, label: b.title, url: b.url, onTap: _loadUrl)).toList()),
  ]);

  Widget _buildWebView(BrowserTab tab) => Stack(children: [
    InAppWebView(
      key: ValueKey(tab.id), initialUrlRequest: URLRequest(url: WebUri(tab.url)),
      initialSettings: InAppWebViewSettings(javaScriptEnabled: true, contentBlockers: _adBlockEnabled ? _adBlockers : [], incognito: _incognito),
      onWebViewCreated: (ctrl) => tab.controller = ctrl,
      onLoadStart: (ctrl, url) => setState(() { tab.url = url?.toString() ?? ''; tab.progress = 0.05; tab.isLoading = true; if (tab == _tab) _urlCtrl.text = tab.url; }),
      onLoadStop: (ctrl, url) async { final title = await ctrl.getTitle(); final u = url?.toString() ?? tab.url; setState(() { tab.url = u; tab.title = (title?.isNotEmpty == true) ? title! : 'Web Page'; tab.progress = 1.0; tab.isLoading = false; if (tab == _tab) _urlCtrl.text = tab.url; }); if (!_incognito && u.isNotEmpty) _history.add(HistoryItem(title: tab.title, url: u, visitedAt: DateTime.now())); },
      onProgressChanged: (ctrl, p) => setState(() => tab.progress = p / 100.0),
    ),
    if (tab.isLoading && tab.progress < 1.0) const Positioned.fill(child: Container(color: Colors.black45, child: OrbitLoadingIndicator())),
  ]);

  Widget _handle() => Container(alignment: Alignment.center, margin: const EdgeInsets.only(top: 12, bottom: 4), child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(2))));
  Widget _sectionLabel(String text) => Text(text, style: const TextStyle(color: C.t3, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5));
  Widget _buildFindBar() => Container(); // Simplified find bar
}

// ═══════════════════════════════════════════════
//  ADDITIONAL UI WIDGETS
// ═══════════════════════════════════════════════

class _QuickLink extends StatelessWidget {
  final String emoji, label, url;
  final Function(String) onTap;
  const _QuickLink({required this.emoji, required this.label, required this.url, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onTap(url),
    child: Column(children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border)), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26)))),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(color: C.t2, fontSize: 11), maxLines: 1),
    ]),
  );
}

class _BottomBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final String? badge;
  const _BottomBtn({required this.icon, required this.onTap, this.active = false, this.badge});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Stack(clipBehavior: Clip.none, children: [
      Container(width: 50, height: 50, decoration: BoxDecoration(color: active ? C.accent.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: active ? C.accent : C.t2, size: 24)),
      if (badge != null) Positioned(right: 0, top: 0, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: C.accent, shape: BoxShape.circle), child: Text(badge!, style: const TextStyle(fontSize: 10, color: Colors.white)))),
    ]),
  );
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingTile({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: iconColor),
    title: Text(title, style: const TextStyle(color: C.t1, fontSize: 14)),
    subtitle: Text(subtitle, style: const TextStyle(color: C.t3, fontSize: 12)),
    trailing: Switch(value: value, onChanged: onChanged),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.iconColor, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(leading: Icon(icon, color: iconColor), title: Text(label), onTap: onTap);
}

class _QuickToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _QuickToggle({required this.icon, required this.label, required this.active, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: active ? color.withOpacity(0.1) : C.elevated, borderRadius: BorderRadius.circular(12)), child: Column(children: [Icon(icon, color: active ? color : C.t2), Text(label, style: TextStyle(color: active ? color : C.t2, fontSize: 10))]))));
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  const _MiniChip({required this.label, required this.color, required this.active});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: active ? color.withOpacity(0.1) : C.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? color : C.border)), child: Text(label, style: TextStyle(color: active ? color : C.t3, fontSize: 10)));
}

class OrbitLoadingIndicator extends StatefulWidget {
  const OrbitLoadingIndicator({super.key});
  @override
  State<OrbitLoadingIndicator> createState() => _OrbitLoadingIndicatorState();
}
class _OrbitLoadingIndicatorState extends State<OrbitLoadingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Center(child: RotationTransition(turns: _ctrl, child: const Icon(Icons.language_rounded, color: C.accent, size: 40)));
}