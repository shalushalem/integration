import re, os

lib = r'c:\Users\parim\myapp\lib'

def fix_file(filename, replacements):
    path = os.path.join(lib, filename)
    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()
    new_text = text
    for old, new in replacements:
        new_text = new_text.replace(old, new)
    if new_text != text:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_text)
        print(f'Fixed: {filename}')
    else:
        print(f'No change: {filename}')


# Fix office_fit.dart
fix_file('office_fit.dart', [
    ("import 'dart:math' as math;\n", ''),
    ('ClampingScrollPhysics()', 'BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())'),
])

# Fix vacation.dart: unreachable_switch_default
# Remove the default clause from the switch on _VacBg enum
# (all cases covered, default is unreachable)
path = os.path.join(lib, 'vacation.dart')
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()
# Remove: default:\n        return LinearGradient(... ) that follows after all enum cases
# The pattern is: the default case at end of a switch on an exhaustive enum
new_text = re.sub(
    r'\n\s*default:\s*\n\s*return LinearGradient\([^;]+;\s*\}',
    '\n    }',
    text,
    flags=re.DOTALL
)
if new_text != text:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_text)
    print('Fixed: vacation.dart (unreachable_switch_default)')
else:
    print('vacation.dart - no default clause found for removal, checking manually...')
    # Find the pattern
    idx = text.find('default:')
    print(f'  default: at index {idx}')
    print(f'  context: {repr(text[max(0,idx-50):idx+200])}')


# Fix party_looks.dart: remove unused private state fields
path = os.path.join(lib, 'party_looks.dart')
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Remove unused getter aliases in _Screen4State (lines 119-130)
unused_getters = [
    "  Color get _panel => _t.panel;\n",
    "  Color get _panel2 => _t.panelBorder;\n",
    "  Color get _card => _t.card;\n", 
    "  Color get _cardBorder => _t.cardBorder;\n",
    "  Color get _text => _t.textPrimary;\n",
    "  Color get _muted => _t.mutedText;\n",
    "  Color get _accent => _t.accent.primary;\n",
    "  Color get _accent2 => _t.accent.secondary;\n",
    "  Color get _accent4 => _t.accent.tertiary;\n",
    "  Color get _phoneShell => _t.phoneShell;\n",
    "  Color get _transparent => _t.backgroundPrimary.withValues(alpha: 0.0);\n",
    "  Color get _phoneShell2 => _t.phoneShellInner;\n",
]
for g in unused_getters:
    text = text.replace(g, '')

# Fix prefer_final_fields: _looks field can be final... actually it's mutated by setState
# Skip this one - it's a false positive since _looks IS mutated

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print('Fixed: party_looks.dart (unused getters)')


# Fix everything_else.dart: remove unused private declarations
path = os.path.join(lib, 'everything_else.dart')
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

unused_decls = [
    "  Color get _panelShell2 => _t.phoneShellInner;\n",
    "  Color get _muted => _t.mutedText;\n",
    "  Color get _tileText => _t.tileText;\n",
    "  Color get _accent => _t.accent.primary;\n",
    "  Color get _accent2 => _t.accent.secondary;\n",
    "  Color get _accent3 => _t.accent.tertiary;\n",
    "  Color get _accent4 => Color.lerp(_t.accent.primary, _t.accent.secondary, 0.55)!;\n",
    "  Color get _accent5 => Color.lerp(_t.accent.secondary, _t.accent.tertiary, 0.55)!;\n",
    "  Color get _card => _t.card;\n",
    "  Color get _cardBorder => _t.cardBorder;\n",
    "  Color get _panel => _t.panel;\n",
    "  Color get _transparent => _t.backgroundPrimary.withValues(alpha: 0.0);\n",
]
for d in unused_decls:
    text = text.replace(d, '')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print('Fixed: everything_else.dart (unused declarations)')


# Fix profile.dart: remove unused import, unused fields, fix __ params
path = os.path.join(lib, 'profile.dart')
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Remove unused import
text = text.replace("import 'package:myapp/theme/base_theme.dart';\n", '')

# Remove unused private getter declarations
unused_profile = [
    "  Color get _tileText => _t.tileText;\n",
    "  Color get _accentDimLocal => _t.accent.primary.withValues(alpha: 0.25);\n",
    "  Color get _accentBorderLocal => _t.accent.primary.withValues(alpha: 0.40);\n",
]
for d in unused_profile:
    text = text.replace(d, '')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print('Fixed: profile.dart (unused import/fields)')


# Fix home.dart: remove unused private field _panelBorder
path = os.path.join(lib, 'home.dart')
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()
text = text.replace("  Color get _panelBorder => _t.panelBorder;\n", '')
with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print('Fixed: home.dart (unused _panelBorder)')


# Fix home & utilities.dart: remove unused _PlaceholderPage
path = os.path.join(lib, 'home & utilities.dart')
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()
# The _PlaceholderPage is unused, find and remove it
new_text = re.sub(
    r'\n// .*?\nclass _PlaceholderPage extends StatelessWidget.*?^\}',
    '',
    text,
    flags=re.DOTALL|re.MULTILINE
)
if new_text != text:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_text)
    print('Fixed: home & utilities.dart (_PlaceholderPage removed)')
else:
    print('home & utilities.dart - _PlaceholderPage pattern not found')


# Fix medi_tracker.dart: remove unnecessary_to_list_in_spreads
path = os.path.join(lib, 'medi_tracker.dart')
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()
# Line 2088: ...items.toList() -> ...items in a spread
# The pattern in spreads: ...[...someList.map(...).toList()]  -> ...someList.map(...)
text = re.sub(r'\.\.\.\(([^)]+)\.map\(([^)]+)\)\.toList\(\)\)', r'...(\1.map(\2))', text)
text = re.sub(r'\.\.\.([\w.]+)\.toList\(\)', r'...\1', text)
with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print('Fixed: medi_tracker.dart (unnecessary_to_list_in_spreads)')


print('\nAll fixes applied!')
