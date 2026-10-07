import os
import glob
files = glob.glob('app/**/*.py', recursive=True) + glob.glob('tests/**/*.py', recursive=True)
for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    if 'from __future__ import annotations' in content and not content.startswith('\"\"\"') and not content.startswith('from __future__ import annotations'):
        content = content.replace('from __future__ import annotations\n', '')
        content = 'from __future__ import annotations\n' + content
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)
        print('Fixed __future__ in', f)
    elif 'from __future__ import annotations' in content and content.startswith('\"\"\"'):
        content = content.replace('from __future__ import annotations\n', '')
        end = content.find('\"\"\"', 3)
        if end != -1:
            insert_pos = end + 3
            content = content[:insert_pos] + '\nfrom __future__ import annotations\n' + content[insert_pos:].lstrip('\n')
            with open(f, 'w', encoding='utf-8') as file:
                file.write(content)
            print('Fixed __future__ (docstring) in', f)
