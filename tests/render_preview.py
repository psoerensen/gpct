"""Local Markdown preview for visual QA; GitHub Pages still builds with Jekyll.

Requires Markdown 3.7 in the isolated tooling environment. The stylesheet comes
from the published site; this preview does not compile SCSS or replace Jekyll.
"""
from pathlib import Path
import argparse
import html
import re
import shutil
import time
import markdown

parser = argparse.ArgumentParser()
parser.add_argument('--docs', type=Path, default=Path('docs'))
parser.add_argument('--output', type=Path, default=Path('_site/gpct'))
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
shutil.copytree(args.docs / 'assets', args.output / 'assets', dirs_exist_ok=True)
css = args.output / 'assets/css/style.css'
css.parent.mkdir(parents=True, exist_ok=True)
css.write_text('@import url("https://psoerensen.github.io/gpct/assets/css/style.css");\n', encoding='utf-8')
layout = (args.docs / '_layouts/default.html').read_text(encoding='utf-8-sig')

def liquid(text, title):
    text = re.sub(r"\{\{\s*'([^']*)'\s*\|\s*relative_url\s*\}\}",
                  lambda match: '/gpct' + match[1], text)
    text = re.sub(r"\{\{\s*site.time\s*\|\s*date:\s*'%s'\s*\}\}", str(int(time.time())), text)
    return text.replace('{{ page.title | escape }}', html.escape(title)).replace(
        '{{ site.description | escape }}', 'Benchmarks for methods and models implemented in the gsuite ecosystem')

for source in args.docs.rglob('*.md'):
    text = source.read_text(encoding='utf-8-sig')
    title = source.stem
    if text.startswith('---'):
        _, front, text = text.split('---', 2)
        match = re.search(r'^title:\s*(.+)$', front, re.M)
        if match:
            title = match[1].strip().strip('"')
    content = markdown.markdown(liquid(text, title), extensions=['tables', 'fenced_code'])
    rendered = liquid(layout, title).replace('{{ content }}', content)
    destination = args.output / source.relative_to(args.docs).with_suffix('.html')
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(rendered, encoding='utf-8')
print(f'Rendered local preview at {args.output}; published CSS, Markdown renderer, not a Jekyll build.')
