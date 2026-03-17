import sys, re
# Read from stdin, write categorized list to file
lines = sys.stdin.read().split('\n')
issues = [l.rstrip() for l in lines if l.strip().startswith(('info', 'warning', 'error'))]

# Group by category
categories = {}
for l in issues:
    m = re.search(r'-\s+([a-z_]+)\s*$', l)
    cat = m.group(1) if m else 'other'
    categories.setdefault(cat, []).append(l)

# Write to file
with open(r'c:\Users\parim\myapp\issues.txt', 'w', encoding='utf-8') as f:
    for cat, items in sorted(categories.items()):
        f.write(f'\n=== {cat} ({len(items)}) ===\n')
        for i in items:
            f.write(i + '\n')
    f.write(f'\nTotal: {len(issues)} issues\n')

# Also print summary
print(f'Total: {len(issues)} issues')
for cat, items in sorted(categories.items()):
    print(f'  {cat}: {len(items)}')
