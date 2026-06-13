#!/usr/bin/env python3
"""
L4+L5教案实际修复脚本（Phase 1: 字数表+练习生成）
运行此脚本修改40个教案文件：拆分新字/复习字表 + 生成配套练习

用法：python3 scripts/apply_fix_l4l5.py
"""
import re
import sys
import json
from pathlib import Path

CONTENT_DIR = Path("/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容")
TARGET_NEW_CHARS = 22
TARGET_PAGES = 14

def parse_char_table(content):
    """解析新字表，返回字符列表"""
    chars = []
    lines = content.split('\n')
    in_table = False
    header_seen = False
    sep_seen = False
    
    for line in lines:
        if re.search(r'##\s*二[、．]\s*新字表', line):
            in_table = True
            continue
        if not in_table:
            continue
        
        if '|' in line and ('汉字' in line or '序号' in line) and not header_seen:
            header_seen = True
            continue
        if line.strip().startswith('|---') or line.strip().startswith('|:-'):
            sep_seen = True
            continue
        
        if not line.startswith('|'):
            if header_seen and sep_seen:
                break
            continue
        
        cells = [c.strip() for c in line.split('|')[1:-1]]
        if len(cells) < 5:
            continue
        
        char_text = cells[0].strip() if cells[0] else cells[1].strip() if len(cells) > 1 else ''
        if not char_text or char_text in ('汉字', '序号') or len(char_text) > 2:
            continue
        
        note = cells[-1].strip() if len(cells) > 6 else ''
        is_review = bool(re.search(r'复习|已学|L[1-4]', note))
        is_core = '是' in cells[5].strip() if len(cells) > 5 else False
        
        chars.append({
            'char': char_text,
            'pinyin': cells[1] if len(cells) > 1 else '',
            'strokes': cells[2] if len(cells) > 2 else '',
            'radical': cells[3] if len(cells) > 3 else '',
            'words': cells[4] if len(cells) > 4 else '',
            'is_core': is_core,
            'is_review': is_review,
            'note': note,
        })
    
    return chars


def classify_chars(chars, level):
    """分类：新字（优先核心+非复习）vs 复习区"""
    # 真正新字：非复习 且 核心
    new_core = [c for c in chars if not c['is_review'] and c['is_core']]
    # 非核心新字
    new_noncore = [c for c in chars if not c['is_review'] and not c['is_core']]
    
    # 去重（按汉字）
    seen = set()
    new_all = []
    for c in new_core + new_noncore:
        if c['char'] not in seen:
            seen.add(c['char'])
            new_all.append(c)
    
    new_chars = new_all[:TARGET_NEW_CHARS]
    
    # 其余全部进复习区（去重）
    new_char_texts = {c['char'] for c in new_chars}
    review_chars = []
    seen_review = set()
    for c in chars:
        if c['char'] not in new_char_texts and c['char'] not in seen_review:
            seen_review.add(c['char'])
            review_chars.append(c)
    
    return new_chars, review_chars


def build_char_table(new_chars, review_chars, level):
    """构建拆分后的字表Markdown"""
    core_label = f"是否L{level}核心"
    lines = []
    
    # 新字部分
    lines.append(f"**本课新字：{len(new_chars)}字**（核心{sum(1 for c in new_chars if c['is_core'])} + 扩展{sum(1 for c in new_chars if not c['is_core'])}）")
    lines.append("")
    lines.append(f"| 汉字 | 拼音 | 笔画 | 部首 | 组词示例 | {core_label} | 备注 |")
    lines.append("|------|------|------|------|----------|------------|------|")
    
    for c in new_chars:
        core = '是' if c['is_core'] else '否'
        note = c['note']
        # 清理备注中的复习标记
        note = re.sub(r'（复习字.*?）', '', note)
        note = re.sub(r'复习字.*', '', note).strip()
        lines.append(f"| {c['char']} | {c['pinyin']} | {c['strokes']} | {c['radical']} | {c['words']} | {core} | {note} |")
    
    # 复习巩固部分
    if review_chars:
        lines.append("")
        lines.append(f"**复习巩固字：{len(review_chars)}字**（已学复习{sum(1 for c in review_chars if c['is_review'])} + 超纲/待学{sum(1 for c in review_chars if not c['is_review'])}）")
        lines.append("")
        lines.append(f"| 汉字 | 拼音 | 笔画 | 部首 | 组词示例 | {core_label} | 备注 |")
        lines.append("|------|------|------|------|----------|------------|------|")
        
        for c in review_chars:
            core = '是' if c['is_core'] else '否'
            note = c['note'] or ''
            if c['is_review'] and '复习' not in note:
                note = '复习字' if not note else note + '（复习字）'
            lines.append(f"| {c['char']} | {c['pinyin']} | {c['strokes']} | {c['radical']} | {c['words']} | {core} | {note} |")
    
    return '\n'.join(lines)


def generate_exercises(new_chars, title, level):
    """生成配套练习"""
    sample = new_chars[:min(6, len(new_chars))]
    
    parts = []
    parts.append("## 五、配套练习")
    parts.append("")
    parts.append("### 一、认一认（连线）")
    parts.append("把下面的字和正确的拼音连起来：")
    parts.append("")
    for ch in sample[:4]:
        parts.append(f"| {ch['char']} | — | {ch['pinyin']} |")
    parts.append("")
    
    parts.append("### 二、选一选")
    parts.append("选出正确的字填空：")
    parts.append("")
    if len(sample) >= 3:
        a, b = sample[0], sample[1]
        parts.append(f"1. 我学会了新___字。（{a['char']} / {b['char']}）")
    if len(sample) >= 4:
        c, d = sample[2], sample[3]
        parts.append(f"2. ___天天气真好！（{c['char']} / {d['char']}）")
    parts.append("")
    
    parts.append("### 三、写一写")
    parts.append("在田字格中书写以下汉字，每个写3遍：")
    parts.append("")
    write_chars = '、'.join(c['char'] for c in sample[:4])
    parts.append(f"> {write_chars}")
    parts.append("")
    
    parts.append("### 四、读一读")
    parts.append("大声朗读下列词语：")
    parts.append("")
    word_list = [f"{c['char']}（{c['words']}）" for c in new_chars[:8]]
    parts.append('、'.join(word_list))
    parts.append("")
    
    return '\n'.join(parts)


def fix_file(filepath):
    """修复单个文件"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    level_match = re.search(r'L([45])', filepath.name)
    level = int(level_match.group(1)) if level_match else 4
    
    # 1. 解析字表
    chars = parse_char_table(content)
    if not chars:
        return f"FAIL: {filepath.name} - 字表解析失败"
    
    new_chars, review_chars = classify_chars(chars, level)
    
    # 2. 替换字表
    old_table_pattern = re.compile(
        r'(##\s*二[、．]\s*新字表\s*\n)([\s\S]*?)(?=\n##\s*三[、．])', re.MULTILINE
    )
    new_table = build_char_table(new_chars, review_chars, level)
    
    match = old_table_pattern.search(content)
    if not match:
        return f"FAIL: {filepath.name} - 找不到新字表位置"
    
    content = content[:match.start()] + f"## 二、新字表\n\n{new_table}\n\n" + content[match.end():]
    
    # 3. 更新信息表中的字数
    core_n = sum(1 for c in new_chars if c["is_core"])
    ext_n = sum(1 for c in new_chars if not c["is_core"])
    # 用更精确的匹配：找到含有"新字数"的行并整行替换
    lines = content.split('\n')
    new_lines = []
    for line in lines:
        if '新字数' in line and '|' in line:
            line = f'| 新字数 | {len(new_chars)}字（核心{core_n}+扩展{ext_n}）|'
        new_lines.append(line)
    content = '\n'.join(new_lines)
    
    # 4. 补充/替换 配套练习
    has_exercise = bool(re.search(r'##\s*五[、．]\s*配套练习', content))
    title = filepath.stem.replace('_', ' ')
    
    exercise_content = generate_exercises(new_chars, title, level)
    
    if has_exercise:
        # 替换已有练习
        old_exercise_pattern = re.compile(
            r'##\s*五[、．]\s*配套练习[\s\S]*?(?=\n##\s*六[、．]|\n---\s*\n|\Z)', re.MULTILINE
        )
        content = old_exercise_pattern.sub(exercise_content, content)
    else:
        # 在四、教育目标之后插入
        edu_end_match = re.search(r'(##\s*四[、．][\s\S]*?)(?=\n##\s*六|\n---\s*\n|\Z)', content, re.MULTILINE)
        if edu_end_match:
            insert_pos = edu_end_match.end()
            content = content[:insert_pos] + '\n\n' + exercise_content + '\n' + content[insert_pos:]
    
    # 5. 检查/补充 六、插画需求单
    has_illustration = bool(re.search(r'##\s*六[、．]\s*插画需求', content))
    if not has_illustration:
        illustration = f"""## 六、插画需求单

> 📝 本文档已由 `插画需求单_L{level}_第{filepath.name[:7]}.md` 统一定义，此处保留章节占位，详细分镜请参阅独立需求单文件。
> 基础信息：{len(new_chars)}个新字，{TARGET_PAGES}页绘本脚本，{level}级适配7-{'10' if level==5 else '8'}岁儿童。

"""
        content = content.rstrip() + '\n\n' + illustration
    
    # 写回文件
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return f"OK: {filepath.name} | 新字{len(new_chars)} | 复习{len(review_chars)} | 练习{'✓替换' if has_exercise else '✓新增'} | 插画{'✓已有' if has_illustration else '✓新增'}"


def main():
    results = []
    
    patterns = [
        (4, 'L4-0*.md'),
        (5, 'L5-08*.md'),
        (5, 'L5-09*.md'),
        (5, 'L5-10*.md'),
    ]
    seen = set()
    for level, pat in patterns:
        files = sorted(CONTENT_DIR.glob(pat))
        for fp in files:
            if fp.name in seen:
                continue
            seen.add(fp.name)
        for fp in files:
            if '插画需求' in fp.name or '审核' in fp.name or '创作规范' in fp.name or 'fix' in fp.name:
                continue
            result = fix_file(fp)
            results.append(result)
            print(f"  {result}")
    
    ok = sum(1 for r in results if r.startswith('OK'))
    fail = len(results) - ok
    print(f"\n{'='*60}")
    print(f"修复完成：{ok}成功 / {fail}失败 / {len(results)}总计")
    
    return results

if __name__ == '__main__':
    main()
