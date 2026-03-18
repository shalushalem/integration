// ============================================================================
// FIXES APPLIED
//
// FIX-1  RENDER CRASH — "blurRadius >= 0.0"
//        Clamped all animated opacity / blur values with .clamp(0.0, 1.0)
//        and max(0.0, ...) so they are always non-negative.
//
// FIX-2  PROFILE CHANGES NOT PERSISTING
//        TextEditingControllers stored as late fields, initialised once in
//        initState. Committed to _profile on save via _commitFieldsToProfile.
//
// FIX-2A CONFIRM BUTTON TIMER RACE
//        Logout modal closes the overlay immediately on tap; the toast is
//        shown from onConfirmed callback. No competing timers.
//
// FIX-2C AVATAR NOT REVERTED ON DISCARD
//        _savedAvatarPath / _savedAvatarBytes track last committed avatar.
//        Discard restores both.
//
// FIX-2D GENDER NOT REVERTED ON DISCARD
//        Introduced _editingGender for in-progress edits; only committed to
//        _profile.gender inside _commitFieldsToProfile(). Discard restores
//        _editingGender from _profile.gender.
//
// FIX-2F TOAST STALE OVERLAY ENTRY
//        onDismiss guarded so it is only invoked when entry is still active.
//
// FIX-3  WEB-SAFE IMAGE PICKER
//        Removed dart:io (crashes Flutter Web at compile time).
//        Uses XFile.readAsBytes() → Uint8List → Image.memory() on every
//        platform (Web, Android, iOS, desktop) — no kIsWeb branch needed.
//        _isDirty set to true when a photo is picked.
//        _avatarBytes reverted to _savedAvatarBytes on discard.
//
// FIX-4  REMOVE MOCK STATUS BAR
//        _buildStatusBar() removed entirely.
//
// FIX-4B TWEEN ANIMATION BUILDER MODAL RESET
//        Modal entrance animation moved to _AnimatedModal StatefulWidget
//        backed by a proper AnimationController so it does not reset on
//        every parent setState.
//
// FIX-4D GESTUREDETECTOR HIT-TEST BEHAVIOUR
//        Outer overlay GestureDetector uses HitTestBehavior.opaque.
//
// pubspec.yaml — add:
//   dependencies:
//     image_picker: ^1.1.2
//
// iOS Info.plist — add:
//   <key>NSPhotoLibraryUsageDescription</key>
//   <string>Used to update your profile picture.</string>
//
// Android (minSdk < 33) AndroidManifest.xml — add:
//   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
//       android:maxSdkVersion="32"/>
// ============================================================================

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:myapp/theme/accent_palette.dart';
import 'package:myapp/theme/gradients.dart';
import 'package:myapp/theme/profile_theme.dart';
import 'package:myapp/theme/theme_controller.dart';
import 'package:myapp/theme/theme_tokens.dart';

// --- NEW: Added AppwriteService Import ---
import 'package:myapp/services/appwrite_service.dart'; 

class ProfileController extends ChangeNotifier {
  String name;
  String email;
  String phone;
  String gender;
  String dob;
  Set<String> stylePreferences;
  bool personalizationEnabled;
  bool faceUploaded;
  bool bodyUploaded;
  Uint8List? avatarBytes;

  ProfileController({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.gender = '',
    this.dob = '',
    Set<String>? stylePreferences,
    this.personalizationEnabled = false,
    this.faceUploaded = false,
    this.bodyUploaded = false,
    this.avatarBytes,
  }) : stylePreferences = stylePreferences ?? <String>{};

  void updateBasics({
    required String name,
    required String phone,
    required String gender,
    required String dob,
  }) {
    this.name = name;
    this.phone = phone;
    this.gender = gender;
    this.dob = dob;
    notifyListeners();
  }

  void updateStyles(Set<String> styles) {
    stylePreferences = Set<String>.from(styles);
    notifyListeners();
  }

  void updatePersonalization({
    required bool enabled,
    required bool faceUploaded,
    required bool bodyUploaded,
  }) {
    personalizationEnabled = enabled;
    this.faceUploaded = faceUploaded;
    this.bodyUploaded = bodyUploaded;
    notifyListeners();
  }

  void setAvatarBytes(Uint8List? bytes) {
    avatarBytes = bytes;
    notifyListeners();
  }
}



// ── Palette now sourced from theme tokens ─────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// _FadeSlide — Staggered fadeUp entrance widget
// ─────────────────────────────────────────────────────────────────────────────
class _FadeSlide extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _FadeSlide({
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<_FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<_FadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _opacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Toast system
// FIX-2F: onDismiss is guarded; stale entry.remove() calls are prevented.
// ─────────────────────────────────────────────────────────────────────────────
OverlayEntry? _activeToast;

void _showToast(BuildContext context, String message) {
  _activeToast?.remove();
  _activeToast = null;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ToastWidget(
      message: message,
      onDismiss: () {
        // FIX-2F: only remove if this entry is still the active one
        if (_activeToast == entry) {
          entry.remove();
          _activeToast = null;
        }
      },
    ),
  );
  _activeToast = entry;
  Overlay.of(context).insert(entry);
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ToastWidget({required this.message, required this.onDismiss});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  AppThemeTokens get _t => context.themeTokens;
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _opacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.fastOutSlowIn));
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.fastOutSlowIn));

    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        _ctrl.reverse().then((_) {
          // FIX-2F: mounted check before invoking dismiss
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned(
    bottom: 80,
    left: 0,
    right: 0,
    child: Center(
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: _t.backgroundSecondary,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: _t.cardBorder),
              boxShadow: [
                BoxShadow(
                    color: _t.backgroundPrimary.withValues(alpha: 0.45),
                    blurRadius: 32,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: Text(widget.message,
                style: TextStyle(
                    color: _t.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile state model — single source of truth for persisted fields
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileData {
  String name;
  String username;
  String email;
  String phone;
  String dob;
  String gender;

  _ProfileData({
    this.name = 'Charlotte King',
    this.username = '@johnkinggraphics',
    this.email = 'charlotte@johnkinggraphics.com',
    this.phone = '6895312',
    this.dob = '',
    this.gender = 'Female',
  });

  _ProfileData copyWith({
    String? name,
    String? username,
    String? email,
    String? phone,
    String? dob,
    String? gender,
  }) =>
      _ProfileData(
        name: name ?? this.name,
        username: username ?? this.username,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        dob: dob ?? this.dob,
        gender: gender ?? this.gender,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// FIX-4B: _AnimatedModal — proper StatefulWidget modal wrapper so the
// entrance animation is backed by a real AnimationController and does NOT
// restart on every parent setState.
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedModal extends StatefulWidget {
  final Widget child;
  const _AnimatedModal({required this.child});

  @override
  State<_AnimatedModal> createState() => _AnimatedModalState();
}

class _AnimatedModalState extends State<_AnimatedModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _opacity =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _ctrl,
          curve: Curves.easeOut,
        ));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen4
// ─────────────────────────────────────────────────────────────────────────────
class Screen4 extends StatefulWidget {
  const Screen4({super.key});

  @override
  State<Screen4> createState() => _Screen4State();
}

class _Screen4State extends State<Screen4> with TickerProviderStateMixin {
  AppThemeTokens get _t => context.themeTokens;
  Color get _bg => _t.backgroundPrimary;
  Color get _bg2 => _t.backgroundSecondary;
  Color get _panel => _t.panel;
  Color get _panel2 => _t.panelBorder;
  Color get _card => _t.card;
  Color get _cardBorder => _t.cardBorder;
  Color get _danger => _t.accent.tertiary;
  Color get _dangerDim => _t.accent.tertiary.withValues(alpha: 0.15);
  Color get _dangerBorder => _t.accent.tertiary.withValues(alpha: 0.45);
  Color get _textSub => _t.mutedText.withValues(alpha: 0.9);
  Color get _textBody => _t.mutedText;
  Color get _accentPrimary => _t.accent.primary;
  Color get _accentSecondary => _t.accent.secondary;
  Color get _accentTertiary => _t.accent.tertiary;
  Color get _accentDim => _accentPrimary.withValues(alpha: 0.12);
  Color get _accentBorder => _accentPrimary.withValues(alpha: 0.28);
  Color get _textPrimary => _t.textPrimary;
  Color get _textMuted => _t.mutedText;
  
  // ── View / modal visibility ──
  bool _showEditView = false;
  bool _showLogoutModal = false;
  bool _showLanguageModal = false;
  bool _showDiscardModal = false;

  // --- NEW: Loading state for database fetch ---
  bool _isLoadingProfile = true;

  // ── Preferences ──
  String _selectedLanguage = 'English';

  // ── Edit form ──
  String _selectedEditTab = 'basics';
  bool _isDirty = false;
  bool _isSaving = false;
  final Set<String> _selectedStyles = {'Casual', 'Minimalist'};

  // FIX-2: Persisted profile data — single source of truth.
  _ProfileData _profile = _ProfileData();

  // FIX-2D: In-progress gender value; only written to _profile on save.
  late String _editingGender;

  // FIX-2: TextEditingControllers live here, initialised once in initState.
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _dobCtrl;
  final ScrollController _editScrollCtrl = ScrollController();

  // FIX-3: Avatar state — stored as raw bytes so Image.memory() works on
  // every platform (Web, Android, iOS, desktop) without dart:io.
  Uint8List? _avatarBytes;        // current session (may be unsaved)
  Uint8List? _savedAvatarBytes;   // last committed — restored on discard
  final _imagePicker = ImagePicker();

  // ── Animation controllers ──
  late final AnimationController _breatheCtrl;
  late final Animation<double> _breatheAnim;
  late final AnimationController _ambTLCtrl;
  late final AnimationController _ambBLCtrl;
  late final Animation<double> _ambTL;
  late final Animation<double> _ambBL;
  bool _isThemeTransitioning = false;

  bool get _canSave => _isDirty;

  @override
  void initState() {
    super.initState();

    final sharedProfile = context.read<ProfileController>();
    _profile = _profile.copyWith(
      name: sharedProfile.name.isNotEmpty ? sharedProfile.name : _profile.name,
      phone: sharedProfile.phone.isNotEmpty ? sharedProfile.phone : _profile.phone,
      dob: sharedProfile.dob.isNotEmpty ? sharedProfile.dob : _profile.dob,
      gender: sharedProfile.gender.isNotEmpty ? sharedProfile.gender : _profile.gender,
    );

    // FIX-2: Initialise controllers once from _profile.
    _nameCtrl = TextEditingController(text: _profile.name);
    _usernameCtrl = TextEditingController(text: _profile.username);
    _emailCtrl = TextEditingController(text: _profile.email);
    _phoneCtrl = TextEditingController(text: _profile.phone);
    _dobCtrl = TextEditingController(text: _profile.dob);

    // FIX-2D: Initialise editing gender from profile.
    _editingGender = _profile.gender;

    // Sync avatar from shared profile state.
    _avatarBytes = sharedProfile.avatarBytes;
    _savedAvatarBytes = _avatarBytes;

    // Breathe / glow
    _breatheCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4500));
    _breatheAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut));

    // Ambient corners — all started immediately (FIX-2E: stagger via delays
    // but begin animating from frame 1 via forward() before repeat).
    _ambTLCtrl =
    AnimationController(vsync: this, duration: const Duration(seconds: 6));
    _ambTL = Tween<double>(begin: 0.18, end: 0.30)
        .animate(CurvedAnimation(parent: _ambTLCtrl, curve: Curves.easeInOut));

    _ambBLCtrl =
    AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..forward();
    _ambBL = Tween<double>(begin: 0.18, end: 0.30)
        .animate(CurvedAnimation(parent: _ambBLCtrl, curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _breatheCtrl.repeat(reverse: true);
      _ambTLCtrl.repeat(reverse: true);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _ambBLCtrl.repeat(reverse: true);
      });
    });

    // --- NEW: Trigger real database fetch ---
    _fetchUserProfile();
  }

  // --- NEW: Fetch Database Method ---
  Future<void> _fetchUserProfile() async {
    try {
      final appwrite = Provider.of<AppwriteService>(context, listen: false);
      final user = await appwrite.getCurrentUser();

      if (user != null && mounted) {
        setState(() {
          // Update profile object with real Appwrite data
          _profile = _profile.copyWith(
            name: user.name.isNotEmpty ? user.name : _profile.name,
            email: user.email.isNotEmpty ? user.email : _profile.email,
            phone: user.phone.isNotEmpty ? user.phone : _profile.phone,
          );

          // Update text controllers
          _nameCtrl.text = _profile.name;
          _emailCtrl.text = _profile.email;
          _phoneCtrl.text = _profile.phone;

          _isLoadingProfile = false;
        });

        // Fetch custom generated avatar
        if (_avatarBytes == null) {
          final avatar = await appwrite.getUserAvatar(_profile.name);
          if (avatar != null && mounted) {
            setState(() {
              _avatarBytes = avatar;
              _savedAvatarBytes = avatar;
            });
            context.read<ProfileController>().setAvatarBytes(avatar);
          }
        }
      } else {
        if (mounted) setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      print("Error fetching profile: $e");
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _editScrollCtrl.dispose();
    _breatheCtrl.dispose();
    _ambTLCtrl.dispose();
    _ambBLCtrl.dispose();
    super.dispose();
  }

  // ── FIX-3: Web-safe image picker ────────────────────────────────────────
  // Uses XFile.readAsBytes() on every platform — no dart:io, no kIsWeb branch.
  // Image.memory() renders the bytes on both Web and mobile.
  // ImageSource.camera is excluded: not supported on Flutter Web.
  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _avatarBytes = bytes;
        _isDirty     = true;
      });
      context.read<ProfileController>().setAvatarBytes(_avatarBytes);
      _showToast(context, '✓ Photo updated');
    } catch (_) {
      if (mounted) _showToast(context, '⚠ Could not access photos');
    }
  }

  // ── FIX-2: Sync controllers + editing state back to _profile on save ─────
  void _commitFieldsToProfile() {
    _profile = _profile.copyWith(
      name: _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      dob: _dobCtrl.text.trim(),
      gender: _editingGender, // FIX-2D: commit editing gender
    );
    // FIX-3: commit avatar bytes (same field on all platforms)
    _savedAvatarBytes = _avatarBytes;
    context.read<ProfileController>().updateBasics(
      name: _profile.name,
      phone: _profile.phone,
      gender: _profile.gender,
      dob: _profile.dob,
    );
  }

  // --- UPDATED: Save back to Database if changed ---
  void _saveProfile() async {
    if (!_canSave || _isSaving) return;
    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);
    
    try {
      final appwrite = Provider.of<AppwriteService>(context, listen: false);
      // Attempt to update name in Appwrite if it was modified
      if (_nameCtrl.text.trim() != _profile.name) {
         await appwrite.account.updateName(name: _nameCtrl.text.trim());
      }
    } catch (e) {
      print("Error saving to Appwrite: $e");
    }

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      _commitFieldsToProfile();
      setState(() {
        _isSaving = false;
        _isDirty = false;
        _showEditView = false;
      });
      _showToast(context, '✓ Profile updated');
    }
  }

  // ── Open edit view — sync controllers from current profile ───────────────
  void _openEditView() {
    HapticFeedback.lightImpact();
    _nameCtrl.text = _profile.name;
    _usernameCtrl.text = _profile.username;
    _emailCtrl.text = _profile.email;
    _phoneCtrl.text = _profile.phone;
    _dobCtrl.text = _profile.dob;
    setState(() {
      _editingGender = _profile.gender; // FIX-2D
      _avatarBytes   = _savedAvatarBytes; // FIX-3: restore last saved avatar
      context.read<ProfileController>().setAvatarBytes(_avatarBytes);
      _isDirty = false;
      _selectedEditTab = 'basics';
      _showEditView = true;
    });
  }

  Future<void> _finishThemeTransition() async {
    await Future.delayed(const Duration(milliseconds: 320));
    if (mounted) {
      setState(() => _isThemeTransitioning = false);
    }
  }

  Future<void> _toggleBrightness() async {
    if (_isThemeTransitioning) return;
    final controller = context.read<ThemeController>();
    setState(() => _isThemeTransitioning = true);
    await controller.toggleBrightness();
    if (!mounted) return;
    _showToast(
      context,
      controller.isDarkMode ? '🌙 Dark mode on' : '☀️ Light mode on',
    );
    await _finishThemeTransition();
  }

  Future<void> _setTheme(ProfileTheme theme, String name) async {
    final controller = context.read<ThemeController>();
    if (_isThemeTransitioning || controller.currentTheme == theme) return;
    setState(() => _isThemeTransitioning = true);
    await controller.setTheme(theme);
    if (!mounted) return;
    _showToast(context, '✓ Theme set to $name');
    await _finishThemeTransition();
  }

  void _handleBackNavigation() {
    if (_showLogoutModal) {
      setState(() => _showLogoutModal = false);
      return;
    }
    if (_showLanguageModal) {
      setState(() => _showLanguageModal = false);
      return;
    }
    if (_showDiscardModal) {
      setState(() => _showDiscardModal = false);
      return;
    }
    if (_showEditView) {
      if (_isDirty) {
        setState(() => _showDiscardModal = true);
      } else {
        setState(() => _showEditView = false);
      }
      return;
    }
    Navigator.of(context).maybePop();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final accent = getAccentPalette(controller.currentTheme);
    final isDark = controller.isDarkMode;
    return PopScope(
      canPop: !_showEditView &&
          !_showLogoutModal &&
          !_showLanguageModal &&
          !_showDiscardModal,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: mainBackground(accent, isDark: isDark),
              ),
            ),
            RepaintBoundary(
              child: TickerMode(
                enabled: !_isThemeTransitioning && !_showEditView,
                child: _buildAmbientGlows(accent),
              ),
            ),
            TickerMode(
              enabled: !_isThemeTransitioning,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _isLoadingProfile 
                    ? Center(child: CircularProgressIndicator(color: _accentPrimary))
                    : (_showEditView ? _buildEditView() : _buildProfileView()),
              ),
            ),
            // FIX-4B: modals wrapped in _AnimatedModal (proper AnimationController)
            if (_showLogoutModal)
              _AnimatedModal(child: _buildLogoutModal()),
            if (_showLanguageModal)
              _AnimatedModal(child: _buildLanguageModal()),
            if (_showDiscardModal)
              _AnimatedModal(child: _buildDiscardModal()),
          ],
        ),
      ),
    );
  }

  // ── Ambient corner glows ──────────────────────────────────────────────────
  Widget _buildAmbientGlows(AccentPalette accent) {
    return AnimatedBuilder(
      animation: Listenable.merge([_ambTL, _ambBL]),
      builder: (_, _) => Stack(
        children: [
          _ambientGradientCircle(
            top: -40,
            left: -40,
            size: 240,
            gradient: glowPrimary(accent),
            opacity: _ambTL.value,
          ),
          _ambientGradientCircle(
            bottom: 40,
            right: -40,
            size: 240,
            gradient: glowSecondary(accent),
            opacity: _ambBL.value * 0.75,
          ),
        ],
      ),
    );
  }

  Widget _ambientGradientCircle({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required RadialGradient gradient,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              gradient.colors.first.withValues(alpha: opacity.clamp(0.0, 1.0)),
              _bg.withValues(alpha: 0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PROFILE VIEW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProfileView() {
    return Column(
      key: const ValueKey('profile'),
      children: [
        _FadeSlide(
          child: _buildTopBar(
            title: _buildHeaderTitle('My ', 'Profile'),
            leading: _buildHeaderBtn(
                icon: Icons.chevron_left_rounded,
                onTap: _handleBackNavigation),
            trailing: const SizedBox(width: 36),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FadeSlide(
                  delay: const Duration(milliseconds: 60),
                  child: RepaintBoundary(
                    child: TickerMode(
                      enabled: !_isThemeTransitioning,
                      child: _buildProfileHero(),
                    ),
                  ),
                ),
                _FadeSlide(
                  delay: const Duration(milliseconds: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionLabel('Preferences', topPad: 14),
                      _buildPreferencesGroup(),
                    ],
                  ),
                ),
                _FadeSlide(
                  delay: const Duration(milliseconds: 160),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionLabel('Appearance', topPad: 14),
                      _buildAppearanceSection(),
                    ],
                  ),
                ),
                _FadeSlide(
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionLabel('Account', topPad: 14),
                      _buildAccountGroup(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared top bar ────────────────────────────────────────────────────────
  Widget _buildTopBar({
    required Widget title,
    required Widget leading,
    required Widget trailing,
  }) {
    return Padding(
      // FIX-4: increased top padding since mock status bar is gone
      padding: const EdgeInsets.fromLTRB(22, 56, 22, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [leading, title, trailing],
      ),
    );
  }

  Widget _buildHeaderTitle(String normal, String italic) {
    return RichText(
      text: TextSpan(children: [
        TextSpan(
          text: normal,
          style: TextStyle(
              color: _textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.025),
        ),
        TextSpan(
          text: italic,
          style: TextStyle(
              color: _accentPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w300,
              letterSpacing: -0.03),
        ),
      ]),
    );
  }

  Widget _buildHeaderBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return _PressScaleWidget(
      onTap: onTap,
      pressedScale: 0.97,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _cardBorder),
          boxShadow: [
            BoxShadow(
                color: _bg.withValues(alpha: 0.30),
                blurRadius: 8,
                offset: const Offset(0, 2)),
            BoxShadow(
                color: _textPrimary.withValues(alpha: 0.08),
                blurRadius: 0,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Icon(icon, color: _textSub.withValues(alpha: 0.9), size: 18),
      ),
    );
  }

  // ── Profile Hero ──────────────────────────────────────────────────────────
  Widget _buildProfileHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _breatheAnim,
                builder: (_, _) {
                  final v = _breatheAnim.value.clamp(0.0, 1.0); // FIX-1
                  final opacity = 0.18 + (v * 0.12);
                  final scale = 1.0 + (v * 0.08);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _accentPrimary.withValues(alpha: opacity),
                            _accentSecondary.withValues(alpha: opacity * 0.4),
                            _bg.withValues(alpha: 0),
                          ],
                          stops: const [0.0, 0.45, 0.70],
                        ),
                      ),
                    ),
                  );
                },
              ),
              _buildAvatarRing(editable: false),
            ],
          ),
          const SizedBox(height: 16),
          // FIX-2: Display persisted name and username.
          Text(
            _profile.name,
            style: TextStyle(
                color: _textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.030),
          ),
          const SizedBox(height: 5),
          Text(
            _profile.username,
            style: TextStyle(
                color: _textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.025),
          ),
          const SizedBox(height: 20),
          _PressScaleWidget(
            onTap: _openEditView,
            pressedScale: 0.98,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_accentPrimary, _accentSecondary],
                ),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                      color: _accentPrimary.withValues(alpha: 0.30),
                      blurRadius: 28,
                      offset: const Offset(0, 8)),
                  BoxShadow(
                      color: _accentSecondary.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                  BoxShadow(
                      color: _textPrimary.withValues(alpha: 0.18),
                      blurRadius: 0,
                      offset: const Offset(0, 1)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit,
                      color: _textPrimary.withValues(alpha: 0.92), size: 13),
                  const SizedBox(width: 8),
                  Text('Edit Profile',
                      style: TextStyle(
                          color: _textPrimary.withValues(alpha: 0.97),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.025)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FIX-3: Web-safe avatar image renderer ────────────────────────────────
  // Both platforms store the picked image as Uint8List (_avatarBytes).
  // On Web:    image_picker already provides bytes via readAsBytes().
  // On Mobile: _pickImage also reads bytes and stores them in _avatarBytes.
  // This avoids dart:io File entirely so the file compiles on Flutter Web.
  Widget _buildAvatarImage() {
    if (_avatarBytes != null) {
      return Image.memory(
        _avatarBytes!,
        fit: BoxFit.cover,
        width: 87,
        height: 87,
        cacheWidth: 128,
        cacheHeight: 128,
      );
    }
    return _avatarPlaceholder();
  }

  Widget _avatarPlaceholder() => Center(
    child: Text(
      _profile.name.isNotEmpty ? _profile.name[0].toUpperCase() : 'C',
      style: TextStyle(
        color: _accentPrimary,
        fontSize: 30,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.02,
      ),
    ),
  );

  // ── Avatar ring ───────────────────────────────────────────────────────────
  Widget _buildAvatarRing({bool editable = true}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _breatheAnim,
          builder: (_, child) {
            // FIX-1: clamp so blurRadius / spreadRadius are never negative.
            final v = _breatheAnim.value.clamp(0.0, 1.0);
            final glowOpacity = v * 0.28;
            final blur = (v * 28).clamp(0.0, 28.0);
            final spread = glowOpacity > 0.10 ? 6.0 : 0.0;
            return Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _accentSecondary,
                    _accentPrimary,
                    _accentTertiary
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _accentPrimary
                        .withValues(alpha: glowOpacity.clamp(0.0, 1.0)), // FIX-1
                    blurRadius: blur, // FIX-1: guaranteed ≥ 0
                    spreadRadius: spread, // FIX-1: guaranteed ≥ 0
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2.5),
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_bg2, _t.phoneShell],
              ),
              border: Border.all(
                  color: _textPrimary.withValues(alpha: 0.10), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: _bg.withValues(alpha: 0.40),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            // FIX-3: Web-safe avatar renderer — see _buildAvatarImage()
            child: ClipOval(child: _buildAvatarImage()),
          ),
        ),
        // Camera badge
        Positioned(
          bottom: 1,
          right: 1,
          child: _PressScaleWidget(
            onTap: editable ? _pickImage : null,
            pressedScale: 1.08,
            child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: _accentPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: _bg, width: 2.5),
                boxShadow: [
                  BoxShadow(
                      color: _accentPrimary.withValues(alpha: 0.40),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                  BoxShadow(
                      color: _textPrimary.withValues(alpha: 0.15),
                      blurRadius: 0,
                      offset: const Offset(0, 1)),
                ],
              ),
              child: Icon(Icons.camera_alt,
                  color: _textPrimary, size: 11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text, {double topPad = 18}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPad, 24, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
            color: _textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.13),
      ),
    );
  }

  Widget _buildPreferencesGroup() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildListItem(
            icon: Icons.language,
            label: 'Language',
            meta: _selectedLanguage,
            onTap: () => setState(() => _showLanguageModal = true),
          ),
          const SizedBox(height: 3),
          _buildListItem(
            icon: Icons.location_on_outlined,
            label: 'Location',
            meta: 'Mumbai, IN',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String label,
    String? meta,
    bool destructive = false,
    required VoidCallback onTap,
  }) {
    return _PressScaleWidget(
      onTap: onTap,
      pressedScale: 0.985,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _bg.withValues(alpha: 0)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: destructive ? _dangerDim : _panel,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: destructive ? _dangerBorder : _cardBorder),
              ),
              child: Icon(icon,
                  color: destructive ? _danger : _accentPrimary, size: 15),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: destructive ? _textBody : _textSub,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.008)),
            ),
            if (meta != null) ...[
              Text(meta,
                  style: TextStyle(
                      color: _textMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w300)),
              const SizedBox(width: 4),
            ],
            Opacity(
                opacity: 0.35,
                child: Icon(Icons.chevron_right, color: _textMuted, size: 16)),
          ],
        ),
      ),
    );
  }

  // ── Appearance section ────────────────────────────────────────────────────
  Widget _buildAppearanceSection() {
    final controller = context.read<ThemeController>();
    final accent = getAccentPalette(controller.currentTheme);
    final isDark = controller.isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MODE',
                style: TextStyle(
                    color: _textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.10)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _toggleBrightness,
              child: Row(
                children: [
                  Icon(
                      isDark
                          ? Icons.nightlight_round
                          : Icons.wb_sunny,
                      color: _accentSecondary,
                      size: 17),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        isDark ? 'Dark Mode' : 'Light Mode',
                        style: TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: 44,
                    height: 25,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: isDark
                          ? LinearGradient(
                          colors: [_accentPrimary, _accentSecondary])
                          : null,
                      color: isDark ? null : _panel2,
                    ),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          left: isDark ? 22 : 3,
                          top: 3,
                          child: Container(
                            width: 19,
                            height: 19,
                            decoration: BoxDecoration(
                              color: _textPrimary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: _bg.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text('COLOUR THEME',
                style: TextStyle(
                    color: _textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.10)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                  color: _panel, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  _buildThemeBtn(
                    ProfileTheme.coolBlue,
                    'Cool Blue',
                    [_accentPrimary, _accentTertiary],
                  ),
                  _buildThemeBtn(
                    ProfileTheme.sunsetPop,
                    'Sunset Pop',
                    [accent.primary, accent.tertiary],
                  ),
                  _buildThemeBtn(
                    ProfileTheme.futureCandy,
                    'Future Candy',
                    [accent.secondary, accent.primary],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeBtn(
      ProfileTheme theme, String name, List<Color> dotColors) {
    final controller = context.read<ThemeController>();
    final isActive = controller.currentTheme == theme;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setTheme(theme, name),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
          const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? _panel2 : _bg.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive
                ? [
              BoxShadow(
                  color: _bg.withValues(alpha: 0.20),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dotColors,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: _bg.withValues(alpha: 0.22),
                        blurRadius: 4,
                        offset: const Offset(0, 1))
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(name,
                  style: TextStyle(
                      color: isActive ? _textPrimary : _textMuted,
                      fontSize: 11.5,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountGroup() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildListItem(
        icon: Icons.logout,
        label: 'Log Out',
        destructive: true,
        onTap: () => setState(() => _showLogoutModal = true),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EDIT VIEW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEditView() {
    return Column(
      key: const ValueKey('edit'),
      children: [
        _buildTopBar(
          title: _buildHeaderTitle('Edit ', 'Profile'),
          leading: _buildHeaderBtn(
            icon: Icons.chevron_left_rounded,
            onTap: _handleBackNavigation,
          ),
          trailing: GestureDetector(
            onTap: _canSave ? _saveProfile : null,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11)),
              child: AnimatedOpacity(
                opacity: _canSave ? 1.0 : 0.22,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.check, color: _accentPrimary, size: 20),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _editScrollCtrl,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 26),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    border:
                    Border(bottom: BorderSide(color: _cardBorder)),
                  ),
                  child: Center(child: _buildAvatarRing(editable: true)),
                ),
                _buildSectionTabs(),
                const SizedBox(height: 20),
                _buildEditTabBodies(),
                const SizedBox(height: 8),
                _PressScaleWidget(
                  onTap: _canSave && !_isSaving ? _saveProfile : null,
                  pressedScale: 0.99,
                  child: AnimatedOpacity(
                    opacity: _canSave ? 1.0 : 0.38,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _accentPrimary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: _accentPrimary.withValues(alpha: 0.28),
                              blurRadius: 28,
                              offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _isSaving ? 'Saving…' : 'Save Changes',
                          style: TextStyle(
                              color: _textPrimary.withValues(alpha: 0.96),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.01),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          _buildSectionTab('basics', 'Basics'),
          _buildSectionTab('style', 'Style'),
          _buildSectionTab('tryon', 'Try-On'),
        ],
      ),
    );
  }

  Widget _buildSectionTab(String id, String label) {
    final isActive = _selectedEditTab == id;
    Color c1 = _accentPrimary, c2 = _accentSecondary;
    Color glow = _accentPrimary.withValues(alpha: 0.35);
    if (id == 'style') {
      c1 = _accentSecondary;
      c2 = _accentPrimary;
      glow = _accentSecondary.withValues(alpha: 0.35);
    } else if (id == 'tryon') {
      c1 = _accentTertiary;
      c2 = _accentSecondary;
      glow = _accentTertiary.withValues(alpha: 0.35);
    }
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedEditTab = id);
          if (_editScrollCtrl.hasClients) {
            _editScrollCtrl.jumpTo(0);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding:
          const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isActive
                ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c1, c2])
                : null,
            boxShadow: isActive
                ? [
              BoxShadow(
                  color: glow,
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ]
                : null,
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isActive ? _textPrimary : _textMuted,
                  fontSize: 12.5,
                  fontWeight: isActive
                      ? FontWeight.w700
                      : FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildEditTabBodies() {
    switch (_selectedEditTab) {
      case 'style':
        return _buildStyleSection();
      case 'tryon':
        return _buildTryOnSection();
      case 'basics':
      default:
        return _buildBasicsSection();
    }
  }

  // ── Basics section ────────────────────────────────────────────────────────
  Widget _buildBasicsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldGroup('FULL NAME',
            controller: _nameCtrl, hint: 'Your name'),
        _buildFieldGroup('USERNAME',
            controller: _usernameCtrl, hint: '@username'),
        _buildFieldGroup('EMAIL',
            controller: _emailCtrl, hint: 'Email address'),
        _buildFieldGroup('PHONE',
            controller: _phoneCtrl,
            hint: 'Phone number',
            isPhone: true),
        _buildFieldGroup('DATE OF BIRTH',
            controller: _dobCtrl, hint: 'YYYY-MM-DD'),
        _buildGenderField(),
      ],
    );
  }

  Widget _buildFieldGroup(
      String label, {
        required TextEditingController controller,
        required String hint,
        bool isPhone = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: _textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08)),
          const SizedBox(height: 8),
          isPhone
              ? Row(
            children: [
              Container(
                width: 92,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 13),
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: _cardBorder),
                ),
                child: Text('+91',
                    style: TextStyle(
                        color: _textSub,
                        fontSize: 15,
                        fontWeight: FontWeight.w300)),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildTextField(
                      controller: controller, hint: hint)),
            ],
          )
              : _buildTextField(controller: controller, hint: hint),
        ],
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller, required String hint}) {
    return _FocusTextField(
      controller: controller,
      hint: hint,
      onChanged: (_) {
        if (!_isDirty) setState(() => _isDirty = true);
      },
    );
  }

  Widget _buildGenderField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GENDER',
              style: TextStyle(
                  color: _textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildGenderOption('Male', 'Male'),
              const SizedBox(width: 10),
              _buildGenderOption('Female', 'Female'),
              const SizedBox(width: 10),
              _buildGenderOption('Other', 'Other'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String value, String label) {
    // FIX-2D: Compare against _editingGender, not _profile.gender.
    final isSelected = value == _editingGender;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            // FIX-2D: Write to editing buffer, not directly to _profile.
            _editingGender = value;
            _isDirty = true;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
          const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? _accentDim : _panel,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
                color: isSelected ? _accentBorder : _cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isSelected ? _accentPrimary : _cardBorder,
                      width: 2),
                ),
                child: isSelected
                    ? Center(
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: _accentPrimary, shape: BoxShape.circle),
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: isSelected
                          ? _textSub
                          : _textSub.withValues(alpha: 0.7),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.01)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose your fashion style preferences.',
            style: TextStyle(color: _textMuted, fontSize: 12.5, height: 1.6)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Casual',
            'Streetwear',
            'Formal',
            'Minimalist',
            'Boho',
            'Sporty',
            'Vintage',
            'Glam'
          ].map(_buildStyleChip).toList(),
        ),
      ],
    );
  }

  Widget _buildStyleChip(String label) {
    final selected = _selectedStyles.contains(label);
    return GestureDetector(
      onTap: () => setState(() {
        selected
            ? _selectedStyles.remove(label)
            : _selectedStyles.add(label);
        _isDirty = true;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_accentPrimary, _accentSecondary])
              : null,
          color: selected ? null : _panel,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
              color: selected ? _bg.withValues(alpha: 0) : _cardBorder,
              width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? _textPrimary : _textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildTryOnSection() {
    return Column(
      children: [
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cardBorder, width: 1.5),
          ),
          child: Column(
            children: [
              const Text('📷',
                  style: TextStyle(fontSize: 42)),
              const SizedBox(height: 14),
              _PressScaleWidget(
                onTap: _pickImage,
                pressedScale: 0.97,
                child: Text(
                  'Tap to upload a full-body photo\nto try on outfits virtually.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _textMuted, fontSize: 13, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODALS
  // ─────────────────────────────────────────────────────────────────────────

  // FIX-2A: Logout modal closes immediately; no competing timer.
  Widget _buildLogoutModal() {
    return _buildModalOverlay(
      onDismiss: () => setState(() => _showLogoutModal = false),
      child: Column(
        children: [
          _buildModalHandle(),
          _buildModalIconWrap(Icons.logout, danger: true),
          const SizedBox(height: 18),
          Text('Log Out?',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.025)),
          const SizedBox(height: 9),
          Text(
            "You'll need to sign in again to access your account.",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _textMuted,
                fontSize: 14,
                height: 1.65,
                fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 28),
          _ConfirmButton(
            label: 'Log Out',
            loadingLabel: 'Please wait…',
            danger: true,
            // FIX-2A: Close modal first, then show toast. No competing timers.
            onConfirmed: () {
              setState(() => _showLogoutModal = false);
              _showToast(context, 'Signed out successfully');
            },
          ),
          const SizedBox(height: 10),
          _buildCancelBtn('Cancel',
              onTap: () => setState(() => _showLogoutModal = false)),
        ],
      ),
    );
  }

  Widget _buildLanguageModal() {
    const languages = [
      {'code': 'English', 'flag': '🇬🇧', 'name': 'English', 'sub': ''},
      {'code': 'Telugu', 'flag': '🇮🇳', 'name': 'Telugu', 'sub': 'తెలుగు'},
      {'code': 'Hindi', 'flag': '🇮🇳', 'name': 'Hindi', 'sub': 'हिन्दी'},
      {'code': 'Tamil', 'flag': '🇮🇳', 'name': 'Tamil', 'sub': 'தமிழ்'},
      {
        'code': 'Malayalam',
        'flag': '🇮🇳',
        'name': 'Malayalam',
        'sub': 'മലയാളം'
      },
      {
        'code': 'Kannada',
        'flag': '🇮🇳',
        'name': 'Kannada',
        'sub': 'ಕನ್ನಡ'
      },
    ];

    return _buildModalOverlay(
      onDismiss: () => setState(() => _showLanguageModal = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModalHandle(),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: 'Choose ',
                  style: TextStyle(
                      color: _textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.025)),
              TextSpan(
                  text: 'Language',
                  style: TextStyle(
                      color: _accentPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic)),
            ]),
          ),
          const SizedBox(height: 9),
          Text('Select your preferred display language.',
              style: TextStyle(
                  color: _textMuted,
                  fontSize: 14,
                  height: 1.65,
                  fontWeight: FontWeight.w300)),
          const SizedBox(height: 16),
          ...languages.map((lang) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedLanguage = lang['code']!);
                _showToast(
                    context, '✓ Language set to ${lang['name']}');
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: _selectedLanguage == lang['code']
                      ? _accentDim
                      : _card,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                      color: _selectedLanguage == lang['code']
                          ? _accentBorder
                          : _cardBorder),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(lang['flag']!,
                          style: const TextStyle(fontSize: 20),
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(lang['name']!,
                              style: TextStyle(
                                  color: _textSub,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w400)),
                          if (lang['sub']!.isNotEmpty)
                            Text(lang['sub']!,
                                style: TextStyle(
                                    color: _textMuted, fontSize: 11.5)),
                        ],
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedLanguage == lang['code']
                            ? _accentPrimary
                            : _bg.withValues(alpha: 0),
                        border: Border.all(
                            color: _selectedLanguage == lang['code']
                                ? _accentPrimary
                                : _cardBorder,
                            width: 2),
                      ),
                      child: _selectedLanguage == lang['code']
                          ? Center(
                          child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                  color: _textPrimary,
                                  shape: BoxShape.circle)))
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          )),
          const SizedBox(height: 16),
          _buildCancelBtn('Done',
              onTap: () => setState(() => _showLanguageModal = false)),
        ],
      ),
    );
  }

  Widget _buildDiscardModal() {
    return _buildModalOverlay(
      onDismiss: () => setState(() => _showDiscardModal = false),
      child: Column(
        children: [
          _buildModalHandle(),
          _buildModalIconWrap(Icons.edit_off_outlined, danger: false),
          const SizedBox(height: 18),
          Text('Discard Changes?',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.025)),
          const SizedBox(height: 9),
          Text(
            'You have unsaved edits. Going back will discard all changes.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _textMuted,
                fontSize: 14,
                height: 1.65,
                fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 28),
          _ConfirmButton(
            label: 'Discard',
            loadingLabel: 'Discarding…',
            danger: true,
            onConfirmed: () {
              // FIX-2C: Revert avatar to last saved state.
              // FIX-2D: Revert editing gender to persisted value.
              setState(() {
                _showDiscardModal = false;
                _isDirty = false;
                _showEditView = false;
                // FIX-2C / FIX-3: revert avatar bytes to last saved state
                _avatarBytes = _savedAvatarBytes;
                context.read<ProfileController>().setAvatarBytes(_avatarBytes);
                _editingGender = _profile.gender; // FIX-2D
                // Restore text controllers to last saved values.
                _nameCtrl.text = _profile.name;
                _usernameCtrl.text = _profile.username;
                _emailCtrl.text = _profile.email;
                _phoneCtrl.text = _profile.phone;
                _dobCtrl.text = _profile.dob;
              });
            },
          ),
          const SizedBox(height: 10),
          _buildCancelBtn('Keep Editing',
              onTap: () => setState(() => _showDiscardModal = false)),
        ],
      ),
    );
  }

  // ── Modal helpers ─────────────────────────────────────────────────────────
  Widget _buildModalOverlay(
      {required Widget child, required VoidCallback onDismiss}) {
    return GestureDetector(
      // FIX-4D: opaque hit-testing so the overlay always receives taps.
      behavior: HitTestBehavior.opaque,
      onTap: onDismiss,
      child: Container(
        color: _bg.withValues(alpha: 0.65),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            // Absorb taps on the sheet itself to prevent dismiss.
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: TweenAnimationBuilder<Offset>(
              tween: Tween(begin: const Offset(0, 1), end: Offset.zero),
              duration: const Duration(milliseconds: 260),
              curve: const Cubic(0.32, 0.72, 0.0, 1.0),
              builder: (_, offset, child2) =>
                  FractionalTranslation(translation: offset, child: child2),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 36),
                decoration: BoxDecoration(
                  color: _bg2.withValues(alpha: 0.96),
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border.all(color: _cardBorder),
                  boxShadow: [
                    BoxShadow(
                        color: _bg.withValues(alpha: 0.50),
                        blurRadius: 60,
                        offset: const Offset(0, -16)),
                    BoxShadow(
                        color: _accentPrimary.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -2)),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalHandle() => Center(
    child: Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: _textPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
    ),
  );

  Widget _buildModalIconWrap(IconData icon, {bool danger = false}) =>
      Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: danger ? _dangerDim : _accentDim,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
              color: danger ? _dangerBorder : _accentBorder),
        ),
        child: Icon(icon, color: danger ? _danger : _accentPrimary, size: 24),
      );

  Widget _buildCancelBtn(String label, {required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _textBody,
                  fontSize: 15,
                  fontWeight: FontWeight.w400)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _PressScaleWidget — tap-down / tap-up scale feedback
// ─────────────────────────────────────────────────────────────────────────────
class _PressScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const _PressScaleWidget({
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
  });

  @override
  State<_PressScaleWidget> createState() => _PressScaleWidgetState();
}

class _PressScaleWidgetState extends State<_PressScaleWidget> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    onTapDown:
    widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
    onTapUp: (_) => setState(() => _pressed = false),
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? widget.pressedScale : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _FocusTextField — animated focus ring
// FIX-2: Accepts an external TextEditingController so values survive rebuilds.
// ─────────────────────────────────────────────────────────────────────────────
class _FocusTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  const _FocusTextField({
    required this.controller,
    required this.hint,
    this.onChanged,
  });

  @override
  State<_FocusTextField> createState() => _FocusTextFieldState();
}

class _FocusTextFieldState extends State<_FocusTextField> {
  late final FocusNode _focus;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()
      ..addListener(() => setState(() => _isFocused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accentPrimary = t.accent.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _isFocused ? t.panelBorder : t.panel,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
            color: _isFocused
                ? accentPrimary.withValues(alpha: 0.28)
                : t.cardBorder),
        boxShadow: _isFocused
            ? [
          // FIX-1: Constant blurRadius — never goes negative.
          BoxShadow(
              color: accentPrimary.withValues(alpha: 0.10),
              blurRadius: 4,
              spreadRadius: 3),
        ]
            : null,
      ),
      child: TextField(
        focusNode: _focus,
        controller: widget.controller,
        onChanged: widget.onChanged,
        style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 15,
            fontWeight: FontWeight.w300),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
              color: t.mutedText,
              fontWeight: FontWeight.w300),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ConfirmButton — loading state on confirm actions
// FIX-2A: Uses onConfirmed callback called after the loading delay, so the
// parent decides when to close the modal without a competing timer.
// ─────────────────────────────────────────────────────────────────────────────
class _ConfirmButton extends StatefulWidget {
  final String label;
  final String loadingLabel;
  final bool danger;
  // FIX-2A: renamed from onTap → onConfirmed; called after loading delay.
  final VoidCallback onConfirmed;

  const _ConfirmButton({
    required this.label,
    required this.loadingLabel,
    required this.danger,
    required this.onConfirmed,
  });

  @override
  State<_ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<_ConfirmButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accentPrimary = t.accent.primary;
    final accentSecondary = t.accent.secondary;
    return GestureDetector(
      onTap: _loading
          ? null
          : () async {
        setState(() => _loading = true);
        await Future.delayed(const Duration(milliseconds: 800));
        // FIX-2A: invoke onConfirmed once, after delay; parent handles state.
        if (mounted) widget.onConfirmed();
        if (mounted) setState(() => _loading = false);
      },
      child: AnimatedOpacity(
        opacity: _loading ? 0.65 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: widget.danger ? t.accent.tertiary : null,
            gradient: widget.danger
                ? null
                : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accentPrimary, accentSecondary]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (widget.danger
                    ? t.accent.tertiary
                    : accentPrimary)
                    .withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            _loading ? widget.loadingLabel : widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: context.themeTokens.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin<_KeepAliveWrapper> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}