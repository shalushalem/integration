with open(r'c:\Users\parim\myapp\an.txt', encoding='utf-8', errors='replace') as f:
    lines = f.readlines()
issues = [l.rstrip() for l in lines if l.strip().startswith(('info', 'warning', 'error'))]
for i in issues:
    print(i)
print(f'\nTotal: {len(issues)} issues')
