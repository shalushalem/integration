// profile.dart
// Single source of truth for profile types, controller, screen, and all UI.
// Imported by: main.dart, home.dart, onboarding1.dart, onboarding2.dart, onboarding3.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:myapp/theme/theme_controller.dart';
import 'package:myapp/theme/profile_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME CONFIG
// ─────────────────────────────────────────────────────────────────────────────

enum AppTheme { coolBlue, sunsetPop, futureCandy }

class ThemeColors {
  final Color accent1;
  final Color accent2;
  final Color accent3;

  const ThemeColors({
    required this.accent1,
    required this.accent2,
    required this.accent3,
  });
}

final Map<AppTheme, ThemeColors> themeMap = {
  AppTheme.coolBlue: ThemeColors(
    accent1: Color(0xFF7C6DFA),
    accent2: Color(0xFFA480F5),
    accent3: Color(0xFFE067A4),
  ),
  AppTheme.sunsetPop: ThemeColors(
    accent1: Color(0xFFF4845F),
    accent2: Color(0xFFF5A623),
    accent3: Color(0xFFE0506A),
  ),
  AppTheme.futureCandy: ThemeColors(
    accent1: Color(0xFF43E1C0),
    accent2: Color(0xFF7C6DFA),
    accent3: Color(0xFFF06DB5),
  ),
};

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE STATE MODEL
// ─────────────────────────────────────────────────────────────────────────────

class ProfileState {
  String name;
  String username;
  String email;
  String phone;
  String dob;
  String gender;
  int skinTone;
  String bodyShape;
  Set<String> styles;
  Set<String> shopPrefs;
  bool isDark;
  AppTheme theme;
  String lang;
  String? avatarPath;

  ProfileState({
    this.name = 'New User',
    this.username = '@username',
    this.email = '',
    this.phone = '',
    this.dob = '',
    this.gender = 'Female',
    this.skinTone = 3,
    this.bodyShape = 'Rectangle',
    Set<String>? styles,
    Set<String>? shopPrefs,
    this.isDark = true,
    this.theme = AppTheme.coolBlue,
    this.lang = 'English',
    this.avatarPath,
  }) : styles = styles ?? {'Casual', 'Minimalist'},
       shopPrefs = shopPrefs ?? {};

  ProfileState copyWith({
    String? name,
    String? username,
    String? email,
    String? phone,
    String? dob,
    String? gender,
    int? skinTone,
    String? bodyShape,
    Set<String>? styles,
    Set<String>? shopPrefs,
    bool? isDark,
    AppTheme? theme,
    String? lang,
    String? avatarPath,
    bool clearAvatar = false,
  }) {
    return ProfileState(
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      skinTone: skinTone ?? this.skinTone,
      bodyShape: bodyShape ?? this.bodyShape,
      styles: styles ?? Set.from(this.styles),
      shopPrefs: shopPrefs ?? Set.from(this.shopPrefs),
      isDark: isDark ?? this.isDark,
      theme: theme ?? this.theme,
      lang: lang ?? this.lang,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const List<String> kLanguages = [
  'English', 'Hindi', 'Tamil', 'Telugu', 'Kannada',
  'Malayalam', 'Bengali', 'Marathi', 'French', 'Spanish',
  'German', 'Arabic', 'Japanese',
];

const List<Color> kSkinTones = [
  Color(0xFFFDDBB4), Color(0xFFF5C6A0), Color(0xFFE8A87C),
  Color(0xFFC68642), Color(0xFF8D5524), Color(0xFF4A2912),
  Color(0xFF2C1A0E), Color(0xFF1A0D07),
];

const List<Map<String, String>> kStyleCards = [
  {'label': 'Clean Minimal', 'img': 'assets/styles/clean_minimal.jpg'},
  {'label': 'Soft Elegant',  'img': 'assets/styles/soft_elegant.jpg'},
  {'label': 'Street Cool',   'img': 'assets/styles/street_cool.jpg'},
  {'label': 'Boho Artisanal','img': 'assets/styles/boho_artisinal.jpeg'},
  {'label': 'Party Glam',    'img': 'assets/styles/party_galm.jpg'},
  {'label': 'Formal Chic',   'img': 'assets/styles/formal_chic.jpg'},
];

const List<Map<String, String>> kShopPrefs = [
  {'label': 'Women',      'gender': 'women', 'img': 'assets/shop/women.jpg'},
  {'label': 'Men',        'gender': 'men',   'img': 'assets/shop/men.jpg'},
  {'label': 'Accessories','gender': 'both',  'img': 'assets/shop/accessories.jpg'},
  {'label': 'Ethnic',     'gender': 'both',  'img': 'assets/shop/ethnic.jpg'},
];

const Map<String, List<Map<String, String>>> kBodyShapes = {
  'women': [
    {'name': 'Hourglass', 'img': 'assets/body_shapes/women_hourglass.jpg'},
    {'name': 'Apple',     'img': 'assets/body_shapes/women_apple.jpg'},
    {'name': 'Traingle',  'img': 'assets/body_shapes/women_traingle.jpg'},
    {'name': 'Rectangle', 'img': 'assets/body_shapes/women_rectangle.jpg'},
    {'name': 'Inverted',  'img': 'assets/body_shapes/women_inverted.jpg'},
    {'name': 'Pear',      'img': 'assets/body_shapes/women_pear.jpg'},
  ],
  'men': [
    {'name': 'Traingle',  'img': 'assets/body_shapes/men_traingle.jpg'},
    {'name': 'Rectangle', 'img': 'assets/body_shapes/men_rectangle.jpg'},
    {'name': 'Oval',      'img': 'assets/body_shapes/men_oval.jpg'},
    {'name': 'Inverted',  'img': 'assets/body_shapes/men_inverted.jpg'},
    {'name': 'Trapezoid', 'img': 'assets/body_shapes/men_trapezoid.jpg'},
  ],
};

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE CONTROLLER  (ChangeNotifier — used via Provider in main.dart)
// ─────────────────────────────────────────────────────────────────────────────

class ProfileController extends ChangeNotifier {
  ProfileState _state = ProfileState();

  ProfileState get state => _state;

  /// Called by onboarding1.dart
  void updateBasics({
    String? name,
    String? username,
    String? email,
    String? phone,
    String? dob,
    String? gender,
    int? skinTone,
    String? bodyShape,
    Set<String>? shopPrefs,
    String? lang,
    String? avatarPath,
  }) {
    _state = _state.copyWith(
      name: name,
      username: username,
      email: email,
      phone: phone,
      dob: dob,
      gender: gender,
      skinTone: skinTone,
      bodyShape: bodyShape,
      shopPrefs: shopPrefs,
      lang: lang,
      avatarPath: avatarPath,
    );
    notifyListeners();
  }

  /// Called by onboarding2.dart
  void updateStyles(Set<String> styles) {
    _state = _state.copyWith(styles: styles);
    notifyListeners();
  }

  /// Called by onboarding3.dart
  void updatePersonalization({
    required bool enabled,
    required bool faceUploaded,
    required bool bodyUploaded,
  }) {
    // Personalization flags are stored locally in the onboarding screen;
    // notify listeners so any dependent widget can rebuild if needed.
    notifyListeners();
  }

  /// Full-state update used internally by ProfileScreen
  void updateState(ProfileState newState) {
    _state = newState;
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE SCREEN  (widget referenced by home.dart nav bar)
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final profileCtrl = context.watch<ProfileController>();
    final s = profileCtrl.state;
    final colors = themeMap[s.theme]!;
    return ProfilePage(
      state: s,
      colors: colors,
      onStateChange: (newState) {
        // dark mode లేదా accent theme మారినప్పుడు ThemeController కి sync చేయి
        _syncTheme(context, newState, s);
        profileCtrl.updateState(newState);
      },
    );
  }

  void _syncTheme(BuildContext context, ProfileState newState, ProfileState oldState) {
    try {
      final themeCtrl = Provider.of<ThemeController>(context, listen: false);

      // Dark/Light mode sync
      if (newState.isDark != oldState.isDark) {
        if (themeCtrl.isDarkMode != newState.isDark) {
          themeCtrl.toggleBrightness();
        }
      }

      // Accent theme sync — AppTheme → ProfileTheme convert చేసి set చేయి
      if (newState.theme != oldState.theme) {
        final profileTheme = ProfileTheme.values.firstWhere(
          (t) => t.name == newState.theme.name,
          orElse: () => ProfileTheme.coolBlue,
        );
        themeCtrl.setTheme(profileTheme);
      }
    } catch (_) {
      // ThemeController not available — ProfileState alone drives UI
    }
  }
}


class ProfilePage extends StatefulWidget {
  final ProfileState state;
  final ThemeColors colors;
  final ValueChanged<ProfileState> onStateChange;

  const ProfilePage({
    super.key,
    required this.state,
    required this.colors,
    required this.onStateChange,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  bool _showEdit = false;

  ProfileState get s => widget.state;
  ThemeColors get c => widget.colors;

  Color get _bg => s.isDark ? const Color(0xFF0D0E14) : const Color(0xFFF4F4F8);
  Color get _bg2 => s.isDark ? const Color(0xFF13141C) : const Color(0xFFECECF4);
  Color get _panel => s.isDark ? const Color(0xFF1A1C26) : const Color(0xFFE6E7F0);
  Color get _card => s.isDark ? const Color(0xFF181922) : Colors.white;
  Color get _cardBorder => s.isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07);
  Color get _textPrimary => s.isDark ? const Color(0xFFF0F0F8) : const Color(0xFF18192A);
  Color get _textMuted => s.isDark
      ? const Color(0xFFB4B6D2).withOpacity(0.65)
      : const Color(0xFF50526E).withOpacity(0.65);
  Color get _danger => s.isDark ? const Color(0xFFF06080) : const Color(0xFFD94060);

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        backgroundColor: _bg2,
        shape: const StadiumBorder(),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2200),
      ),
    );
  }

  void _update(ProfileState newState) => widget.onStateChange(newState);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: s.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bg,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showEdit
              ? _EditView(
                  key: const ValueKey('edit'),
                  state: s,
                  colors: c,
                  bg: _bg, bg2: _bg2, panel: _panel, card: _card,
                  cardBorder: _cardBorder,
                  textPrimary: _textPrimary, textMuted: _textMuted,
                  onSave: (newState) {
                    _update(newState);
                    setState(() => _showEdit = false);
                    _showToast('✓ Profile updated');
                  },
                  onDiscard: () => setState(() => _showEdit = false),
                  onToast: _showToast,
                )
              : _ProfileView(
                  key: const ValueKey('profile'),
                  state: s,
                  colors: c,
                  bg: _bg, bg2: _bg2, panel: _panel, card: _card,
                  cardBorder: _cardBorder,
                  textPrimary: _textPrimary, textMuted: _textMuted,
                  danger: _danger,
                  onEditTap: () => setState(() => _showEdit = true),
                  onStateChange: _update,
                  onToast: _showToast,
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileView extends StatelessWidget {
  final ProfileState state;
  final ThemeColors colors;
  final Color bg, bg2, panel, card, cardBorder, textPrimary, textMuted, danger;
  final VoidCallback onEditTap;
  final ValueChanged<ProfileState> onStateChange;
  final ValueChanged<String> onToast;

  const _ProfileView({
    super.key,
    required this.state,
    required this.colors,
    required this.bg, required this.bg2, required this.panel,
    required this.card, required this.cardBorder,
    required this.textPrimary, required this.textMuted, required this.danger,
    required this.onEditTap,
    required this.onStateChange,
    required this.onToast,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
            child: Row(
              children: [
                _HeaderBtn(icon: '‹', bg: panel, border: cardBorder, textMuted: textMuted,
                    onTap: () => Navigator.maybePop(context)),
                const Spacer(),
                Text.rich(TextSpan(
                  text: 'My ',
                  style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600,
                      letterSpacing: -0.5),
                  children: [
                    TextSpan(text: 'Profile',
                        style: TextStyle(color: colors.accent1, fontWeight: FontWeight.w300,
                            fontStyle: FontStyle.italic, fontSize: 17)),
                  ],
                )),
                const Spacer(),
                const SizedBox(width: 36),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        children: [
                          _AvatarWidget(state: state, colors: colors, bg: bg, bg2: bg2,
                              size: 92, onPickImage: null),
                          const SizedBox(height: 16),
                          Text(state.name,
                              style: TextStyle(color: textPrimary, fontSize: 24,
                                  fontWeight: FontWeight.w600, letterSpacing: -0.7)),
                          const SizedBox(height: 5),
                          Text(state.username,
                              style: TextStyle(color: textMuted, fontSize: 13, letterSpacing: 0.4)),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: onEditTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [colors.accent1, colors.accent2],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(color: colors.accent1.withOpacity(0.3),
                                      blurRadius: 28, offset: const Offset(0, 8)),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('✎', style: TextStyle(color: textPrimary, fontSize: 11)),
                                  const SizedBox(width: 8),
                                  Text('Edit Profile',
                                      style: TextStyle(color: textPrimary,
                                          fontSize: 13.5, fontWeight: FontWeight.w600,
                                          letterSpacing: 0.4)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Preferences Section
                  _SectionLabel(label: 'PREFERENCES', textMuted: textMuted),
                  _SectionGroup(children: [
                    _ListItem(
                      icon: '🌐', iconAccent: true, label: 'Language',
                      meta: state.lang, colors: colors, card: card,
                      cardBorder: cardBorder, textPrimary: textPrimary, textMuted: textMuted,
                      onTap: () => _showLanguageModal(context),
                    ),
                    _ListItem(
                      icon: '📍', iconAccent: true, label: 'Location',
                      meta: 'Mumbai, IN', colors: colors, card: card,
                      cardBorder: cardBorder, textPrimary: textPrimary, textMuted: textMuted,
                    ),
                  ]),

                  // Appearance Section
                  _SectionLabel(label: 'APPEARANCE', textMuted: textMuted),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MODE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                              color: textMuted, letterSpacing: 1.3)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              final goingLight = state.isDark;
                              onStateChange(state.copyWith(isDark: !state.isDark));
                              onToast(goingLight ? '☀️ Light mode on' : '🌙 Dark mode on');
                            },
                            child: Row(children: [
                              Text(state.isDark ? '🌙' : '☀️', style: const TextStyle(fontSize: 17)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(state.isDark ? 'Dark Mode' : 'Light Mode',
                                  style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
                              _ToggleSwitch(value: state.isDark, colors: colors),
                            ]),
                          ),
                          const SizedBox(height: 16),
                          Text('COLOUR THEME', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                              color: textMuted, letterSpacing: 1.3)),
                          const SizedBox(height: 8),
                          _ThemeRow(state: state, colors: colors, panel: panel,
                              textPrimary: textPrimary, textMuted: textMuted,
                              onSelect: (t) {
                                onStateChange(state.copyWith(theme: t));
                                final names = {AppTheme.coolBlue: 'Cool Blue',
                                    AppTheme.sunsetPop: 'Sunset Pop', AppTheme.futureCandy: 'Future Candy'};
                                onToast('✓ Theme set to ${names[t]}');
                              }),
                        ],
                      ),
                    ),
                  ),

                  // Account Section
                  _SectionLabel(label: 'ACCOUNT', textMuted: textMuted),
                  _SectionGroup(children: [
                    _ListItem(
                      icon: '🚪', iconDanger: true, label: 'Log Out',
                      labelDanger: true, colors: colors, card: card,
                      cardBorder: cardBorder, textPrimary: textPrimary, textMuted: textMuted,
                      danger: danger,
                      onTap: () => _showLogoutModal(context),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LanguageSheet(
        current: state.lang,
        bg2: bg2,
        cardBorder: cardBorder,
        textPrimary: textPrimary,
        textMuted: textMuted,
        accentColor: colors.accent1,
        onSelect: (lang) {
          Navigator.pop(context);
          onStateChange(state.copyWith(lang: lang));
          onToast('✓ Language set to $lang');
        },
      ),
    );
  }

  void _showLogoutModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ConfirmSheet(
        icon: '🚪',
        isDanger: true,
        title: 'Log Out?',
        body: "Are you sure you want to log out? You'll need to sign in again to access your profile.",
        confirmLabel: 'Log Out',
        cancelLabel: 'Cancel',
        bg2: bg2, cardBorder: cardBorder, textPrimary: textPrimary, textMuted: textMuted,
        panel: panel, danger: danger, accentColor: colors.accent1,
        onConfirm: () {
          Navigator.pop(context);
          onToast('👋 Logged out');
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _EditView extends StatefulWidget {
  final ProfileState state;
  final ThemeColors colors;
  final Color bg, bg2, panel, card, cardBorder, textPrimary, textMuted;
  final ValueChanged<ProfileState> onSave;
  final VoidCallback onDiscard;
  final ValueChanged<String> onToast;

  const _EditView({
    super.key,
    required this.state,
    required this.colors,
    required this.bg, required this.bg2, required this.panel,
    required this.card, required this.cardBorder,
    required this.textPrimary, required this.textMuted,
    required this.onSave, required this.onDiscard, required this.onToast,
  });

  @override
  State<_EditView> createState() => _EditViewState();
}

class _EditViewState extends State<_EditView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _dobCtrl;

  late ProfileState _draft;
  bool _isDirty = false;
  bool _faceUploaded = false;
  bool _bodyUploaded = false;
  bool _tryOnEnabled = false;
  String _bodyGender = 'women'; // tracks which gender tab is selected in Body Shape

  ThemeColors get c => widget.colors;
  Color get _bg => widget.bg;
  Color get _panel => widget.panel;
  Color get _card => widget.card;
  Color get _cardBorder => widget.cardBorder;
  Color get _textPrimary => widget.textPrimary;
  Color get _textMuted => widget.textMuted;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _faceUploaded = false;
    _bodyUploaded = false;
    _draft = widget.state.copyWith();
    _nameCtrl = TextEditingController(text: widget.state.name);
    _usernameCtrl = TextEditingController(text: widget.state.username.replaceAll('@', ''));
    _emailCtrl = TextEditingController(text: widget.state.email);
    _phoneCtrl = TextEditingController(text: widget.state.phone);
    _dobCtrl = TextEditingController(text: widget.state.dob);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  void _markDirty() => setState(() => _isDirty = true);

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        _draft = _draft.copyWith(avatarPath: img.path);
        _isDirty = true;
      });
      widget.onToast('✓ Photo updated');
    }
  }

  void _handleBack() {
    if (_isDirty) {
      _showDiscardModal();
    } else {
      widget.onDiscard();
    }
  }

  void _save() {
    final name = _nameCtrl.text.trim().isEmpty ? 'New User' : _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    widget.onSave(_draft.copyWith(
      name: name,
      username: username.isEmpty ? '' : '@${username.replaceAll('@', '')}',
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      dob: _dobCtrl.text.trim(),
    ));
  }

  void _showDiscardModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.bg2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ConfirmSheet(
        icon: '⚠️',
        isDanger: true,
        title: 'Discard Changes?',
        body: "You have unsaved changes. If you leave now, they'll be lost.",
        confirmLabel: 'Discard',
        cancelLabel: 'Keep Editing',
        bg2: widget.bg2, cardBorder: _cardBorder, textPrimary: _textPrimary,
        textMuted: _textMuted, panel: _panel,
        danger: const Color(0xFFF06080),
        accentColor: c.accent1,
        onConfirm: () { Navigator.pop(context); widget.onDiscard(); },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
            child: Row(
              children: [
                _HeaderBtn(icon: '‹', bg: _panel, border: _cardBorder, textMuted: _textMuted,
                    onTap: _handleBack),
                const Spacer(),
                Text.rich(TextSpan(
                  text: 'Edit ',
                  style: TextStyle(color: _textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
                  children: [
                    TextSpan(text: 'Profile',
                        style: TextStyle(color: c.accent1, fontWeight: FontWeight.w300,
                            fontStyle: FontStyle.italic, fontSize: 17)),
                  ],
                )),
                const Spacer(),
                const SizedBox(width: 36),
              ],
            ),
          ),

          // Avatar
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AvatarWidget(
                  state: _draft, colors: c, bg: _bg, bg2: widget.bg2,
                  size: 92, onPickImage: _pickAvatar),
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cardBorder),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.accent1, c.accent2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: c.accent1.withOpacity(0.38),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: _textMuted,
              labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, letterSpacing: 0.2),
              unselectedLabelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Basics', height: 42),
                Tab(text: 'Style', height: 42),
                Tab(text: 'Try On', height: 42),
              ],
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // BASICS TAB
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(text: 'Full Name', textMuted: _textMuted),
                      _FieldInput(ctrl: _nameCtrl, hint: 'Your name',
                          panel: _panel, cardBorder: _cardBorder,
                          textPrimary: _textPrimary, textMuted: _textMuted,
                          accentColor: c.accent1, onChanged: (_) => _markDirty()),

                      _FieldLabel(text: 'Username', textMuted: _textMuted),
                      _FieldInput(ctrl: _usernameCtrl, hint: '@username',
                          panel: _panel, cardBorder: _cardBorder,
                          textPrimary: _textPrimary, textMuted: _textMuted,
                          accentColor: c.accent1, onChanged: (_) => _markDirty()),

                      _FieldLabel(text: 'Email', textMuted: _textMuted),
                      _FieldInput(ctrl: _emailCtrl, hint: 'email@example.com',
                          keyboardType: TextInputType.emailAddress,
                          panel: _panel, cardBorder: _cardBorder,
                          textPrimary: _textPrimary, textMuted: _textMuted,
                          accentColor: c.accent1, onChanged: (_) => _markDirty()),

                      _FieldLabel(text: 'Phone', textMuted: _textMuted),
                      _FieldInput(ctrl: _phoneCtrl, hint: '+91 XXXXX XXXXX',
                          keyboardType: TextInputType.phone,
                          panel: _panel, cardBorder: _cardBorder,
                          textPrimary: _textPrimary, textMuted: _textMuted,
                          accentColor: c.accent1, onChanged: (_) => _markDirty()),

                      _FieldLabel(text: 'Date of Birth', textMuted: _textMuted),
                      _FieldInput(ctrl: _dobCtrl, hint: 'YYYY-MM-DD',
                          keyboardType: TextInputType.datetime,
                          panel: _panel, cardBorder: _cardBorder,
                          textPrimary: _textPrimary, textMuted: _textMuted,
                          accentColor: c.accent1, onChanged: (_) => _markDirty()),

                      _FieldLabel(text: 'Gender', textMuted: _textMuted),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: ['Female', 'Male', 'Non-binary', 'Other'].map((g) {
                          final val = g == 'Other' ? 'Prefer not to say' : g;
                          final active = _draft.gender == val;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _draft = _draft.copyWith(gender: val);
                              _markDirty();
                            }),
                            child: _Chip(
                              label: g, active: active,
                              panel: _panel, cardBorder: _cardBorder,
                              textMuted: _textMuted,
                              accentDim: c.accent1.withOpacity(0.12),
                              accentBorder: c.accent1.withOpacity(0.28),
                              accentColor: c.accent1,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      _FieldLabel(text: 'Skin Tone', textMuted: _textMuted),
                      Row(
                        children: List.generate(kSkinTones.length, (i) {
                          final active = _draft.skinTone == i + 1;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _draft = _draft.copyWith(skinTone: i + 1);
                              _markDirty();
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 10),
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: kSkinTones[i],
                                shape: BoxShape.circle,
                                border: active
                                    ? Border.all(color: c.accent1, width: 3)
                                    : Border.all(color: Colors.transparent, width: 3),
                              ),
                              transform: active
                                  ? (Matrix4.identity()..scale(1.15))
                                  : Matrix4.identity(),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 14),

                      _FieldLabel(text: 'Shop Preferences', textMuted: _textMuted),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10, mainAxisSpacing: 10,
                        children: kShopPrefs.map((pref) {
                          final label = pref['label']!;
                          final isActive = _draft.shopPrefs.contains(label);
                          return _PrefCard(
                            label: label,
                            imgUrl: pref['img']!,
                            active: isActive,
                            colors: c,
                            cardBorder: _cardBorder,
                            panel: _panel,
                            onTap: () => setState(() {
                              final updated = Set<String>.from(_draft.shopPrefs);
                              if (isActive) {
                                updated.remove(label);
                              } else {
                                updated.add(label);
                              }
                              _draft = _draft.copyWith(shopPrefs: updated);

                              // Auto-switch body shape gender based on shop pref selection
                              if (label == 'Women' && !isActive) {
                                _bodyGender = 'women';
                                _draft = _draft.copyWith(bodyShape: kBodyShapes['women']!.first['name']!);
                              } else if (label == 'Men' && !isActive) {
                                _bodyGender = 'men';
                                _draft = _draft.copyWith(bodyShape: kBodyShapes['men']!.first['name']!);
                              }

                              _markDirty();
                            }),
                          );
                        }).toList(),
                      ),
                      // Body Shape — animates in only when Women or Men is selected
                      _ProfileBodyShapeReveal(
                        visible: _draft.shopPrefs.contains('Women') || _draft.shopPrefs.contains('Men'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 14),
                            _FieldLabel(text: 'Body Shape', textMuted: _textMuted),
                            GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 10, mainAxisSpacing: 10,
                              childAspectRatio: 0.65,
                              children: kBodyShapes[_bodyGender]!.map((shape) {
                                final isActive = _draft.bodyShape == shape['name'];
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    _draft = _draft.copyWith(bodyShape: shape['name']!);
                                    _markDirty();
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isActive ? c.accent1 : _cardBorder,
                                        width: isActive ? 2 : 1,
                                      ),
                                      color: isActive ? c.accent1.withOpacity(0.1) : _panel,
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                                            child: Image.asset(
                                              shape['img']!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder: (_, _, _) => const Icon(Icons.person, size: 40),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          child: Text(
                                            shape['name']!,
                                            style: TextStyle(
                                              color: isActive ? c.accent1 : _textPrimary,
                                              fontSize: 11,
                                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // STYLE TAB
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Choose styles that match your vibe ✨',
                          style: TextStyle(color: _textMuted, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('Tap to select multiple',
                          style: TextStyle(color: _textMuted.withOpacity(0.7), fontSize: 10.5)),
                      const SizedBox(height: 14),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 3 / 4,
                        children: kStyleCards.map((sc) {
                          final active = _draft.styles.contains(sc['label']);
                          return _StyleImgCard(
                            label: sc['label']!,
                            imgUrl: sc['img']!,
                            active: active,
                            colors: c,
                            cardBorder: _cardBorder,
                            panel: _panel,
                            onTap: () => setState(() {
                              final newStyles = Set<String>.from(_draft.styles);
                              if (active) {
                                newStyles.remove(sc['label']);
                              } else {
                                newStyles.add(sc['label']!);
                              }
                              _draft = _draft.copyWith(styles: newStyles);
                              _markDirty();
                            }),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // TRY ON TAB
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      // Intro card
                      Container(
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _cardBorder),
                          boxShadow: [
                            BoxShadow(color: c.accent1.withOpacity(0.10), blurRadius: 20, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          children: [
                            // shimmer top strip
                            Container(
                              height: 1.5,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                gradient: LinearGradient(colors: [
                                  Colors.transparent,
                                  c.accent1.withOpacity(0.5),
                                  c.accent2.withOpacity(0.3),
                                  Colors.transparent,
                                ]),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [c.accent1.withOpacity(0.18), c.accent2.withOpacity(0.12)],
                                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(color: c.accent1.withOpacity(0.30)),
                                    ),
                                    child: Icon(Icons.person_outline, color: c.accent1, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Personalized Fit Preview',
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                                                color: _textPrimary, letterSpacing: -0.15)),
                                        const SizedBox(height: 5),
                                        Text('Upload photos to improve fit accuracy and how outfits look on your body type.',
                                            style: TextStyle(fontSize: 12.5, color: _textMuted,
                                                fontWeight: FontWeight.w400, height: 1.5)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _cardBorder),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Enable Virtual Try-On',
                                  style: TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Text('Turn on to upload photos for a personalised fit preview.',
                                  style: TextStyle(color: _textMuted, fontSize: 12, height: 1.4)),
                            ]),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => setState(() {
                              _tryOnEnabled = !_tryOnEnabled;
                              _markDirty();
                            }),
                            child: _ToggleSwitch(value: _tryOnEnabled, colors: c),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 14),

                      // Optional badge
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _panel,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: Text('Both uploads are optional',
                              style: TextStyle(fontSize: 11, color: _textMuted, letterSpacing: 0.3)),
                        ),
                      ]),
                      const SizedBox(height: 14),

                      // Face upload row
                      _TryOnUploadRow(
                        title: 'Add a face photo',
                        subtitle: 'Used only to enhance facial fit and styling.',
                        uploaded: _faceUploaded,
                        isFace: true,
                        colors: c,
                        card: _card,
                        cardBorder: _cardBorder,
                        panel: _panel,
                        textPrimary: _textPrimary,
                        textMuted: _textMuted,
                        onTap: () => setState(() {
                          _faceUploaded = !_faceUploaded;
                          _markDirty();
                        }),
                      ),
                      const SizedBox(height: 12),

                      // Body upload row
                      _TryOnUploadRow(
                        title: 'Add a full body photo',
                        subtitle: 'Improves outfit proportion accuracy.',
                        uploaded: _bodyUploaded,
                        isFace: false,
                        colors: c,
                        card: _card,
                        cardBorder: _cardBorder,
                        panel: _panel,
                        textPrimary: _textPrimary,
                        textMuted: _textMuted,
                        onTap: () => setState(() {
                          _bodyUploaded = !_bodyUploaded;
                          _markDirty();
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Privacy block
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: c.accent3.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.accent3.withOpacity(0.20)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: c.accent3.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.shield_outlined, color: c.accent3, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Your Privacy is Protected',
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                                          color: c.accent3, letterSpacing: 0.2)),
                                  const SizedBox(height: 4),
                                  Text('Photos are used solely for fit modeling and are deleted on request. AHVI does not sell or share personal data.',
                                      style: TextStyle(fontSize: 12, color: _textMuted,
                                          fontWeight: FontWeight.w300, height: 1.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Continue / Save Button
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              final tab = _tabController.index;
              final isLastTab = tab == 2;
              final label = tab == 0
                  ? 'Continue to Style  →'
                  : tab == 1
                      ? 'Continue to Try On  →'
                      : 'Save Changes';
              final canTap = isLastTab ? _isDirty : true;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GestureDetector(
                  onTap: canTap
                      ? () {
                          if (isLastTab) {
                            _save();
                          } else {
                            _tabController.animateTo(tab + 1);
                          }
                        }
                      : null,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: canTap ? 1.0 : 0.4,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [c.accent1, c.accent2],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: c.accent1.withOpacity(0.28),
                              blurRadius: 20,
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          label,
                          key: ValueKey(tab),
                          style: TextStyle(
                              color: _textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  final ProfileState state;
  final ThemeColors colors;
  final Color bg, bg2;
  final double size;
  final VoidCallback? onPickImage;

  const _AvatarWidget({
    required this.state, required this.colors, required this.bg, required this.bg2,
    required this.size, required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 16,
      height: size + 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow ring
          Container(
            width: size + 36,
            height: size + 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                colors.accent1.withOpacity(0.22),
                colors.accent2.withOpacity(0.09),
                Colors.transparent,
              ]),
            ),
          ),
          // Gradient ring
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [colors.accent2, colors.accent1, colors.accent3],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: colors.accent1.withOpacity(0.3),
                    blurRadius: 28, offset: const Offset(0, 8)),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [bg2, const Color(0xFF1A1C26)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                border: Border.all(color: Colors.white.withOpacity(0.10), width: 2.5),
              ),
              clipBehavior: Clip.hardEdge,
              child: state.avatarPath != null
                  ? Image.file(File(state.avatarPath!), fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        (state.name.isEmpty ? 'C' : state.name[0]).toUpperCase(),
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w300,
                            color: colors.accent1, letterSpacing: -0.5),
                      ),
                    ),
            ),
          ),
          // Camera badge
          if (onPickImage != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: onPickImage,
                child: Container(
                  width: 27, height: 27,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accent1,
                    border: Border.all(color: bg, width: 2.5),
                    boxShadow: [BoxShadow(color: colors.accent1.withOpacity(0.4), blurRadius: 12)],
                  ),
                  alignment: Alignment.center,
                  child: const Text('📷', style: TextStyle(fontSize: 10)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final String icon;
  final Color bg, border, textMuted;
  final VoidCallback? onTap;

  const _HeaderBtn({required this.icon, required this.bg, required this.border,
      required this.textMuted, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(11),
          border: Border.all(color: border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 8)],
        ),
        alignment: Alignment.center,
        child: Text(icon, style: TextStyle(fontSize: 18, color: textMuted)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color textMuted;
  const _SectionLabel({required this.label, required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
      child: Text(label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
              color: textMuted, letterSpacing: 1.3)),
    );
  }
}

class _SectionGroup extends StatelessWidget {
  final List<Widget> children;
  const _SectionGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: children.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: c,
        )).toList(),
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final String icon;
  final String label;
  final String? meta;
  final bool iconAccent;
  final bool iconDanger;
  final bool labelDanger;
  final ThemeColors colors;
  final Color card, cardBorder, textPrimary, textMuted;
  final Color? danger;
  final VoidCallback? onTap;

  const _ListItem({
    required this.icon, required this.label,
    this.meta, this.iconAccent = false, this.iconDanger = false,
    this.labelDanger = false, required this.colors,
    required this.card, required this.cardBorder,
    required this.textPrimary, required this.textMuted,
    this.danger, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconDanger
                  ? (danger ?? Colors.red).withOpacity(0.13)
                  : iconAccent ? colors.accent1.withOpacity(0.12) : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: iconDanger
                    ? (danger ?? Colors.red).withOpacity(0.38)
                    : iconAccent ? colors.accent1.withOpacity(0.28) : cardBorder,
              ),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: labelDanger ? textMuted.withOpacity(0.5) : textMuted,
                    fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0.1)),
          ),
          if (meta != null) ...[
            Text(meta!, style: TextStyle(color: textMuted, fontSize: 12.5, fontWeight: FontWeight.w300)),
            const SizedBox(width: 4),
          ],
          Text('›', style: TextStyle(color: textMuted, fontSize: 14)),
        ]),
      ),
    );
  }
}

class _ToggleSwitch extends StatelessWidget {
  final bool value;
  final ThemeColors colors;
  const _ToggleSwitch({required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 44, height: 25,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: value
            ? LinearGradient(colors: [colors.accent1, colors.accent2])
            : null,
        color: value ? null : const Color(0xFF22253A),
      ),
      child: Stack(children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          left: value ? 22 : 3,
          top: 3,
          child: Container(
            width: 19, height: 19,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6)],
            ),
          ),
        ),
      ]),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  final ProfileState state;
  final ThemeColors colors;
  final Color panel, textPrimary, textMuted;
  final ValueChanged<AppTheme> onSelect;

  const _ThemeRow({required this.state, required this.colors, required this.panel,
      required this.textPrimary, required this.textMuted, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final themes = [
      (AppTheme.coolBlue, 'Cool Blue',
       [const Color(0xFF7C6DFA), const Color(0xFFA480F5)]),
      (AppTheme.sunsetPop, 'Sunset Pop',
       [const Color(0xFFF4845F), const Color(0xFFE0506A)]),
      (AppTheme.futureCandy, 'Future Candy',
       [const Color(0xFF43E1C0), const Color(0xFF7C6DFA)]),
    ];

    return Row(
      children: themes.map((t) {
        final active = state.theme == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: active ? panel : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: active
                    ? [BoxShadow(color: Colors.black.withOpacity(0.20), blurRadius: 8)]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 13, height: 13,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: t.$3,
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(t.$2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: active ? textPrimary : textMuted,
                            fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final Color textMuted;
  const _FieldLabel({required this.text, required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(),
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
              color: textMuted, letterSpacing: 1.3)),
    );
  }
}

class _FieldInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType? keyboardType;
  final Color panel, cardBorder, textPrimary, textMuted, accentColor;
  final ValueChanged<String>? onChanged;

  const _FieldInput({
    required this.ctrl, required this.hint, this.keyboardType,
    required this.panel, required this.cardBorder,
    required this.textPrimary, required this.textMuted, required this.accentColor,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w300),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: textMuted, fontWeight: FontWeight.w300),
          filled: true,
          fillColor: panel,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: cardBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: cardBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: accentColor.withOpacity(0.28))),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final Color panel, cardBorder, textMuted, accentDim, accentBorder, accentColor;

  const _Chip({
    required this.label, required this.active,
    required this.panel, required this.cardBorder, required this.textMuted,
    required this.accentDim, required this.accentBorder, required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: active ? accentDim : panel,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: active ? accentBorder : cardBorder),
      ),
      child: Text(label,
          style: TextStyle(
              color: active ? accentColor : textMuted,
              fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}

class _PrefCard extends StatelessWidget {
  final String label, imgUrl;
  final bool active;
  final ThemeColors colors;
  final Color cardBorder, panel;
  final VoidCallback onTap;

  const _PrefCard({
    required this.label, required this.imgUrl, required this.active,
    required this.colors, required this.cardBorder, required this.panel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active ? colors.accent1 : cardBorder,
              width: active ? 2 : 2),
          boxShadow: active
              ? [BoxShadow(color: colors.accent1.withOpacity(0.28), blurRadius: 8)]
              : [],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(active ? 0.08 : 0.20), BlendMode.darken),
              child: Image.asset(imgUrl, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: panel, child: const Icon(Icons.image, color: Colors.white30))),
            ),
            if (active)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [colors.accent1, colors.accent2],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  alignment: Alignment.center,
                  child: const Text('✓', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ),
            Positioned(
              bottom: 8, left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.52),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Text(label, style: const TextStyle(color: Colors.white,
                    fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleImgCard extends StatelessWidget {
  final String label, imgUrl;
  final bool active;
  final ThemeColors colors;
  final Color cardBorder, panel;
  final VoidCallback onTap;

  const _StyleImgCard({
    required this.label, required this.imgUrl, required this.active,
    required this.colors, required this.cardBorder, required this.panel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: active ? colors.accent1 : cardBorder, width: 2),
          boxShadow: active
              ? [BoxShadow(color: colors.accent1.withOpacity(0.30), blurRadius: 8)]
              : [],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(active ? 0.08 : 0.22), BlendMode.darken),
              child: Image.asset(imgUrl, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: panel, child: const Icon(Icons.image, color: Colors.white30))),
            ),
            if (active)
              Positioned(
                top: 9, right: 9,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [colors.accent1, colors.accent2],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  alignment: Alignment.center,
                  child: const Text('✓', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ),
            Positioned(
              bottom: 10, left: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                alignment: Alignment.center,
                child: Text(label, style: const TextStyle(color: Colors.white,
                    fontSize: 11.5, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRY ON UPLOAD ROW
// ─────────────────────────────────────────────────────────────────────────────

class _TryOnUploadRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool uploaded;
  final bool isFace;
  final ThemeColors colors;
  final Color card, cardBorder, panel, textPrimary, textMuted;
  final VoidCallback onTap;

  const _TryOnUploadRow({
    required this.title,
    required this.subtitle,
    required this.uploaded,
    required this.isFace,
    required this.colors,
    required this.card,
    required this.cardBorder,
    required this.panel,
    required this.textPrimary,
    required this.textMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = uploaded ? colors.accent1.withOpacity(0.40) : cardBorder;
    final bgColor = uploaded ? colors.accent1.withOpacity(0.07) : card;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: uploaded
              ? [BoxShadow(color: colors.accent1.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: uploaded ? colors.accent1.withOpacity(0.15) : panel,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                    color: uploaded ? colors.accent1.withOpacity(0.35) : cardBorder),
              ),
              child: Icon(
                isFace ? Icons.person_outline : Icons.accessibility_new_outlined,
                color: uploaded ? colors.accent1 : textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                          color: textPrimary, letterSpacing: -0.1)),
                  const SizedBox(height: 3),
                  if (!uploaded)
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: textMuted,
                            fontWeight: FontWeight.w400, height: 1.4)),
                  if (uploaded)
                    Row(children: [
                      Icon(Icons.check, color: colors.accent2, size: 12),
                      const SizedBox(width: 5),
                      Text('Photo added · encrypted',
                          style: TextStyle(fontSize: 11, color: colors.accent2,
                              fontWeight: FontWeight.w500, letterSpacing: 0.2)),
                    ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: uploaded ? colors.accent1.withOpacity(0.18) : panel,
                shape: BoxShape.circle,
                border: Border.all(
                    color: uploaded ? colors.accent1.withOpacity(0.35) : cardBorder),
              ),
              child: Icon(
                uploaded ? Icons.check : Icons.chevron_right,
                color: uploaded ? colors.accent1 : textMuted,
                size: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEETS
// ─────────────────────────────────────────────────────────────────────────────

// ── Animated reveal widget for Body Shape section in Profile edit ──
class _ProfileBodyShapeReveal extends StatefulWidget {
  final bool visible;
  final Widget child;

  const _ProfileBodyShapeReveal({
    required this.visible,
    required this.child,
  });

  @override
  State<_ProfileBodyShapeReveal> createState() => _ProfileBodyShapeRevealState();
}

class _ProfileBodyShapeRevealState extends State<_ProfileBodyShapeReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    // Fade: eases in smoothly
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    // Slide: comes from slightly below (positive y = down)
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
    ));

    // Subtle scale: grows from 0.95 → 1.0
    _scale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    if (widget.visible) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_ProfileBodyShapeReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _ctrl.forward(from: 0.0);
    } else if (!widget.visible && oldWidget.visible) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeInOutCubic,
          child: _ctrl.isDismissed
              ? const SizedBox.shrink()
              : FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: ScaleTransition(
                      scale: _scale,
                      alignment: Alignment.topCenter,
                      child: widget.child,
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  final String current;
  final Color bg2, cardBorder, textPrimary, textMuted, accentColor;
  final ValueChanged<String> onSelect;

  const _LanguageSheet({
    required this.current, required this.bg2, required this.cardBorder,
    required this.textPrimary, required this.textMuted, required this.accentColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 36, height: 4, margin: const EdgeInsets.only(top: 13, bottom: 16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(100)),
          )),
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: accentColor.withOpacity(0.28)),
            ),
            alignment: Alignment.center,
            child: const Text('🌐', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 14),
          Text('Select Language',
              style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...kLanguages.map((l) => GestureDetector(
            onTap: () => onSelect(l),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: cardBorder)),
              ),
              child: Row(children: [
                SizedBox(width: 20,
                    child: Text(l == current ? '✓' : '',
                        style: TextStyle(color: accentColor, fontSize: 15))),
                const SizedBox(width: 14),
                Text(l, style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w400)),
              ]),
            ),
          )),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              alignment: Alignment.center,
              child: Text('Cancel', style: TextStyle(color: textMuted, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  final String icon, title, body, confirmLabel, cancelLabel;
  final bool isDanger;
  final Color bg2, cardBorder, textPrimary, textMuted, panel, danger, accentColor;
  final VoidCallback onConfirm, onCancel;

  const _ConfirmSheet({
    required this.icon, required this.title, required this.body,
    required this.confirmLabel, required this.cancelLabel, required this.isDanger,
    required this.bg2, required this.cardBorder, required this.textPrimary,
    required this.textMuted, required this.panel, required this.danger,
    required this.accentColor,
    required this.onConfirm, required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 36, height: 4, margin: const EdgeInsets.only(top: 13, bottom: 16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(100)),
          )),
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: isDanger ? danger.withOpacity(0.13) : accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                  color: isDanger ? danger.withOpacity(0.38) : accentColor.withOpacity(0.28)),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(color: textMuted, fontSize: 13.5, height: 1.5)),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: onConfirm,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: isDanger ? danger : null,
                gradient: isDanger ? null : LinearGradient(
                    colors: [accentColor, accentColor.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: (isDanger ? danger : accentColor).withOpacity(0.28),
                      blurRadius: 20, offset: const Offset(0, 6)),
                ],
              ),
              alignment: Alignment.center,
              child: Text(confirmLabel,
                  style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onCancel,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              alignment: Alignment.center,
              child: Text(cancelLabel, style: TextStyle(color: textMuted, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}