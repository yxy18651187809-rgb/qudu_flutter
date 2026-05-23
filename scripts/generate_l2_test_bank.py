#!/usr/bin/env python3
"""
L2绘本测评题库生成器
基于绘本文案的字符表，自动生成每册15-20题的测评题库（初稿）。
"""
import re
import os
import json
from pathlib import Path
from collections import defaultdict

CONTENT_DIR = Path("/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容")
OUTPUT_DIR = CONTENT_DIR

# L2 全局字库（所有L2绘本新字，用于随机干扰项）
L2_GLOBAL_CHARS = set()

def parse_character_table(filepath):
    """从绘本文案中提取新字表"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    chars = []
    in_table = False
    for line in content.split('\n'):
        if '## 新字表' in line:
            in_table = True
            continue
        if in_table:
            # Skip separator lines and empty lines
            if line.startswith('|---') or line.startswith('|:---') or line.startswith('| :---'):
                continue
            if not line.startswith('|'):
                if chars:
                    break
                continue
            cells = [c.strip() for c in line.split('|')[1:-1]]
            # Skip header row
            if len(cells) >= 5 and cells[0] not in ('序号', '汉字', '') and cells[1] != '汉字':
                try:
                    int(cells[0])  # Verify it's a valid row number
                except ValueError:
                    continue
                char = {
                    'char': cells[1] if len(cells) > 1 else '',
                    'pinyin': cells[2] if len(cells) > 2 else '',
                    'strokes': cells[3] if len(cells) > 3 else '',
                    'radical': cells[4] if len(cells) > 4 else '',
                    'words': cells[5] if len(cells) > 5 else '',
                    'type': cells[6] if len(cells) > 6 else '核心',
                }
                if char['char']:
                    chars.append(char)
                    L2_GLOBAL_CHARS.add(char['char'])
    
    return chars


def extract_title(filepath):
    """提取书名"""
    with open(filepath, 'r', encoding='utf-8') as f:
        first_line = f.readline().strip()
    # # 绘本01：《小马的河》
    m = re.search(r'《(.+?)》', first_line)
    return m.group(1) if m else ""


def get_distractor_chars(current_char, book_chars, book_num, count=3):
    """生成干扰项字符列表（同本书+全局随机）"""
    candidates = []
    
    # Priority 1: Same book characters
    for c in book_chars:
        if c['char'] != current_char['char']:
            candidates.append(c['char'])
    
    # Priority 2: Same book, different radical
    same_radical = [c['char'] for c in book_chars 
                    if c['char'] != current_char['char'] and c['radical'] == current_char['radical']]
    diff_radical = [c['char'] for c in book_chars 
                    if c['char'] != current_char['char'] and c['radical'] != current_char['radical']]
    
    result = []
    # 1 same-radical distractor
    if same_radical:
        result.append(same_radical[0])
    else:
        result.append(candidates[0] if candidates else "大")
    
    # 2 different-radical from same book
    for c in diff_radical:
        if c not in result and len(result) < count:
            result.append(c)
    
    # Fill remaining with random L2 chars
    all_others = list(L2_GLOBAL_CHARS - {current_char['char']} - set(result))
    import random
    random.shuffle(all_others)
    for c in all_others:
        if len(result) >= count:
            break
        if c not in result:
            result.append(c)
    
    return result[:count]


def generate_recognize_questions(chars, book_chars, book_num):
    """生成看字选图题目"""
    questions = []
    # Pick 5 chars (prefer concrete nouns)
    priority = []
    for c in chars:
        # Simple heuristic: concrete nouns = characters people can draw
        concrete_radicals = {'氵': 'water', '木': 'tree', '牛': 'animal', '马': 'animal',
                            '虫': 'insect', '鱼': 'fish', '鸟': 'bird', '日': 'sun',
                            '月': 'moon', '山': 'mountain', '口': 'mouth', '手': 'hand',
                            '目': 'eye', '耳': 'ear', '足': 'foot', '雨': 'rain',
                            '艹': 'plant', '土': 'earth', '火': 'fire'}
        score = 0
        if c['radical'] in concrete_radicals:
            score += 2
        if c['type'] == '核心':
            score += 1
        if int(c['strokes']) <= 10:
            score += 1
        priority.append((score, c))
    
    priority.sort(reverse=True, key=lambda x: x[0])
    selected = [c for _, c in priority[:5]]
    
    for i, c in enumerate(selected, 1):
        distractors = get_distractor_chars(c, book_chars, book_num)
        dist_labels = ['A', 'B', 'C', 'D']
        correct_idx = i % 4  # Rotate correct position
        
        options = []
        for j in range(4):
            if j == correct_idx:
                options.append(('✅ 正确', c['char'], concrete_radicals.get(c['radical'], '')))
            else:
                d_char = distractors[j if j < correct_idx else j-1]
                options.append(('干扰', d_char, ''))
        
        q = f"""#### Q{i:02d} | {c['char']} | {'⭐' if int(c['strokes']) <= 8 else '⭐⭐'}

```
题目：显示大字卡片"{c['char']}"
趣趣："找到这个字对应的图片！"
选项："""
        for j, (opt_type, opt_char, hint) in enumerate(options):
            d_label = dist_labels[j]
            if opt_type == '✅ 正确':
                q += f"\n  {d_label}. [图片:{opt_char}]（正确）"
                correct_answer = d_label
            else:
                q += f"\n  {d_label}. [图片:{opt_char}]（干扰项）"
        
        q += f"""
正确答案：{correct_answer}
干扰策略：同绘本字干扰
```"""
        questions.append(q)
    
    return questions


def generate_meaning_questions(chars, book_chars, book_num):
    """生成选词填空/释义题"""
    questions = []
    selected = chars[:5]  # First 5 chars
    
    import random
    for i, c in enumerate(selected, 1):
        distractors = get_distractor_chars(c, book_chars, book_num)
        correct_idx = i % 4
        
        q = f"""#### Q{i+5:02d} | {c['char']} | ⭐⭐

```
题目：显示大字"{c['char']}"
趣趣："这个字和哪个词有关？"
选项："""
        d_labels = ['A', 'B', 'C', 'D']
        # Generate word options based on character's 组词
        words = c['words'].split('、')
        correct_word = words[0] if words else c['char']
        
        dist_words = []
        for d in distractors:
            for dc in book_chars:
                if dc['char'] == d:
                    dw = dc['words'].split('、')[0] if dc['words'] else d
                    dist_words.append(dw)
                    break
            else:
                dist_words.append(d + '字')
        
        for j in range(4):
            if j == correct_idx:
                q += f"\n  {d_labels[j]}. {correct_word}（正确）"
                correct_answer = d_labels[j]
            else:
                idx = j if j < correct_idx else j-1
                q += f"\n  {d_labels[j]}. {dist_words[idx] if idx < len(dist_words) else '其他'}（干扰项）"
        
        q += f"""
正确答案：{correct_answer}
干扰策略：同绘本字的组词干扰
```"""
        questions.append(q)
    
    return questions


def generate_pinyin_questions(chars, book_chars, book_num):
    """生成拼音配对题"""
    questions = []
    selected = chars[5:10] if len(chars) > 5 else chars[:5]
    
    for i, c in enumerate(selected, 1):
        distractors = get_distractor_chars(c, book_chars, book_num)
        correct_idx = i % 4
        
        # Get wrong pinyins from distractors
        wrong_pinyins = []
        for d in distractors:
            for dc in book_chars:
                if dc['char'] == d:
                    wrong_pinyins.append(dc['pinyin'])
                    break
            else:
                wrong_pinyins.append('?')
        
        q = f"""#### Q{i+10:02d} | {c['char']} | {'⭐' if len(c['pinyin']) <= 5 else '⭐⭐'}

```
题目：显示大字"{c['char']}"
趣趣："这个字读什么？"
选项："""
        d_labels = ['A', 'B', 'C', 'D']
        for j in range(4):
            if j == correct_idx:
                q += f"\n  {d_labels[j]}. {c['pinyin']}（正确）"
                correct_answer = d_labels[j]
            else:
                idx = j if j < correct_idx else j-1
                wp = wrong_pinyins[idx] if idx < len(wrong_pinyins) else '?'
                q += f"\n  {d_labels[j]}. {wp}（干扰项）"
        
        q += f"""
正确答案：{correct_answer}
干扰策略：同绘本字的拼音干扰
```"""
        questions.append(q)
    
    return questions


def generate_test_bank(filepath, book_num):
    """为单本绘本生成完整题库"""
    chars = parse_character_table(filepath)
    title = extract_title(filepath)
    
    if not chars:
        print(f"  ⚠️ No characters found in {filepath}")
        return None
    
    total = len(chars)
    
    # Generate questions
    recognize_qs = generate_recognize_questions(chars, chars, book_num)
    meaning_qs = generate_meaning_questions(chars, chars, book_num)
    pinyin_qs = generate_pinyin_questions(chars, chars, book_num)
    
    all_qs = recognize_qs + meaning_qs + pinyin_qs
    
    # Build output
    lines = []
    lines.append(f"# 测字题库 v1.0 · 绘本{book_num:02d}《{title}》")
    lines.append("")
    lines.append(f"> **绘本编号**：{book_num:02d}")
    lines.append(f"> **绘本名称**：《{title}》")
    lines.append(f"> **新字数量**：{total}字")
    lines.append(f"> **题目数量**：{len(all_qs)}题（recognize × {len(recognize_qs)} + meaning × {len(meaning_qs)} + pinyin × {len(pinyin_qs)}）")
    
    # Calculate difficulty
    avg_strokes = sum(int(c['strokes']) for c in chars) / len(chars)
    difficulty = "⭐⭐ ~ ⭐⭐⭐" if avg_strokes > 9 else "⭐ ~ ⭐⭐"
    lines.append(f"> **难度范围**：{difficulty}")
    lines.append(f"> **创建日期**：2026-05-23")
    lines.append(f"> **创建方式**：AI初稿（待教研员审核）")
    lines.append("")
    lines.append("---")
    lines.append("")
    
    # Character table
    lines.append("## 新字表")
    lines.append("")
    lines.append("| 序号 | 汉字 | 拼音 | 笔画 | 部首 | 组词 | 类型 |")
    lines.append("|:---:|:---:|:---:|:---:|:---:|:---|:---:|")
    for i, c in enumerate(chars, 1):
        lines.append(f"| {i} | {c['char']} | {c['pinyin']} | {c['strokes']} | {c['radical']} | {c['words']} | {c['type']} |")
    lines.append("")
    lines.append("---")
    lines.append("")
    
    # Questions
    lines.append("## 题目列表")
    lines.append("")
    
    lines.append("### 一、看字选图（recognize）× 5题")
    lines.append("")
    lines.append("> **题型说明**：显示汉字，从4张图片中选择正确的一张。")
    lines.append("> **干扰项策略**：同绘本新字 > 同部首/同主题 > 随机L2字")
    lines.append("")
    for q in recognize_qs:
        lines.append(q)
        lines.append("")
    
    lines.append("### 二、释义选择（meaning_select）× 5题")
    lines.append("")
    lines.append("> **题型说明**：显示汉字，选择正确的组词/释义。")
    lines.append("> **干扰项策略**：同绘本字的组词 > 形近字组词 > 随机组词")
    lines.append("")
    for q in meaning_qs:
        lines.append(q)
        lines.append("")
    
    lines.append("### 三、拼音配对（pinyin_match）× 5题")
    lines.append("")
    lines.append("> **题型说明**：显示汉字，选择正确的拼音。")
    lines.append("> **干扰项策略**：同绘本字的拼音 > 声调变体 > 随机拼音")
    lines.append("")
    for q in pinyin_qs:
        lines.append(q)
        lines.append("")
    
    return "\n".join(lines)


def main():
    # Find all generated L2 picture books
    pb_files = sorted(CONTENT_DIR.glob("绘本*-*_L2文案v1.md"))
    
    results = []
    for f in pb_files:
        # Extract book number from filename
        m = re.match(r'绘本(\d+)-', f.name)
        if not m:
            continue
        book_num = int(m.group(1))
        
        print(f"📝 Generating test bank for book {book_num}...")
        output = generate_test_bank(str(f), book_num)
        
        if output:
            out_filename = f"测字题库_v1.0_绘本{book_num:02d}-L2初稿.md"
            out_path = OUTPUT_DIR / out_filename
            with open(out_path, 'w', encoding='utf-8') as f:
                f.write(output)
            print(f"  ✅ {out_filename}")
            results.append(out_filename)
    
    print(f"\n✅ Done! Generated {len(results)} test bank files.")
    return results


if __name__ == "__main__":
    main()
