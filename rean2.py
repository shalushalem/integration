import sys
lines = sys.stdin.readlines()
issues = [l.rstrip() for l in lines if l.strip().startswith(('info', 'warning', 'error'))]
for i in issues:
    print(i)
print(f'\nTotal: {len(issues)} issues')
