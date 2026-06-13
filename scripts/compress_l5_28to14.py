#!/usr/bin/env python3
"""L5-085~094 压缩脚本：28页 → 14页"""
import re
from pathlib import Path

CONTENT_DIR = Path("/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容")

FILES = [
    "L5-085_论语故事.md",
    "L5-086_宇宙的奥秘.md",
    "L5-087_假如我是你.md",
    "L5-088_千字文故事.md",
    "L5-089_人工智能来了.md",
    "L5-090_唐诗里的春天.md",
    "L5-091_什么是公平.md",
    "L5-092_郑和下西洋.md",
    "L5-093_微观世界.md",
    "L5-094_我的第一次辩论.md",
]

def extract_pages(content):
    in_section = False
    pages = []
    current = None
    for line in content.split('\n'):
        if re.match(r'##\s*三[、．]\s*故事正文', line):
            in_section = True
            continue
        if in_section and re.match(r'##\s*[四五六][、．]', line):
            break
        if not in_section:
            continue
        pm = re.match(r'###\s*Page\s+(\d+)', line)
        if pm:
            if current:
                pages.append(current)
            current = {'num': int(pm.group(1)), 'raw_lines': []}
        if current is not None:
            current['raw_lines'].append(line)
    if current:
        pages.append(current)
    return pages

def parse_page(p):
    desc, text, pinyin, chars = "", "", "", ""
    section = None
    buf = ""
    for ln in p['raw_lines']:
        if '【画面描述】' in ln:
            if section:
                if section == 'desc': desc = buf
                elif section == 'text': text = buf
                elif section == 'pinyin': pinyin = buf
                elif section == 'chars': chars = buf
            section = 'desc'
            buf = ln.replace('【画面描述】', '').strip()
        elif '【文字】' in ln:
            if section == 'desc': desc = buf
            section = 'text'
            buf = ln.replace('【文字】', '').strip()
        elif '【拼音】' in ln:
            if section == 'text': text = buf
            section = 'pinyin'
            buf = ln.replace('【拼音】', '').strip()
        elif '【新字' in ln or '【新字标注】' in ln:
            if section == 'pinyin': pinyin = buf
            section = 'chars'
            buf = re.sub(r'【新字[^】]*】', '', ln).strip()
        else:
            if section and buf is not None:
                buf += '\n' + ln.strip()
    if section == 'chars': chars = buf
    elif section == 'pinyin': pinyin = buf
    elif section == 'text': text = buf
    elif section == 'desc': desc = buf
    return {'desc': desc, 'text': text, 'pinyin': pinyin, 'chars': chars}

def merge_two(a, b):
    # 画面描述
    new_desc = a['desc']
    if b['desc'] and b['desc'] != a['desc']:
        new_desc = a['desc'] + "；" + b['desc']
    # 文字
    new_text = a['text']
    if b['text'] and b['text'] != a['text']:
        if new_text and new_text[-1] not in '。！？':
            new_text += '，'
        new_text += b['text']
    # 拼音
    new_pinyin = a['pinyin']
    if b['pinyin'] and b['pinyin'] != a['pinyin']:
        new_pinyin += ' ' + b['pinyin']
    # 新字去重
    a_c = set(re.findall(r'[\u4e00-\u9fff]', a['chars']))
    b_c = set(re.findall(r'[\u4e00-\u9fff]', b['chars']))
    merged = a_c | b_c
    a_rev = '复习' in a['chars'] or '（复习' in a['chars']
    b_rev = '复习' in b['chars'] or '（复习' in b['chars']
    label = '（复习字）' if (a_rev or b_rev) else ''
    new_chars = '、'.join(sorted(merged)) + label
    return {'desc': new_desc, 'text': new_text, 'pinyin': new_pinyin.strip(), 'chars': new_chars}

def compress_to_14(pages_28):
    merged = []
    for i in range(0, 28, 2):
        a = pages_28[i]
        b = pages_28[i+1] if i+1 < len(pages_28) else None
        if b:
            merged.append(merge_two(a, b))
        else:
            merged.append(a)
    return merged

def rebuild_section(pages_14):
    lines = ["## 三、故事正文（分页脚本）\n"]
    for i, p in enumerate(pages_14, 1):
        lines.append(f"### Page {i}\n")
        lines.append(f"【画面描述】{p['desc']}\n")
        lines.append(f"【文字】{p['text']}\n")
        lines.append(f"【拼音】{p['pinyin']}\n")
        lines.append(f"【新字】{p['chars']}\n")
        lines.append("")
    return '\n'.join(lines)

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    pages_raw = extract_pages(content)
    print(f"  {filepath.name}: 提取{pages_raw}页", end="")
    if len(pages_raw) != 28:
        print(f"  ⚠️ 实际{len(pages_raw)}页，跳过")
        return False

    parsed = [parse_page(p) for p in pages_raw]
    pages_14 = compress_to_14(parsed)
    print(f" → 压缩至{len(pages_14)}页")

    new_section = rebuild_section(pages_14)

    # 找第三节位置
    idx3 = content.find("## 三、故事正文（分页脚本）")
    if idx3 < 0:
        print(f"  ❌ 找不到第三节，跳过")
        return False

    # 找第三节结束位置（下一个## ）
    rest = content[idx3:]
    lines_r = rest.split('\n')
    end_pos = len(rest)
    for i, ln in enumerate(lines_r[1:], 1):
        if ln.startswith('## '):
            # 计算截止位置
            end_pos = 0
            for j in range(i):
                end_pos += len(lines_r[j]) + 1
            break

    new_content = content[:idx3] + new_section + "\n" + content[idx3 + end_pos:]

    # 更新信息表页数
    new_content = re.sub(r'(页数\s*\|\s*)\d+页', r'\g<1>14页', new_content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    return True

def main():
    print("="*60)
    print("L5-085~094 压缩：28页 → 14页")
    print("="*60)
    ok = 0
    for fname in FILES:
        fp = CONTENT_DIR / fname
        if not fp.exists():
            print(f"  ❌ 不存在: {fname}")
            continue
        try:
            r = process_file(fp)
            if r:
                ok += 1
        except Exception as e:
            print(f"  ❌ 错误: {fname} — {e}")
    print(f"\n{'='*60}")
    print(f"完成：{ok}/{len(FILES)} 成功")
    print("="*60)

if __name__ == '__main__':
    main()
