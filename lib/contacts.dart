import 'package:flutter/material.dart';
import 'package:myapp/services/appwrite_service.dart';
import 'package:myapp/theme/theme_tokens.dart';
import 'package:provider/provider.dart';

enum _ContactSort { az, recent }

class _ContactRecord {
  final String id;
  final String name;
  final String number;
  final String? imageUrl;
  final DateTime addedAt;

  const _ContactRecord({
    required this.id,
    required this.name,
    required this.number,
    required this.imageUrl,
    required this.addedAt,
  });
}

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  _ContactSort _sort = _ContactSort.az;
  bool _loading = true;
  String? _loadError;
  final List<_ContactRecord> _allContacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
      final appwrite = Provider.of<AppwriteService>(context, listen: false);
      final docs = await appwrite.getContacts();
      final mapped = docs.map((doc) {
        final data = doc.data;
        final raw = doc.raw;

        final name = (data['name'] ?? '').toString().trim();
        final number =
            (data['number'] ?? data['phone'] ?? data['phone_number'] ?? '')
                .toString()
                .trim();
        final image =
            (data['image_url'] ?? data['imageUrl'] ?? '')
                .toString()
                .trim();
        final created =
            (data['addedAt'] ?? data['createdAt'] ?? raw[r'$createdAt'] ?? '')
                .toString()
                .trim();

        return _ContactRecord(
          id: doc.$id,
          name: name.isEmpty ? 'Unnamed contact' : name,
          number: number,
          imageUrl: image.isEmpty ? null : image,
          addedAt: DateTime.tryParse(created) ?? DateTime.fromMillisecondsSinceEpoch(0),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _allContacts
          ..clear()
          ..addAll(mapped);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _openAddContactPage() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const _AddContactPage(),
      ),
    );
    if (saved == true) {
      await _loadContacts();
    }
  }

  Future<void> _deleteContact(_ContactRecord contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final t = dialogContext.themeTokens;
        return AlertDialog(
          backgroundColor: t.backgroundSecondary,
          title: Text(
            'Delete contact?',
            style: TextStyle(color: t.textPrimary),
          ),
          content: Text(
            contact.name,
            style: TextStyle(color: t.mutedText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final appwrite = Provider.of<AppwriteService>(context, listen: false);
      await appwrite.deleteContact(contact.id);
      if (!mounted) return;
      setState(() {
        _allContacts.removeWhere((c) => c.id == contact.id);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  List<_ContactRecord> get _contacts {
    final q = _query.trim().toLowerCase();
    final filtered = _allContacts.where((c) {
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) || c.number.toLowerCase().contains(q);
    }).toList();

    switch (_sort) {
      case _ContactSort.az:
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case _ContactSort.recent:
        filtered.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    }
    return filtered;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final contacts = _contacts;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              _buildSearch(t),
              const SizedBox(height: 12),
              _buildActions(t),
              const SizedBox(height: 14),
              _buildSort(t),
              const SizedBox(height: 12),
              if (_loading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: CircularProgressIndicator(color: t.accent.primary),
                  ),
                ),
              if (!_loading && _loadError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.panel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.cardBorder),
                  ),
                  child: Text(
                    'Failed to load contacts from backend: $_loadError',
                    style: TextStyle(color: t.mutedText, fontSize: 12),
                  ),
                ),
              if (!_loading && _loadError == null && contacts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.panel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.cardBorder),
                  ),
                  child: Text(
                    'No contacts found. Add your first contact.',
                    style: TextStyle(color: t.mutedText, fontSize: 12),
                  ),
                ),
            ]),
          ),
        ),
        if (!_loading && contacts.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildContactCard(t, contacts[i]),
                childCount: contacts.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearch(AppThemeTokens t) {
    return Container(
      decoration: BoxDecoration(
        color: t.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.cardBorder),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        style: TextStyle(color: t.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: 'Search name or number',
          hintStyle: TextStyle(color: t.mutedText),
          prefixIcon: Icon(Icons.search_rounded, color: t.mutedText, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        ),
      ),
    );
  }

  Widget _buildActions(AppThemeTokens t) {
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Add Contact',
            onTap: () {
              _openAddContactPage();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon: Icons.refresh_rounded,
            label: 'Refresh',
            onTap: () {
              _loadContacts();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSort(AppThemeTokens t) {
    final label = _sort == _ContactSort.az ? 'A-Z' : 'Recent';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Contacts',
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        PopupMenuButton<_ContactSort>(
          onSelected: (value) => setState(() => _sort = value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: _ContactSort.az, child: Text('A-Z')),
            PopupMenuItem(value: _ContactSort.recent, child: Text('Recent')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: t.panel,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort_rounded, size: 16, color: t.mutedText),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(color: t.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(
    AppThemeTokens t,
    _ContactRecord contact,
  ) {
    final initials = contact.name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: t.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.cardBorder),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => _deleteContact(contact),
              child: Icon(Icons.delete_outline_rounded, size: 18, color: t.mutedText),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                color: t.backgroundSecondary,
                child: contact.imageUrl == null
                    ? Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : Image.network(
                        contact.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: t.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            contact.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            contact.number,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.mutedText,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: t.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: t.accent.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddContactPage extends StatefulWidget {
  const _AddContactPage();

  @override
  State<_AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<_AddContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _otherInfoCtrl = TextEditingController();

  DateTime? _birthday;
  String _countryCode = '+1';
  bool _saving = false;

  static const List<String> _countryCodes = [
    '+1',
    '+44',
    '+91',
    '+61',
    '+65',
    '+81',
  ];

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _surnameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _otherInfoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthday = picked);
    }
  }

  Future<void> _saveContact() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving) return;

    final first = _firstNameCtrl.text.trim();
    final surname = _surnameCtrl.text.trim();
    final fullName = [first, surname].where((s) => s.isNotEmpty).join(' ').trim();
    final phone = '$_countryCode ${_phoneCtrl.text.trim()}'.trim();

    final payload = <String, dynamic>{
      'name': fullName,
      'number': phone,
    };

    setState(() => _saving = true);
    try {
      final appwrite = Provider.of<AppwriteService>(context, listen: false);
      await appwrite.createContact(payload);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contact save failed: $e')),
      );
      setState(() => _saving = false);
    }
  }

  String _birthdayText() {
    final b = _birthday;
    if (b == null) return 'Select birthday';
    final month = b.month.toString().padLeft(2, '0');
    final day = b.day.toString().padLeft(2, '0');
    return '${b.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;

    return Scaffold(
      backgroundColor: t.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: t.backgroundPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: t.textPrimary),
        title: Text(
          'Create Contact',
          style: TextStyle(
            color: t.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InputField(
                  controller: _firstNameCtrl,
                  label: 'First name',
                  hint: 'Enter first name',
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'First name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: _surnameCtrl,
                  label: 'Surname',
                  hint: 'Enter surname',
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 12),
                Text(
                  'Phone number',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: t.panel,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: t.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _countryCode,
                          dropdownColor: t.panel,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          iconEnabledColor: t.mutedText,
                          items: _countryCodes
                              .map(
                                (code) => DropdownMenuItem<String>(
                                  value: code,
                                  child: Text(code),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _countryCode = value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InputField(
                        controller: _phoneCtrl,
                        label: '',
                        hint: 'Phone number',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          return null;
                        },
                        denseTop: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'Optional (not stored yet)',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                Text(
                  'Birthday',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickBirthday,
                  child: Ink(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: t.panel,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cake_outlined,
                          color: t.mutedText,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _birthdayText(),
                          style: TextStyle(
                            color: _birthday == null ? t.mutedText : t.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: _addressCtrl,
                  label: 'Address',
                  hint: 'Optional (not stored yet)',
                  keyboardType: TextInputType.streetAddress,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: _otherInfoCtrl,
                  label: 'Other info',
                  hint: 'Optional (not stored yet)',
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveContact,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: t.accent.primary,
                      foregroundColor: t.tileText,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Save Contact',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
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

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.denseTop = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool denseTop;

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: denseTop ? 0 : 7),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: t.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: t.mutedText),
            filled: true,
            fillColor: t.panel,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: t.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: t.accent.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}
