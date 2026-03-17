import re

path = r'c:\Users\parim\myapp\lib\workout.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# The problem: lines like:
#   final kAccentGrad = LinearGradient(
#       begin: Alignment.topLeft,
#       end: Alignment.bottomRight,
#       colors: [accent.secondary, accent.primary],
#   );
# The regex removed only "  final kAccentGrad = LinearGradient(\r\n" 
# leaving the orphaned "begin:", "end:", "colors:", ");" lines

# Find all orphaned gradient patterns (lines that start with "begin:" or "end:" 
# that aren't inside a proper constructor call) and add back the variable assignment.
# These always appear as:
#   "      begin: Alignment.topLeft,\n      end: Alignment.bottomRight,\n      colors: [...],\n    );\n"
# preceded by a line that ends with ";" or "}" or variable declaration

# The fix: add "final kAccentGrad = LinearGradient(" before each orphaned block
orphan_pattern = re.compile(
    r'([ \t]+)(begin: Alignment\.topLeft,\r?\n'
    r'\s+end: Alignment\.bottomRight,\r?\n'
    r'\s+colors: \[(?:accent\.|kAccent)[^\]]+\],\r?\n'
    r'\s+\);)',
    re.MULTILINE
)

def repair_gradient(m):
    indent = m.group(1)
    body = m.group(2)
    return f'{indent}final kAccentGrad = LinearGradient(\n{indent}{body}'

new_text = orphan_pattern.sub(repair_gradient, text)

count = len(orphan_pattern.findall(text))
print(f'Found {count} orphaned gradient blocks')

if new_text != text:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_text)
    print('Fixed: workout.dart')
else:
    print('No changes made to workout.dart')
    # Print the orphaned contexts to debug
    orphan_simple = re.compile(r'      begin: Alignment\.topLeft,')
    for m in orphan_simple.finditer(text):
        start = max(0, m.start() - 200)
        print(f'Context around "begin:": ...{repr(text[start:m.start()+300])}...')
        print('---')
