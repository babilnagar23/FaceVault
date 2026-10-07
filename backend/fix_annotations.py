import os
import glob
files = glob.glob('app/**/*.py', recursive=True) + glob.glob('tests/**/*.py', recursive=True) + glob.glob('scripts/**/*.py', recursive=True)
for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    if 'from __future__ import annotations' not in content:
        if content.startswith('"""'):
            end_docstring = content.find('"""', 3)
            if end_docstring != -1:
                insert_pos = end_docstring + 3
                new_content = content[:insert_pos] + '\nfrom __future__ import annotations\n' + content[insert_pos:]
            else:
                new_content = 'from __future__ import annotations\n' + content
        else:
            new_content = 'from __future__ import annotations\n' + content
        with open(f, 'w', encoding='utf-8') as file:
            file.write(new_content)
