#!/usr/bin/env python3
"""修复L4-075~084的缺失章节（四、教育目标 + 五、配套练习）"""
import re
from pathlib import Path

CONTENT_DIR = Path("/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容")

def fix_sections(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Check if already has 四、教育目标 section
    if re.search(r'##\s*四[、．]\s*教育目标', content):
        return f"SKIP: {filepath.name} - 已有四、教育目标"
    
    # Extract education goals from info table or text block
    edu_goals = ""
    # Try to extract from 【教育目标】 block
    edu_block = re.search(r'【教育目标】(.*?)(?=\*\*自检|##\s*六|##\s*五|\Z)', content, re.DOTALL)
    if edu_block:
        edu_goals = edu_block.group(1).strip()
    
    # Extract new chars for exercise generation
    char_section = re.search(r'##\s*二[、．]\s*新字表\s*\n(.*?)(?=\n##\s*三)', content, re.DOTALL)
    sample_chars = []
    if char_section:
        char_text = char_section.group(1)
        # Extract汉字 from the "本课新字" section
        for line in char_text.split('\n'):
            if line.startswith('| ') and '|' in line:
                cells = [c.strip() for c in line.split('|')[1:-1]]
                if cells and cells[0] and len(cells[0]) == 1 and not cells[0] in ('汉', '序'):
                    sample_chars.append({
                        'char': cells[0],
                        'pinyin': cells[1] if len(cells) > 1 else '',
                        'words': cells[4] if len(cells) > 4 else cells[0],
                    })
    
    # Truncate to max needed
    sample_chars = sample_chars[:6]
    
    # Build 四、教育目标
    edu_section = """## 四、教育目标

### 1. 识字目标
"""
    if sample_chars:
        chars_str = '、'.join(c['char'] for c in sample_chars[:4])
        edu_section += f"会认{len(sample_chars)}个生字，会写其中{min(4, len(sample_chars))}字（{chars_str}）\n"
    else:
        edu_section += "会认本课生字，能正确书写\n"
    
    edu_section += """
### 2. 认知目标
通过故事内容理解相关主题知识，拓展认知视野。

### 3. 情感目标
培养对故事主题的兴趣，在阅读中获得情感体验。

### 4. 能力目标
能复述故事大意，表达自己的理解和感受。
"""
    
    # Build 五、配套练习
    if sample_chars:
        ex_lines = ["## 五、配套练习", ""]
        ex_lines.append("### 一、认一认（连线）")
        ex_lines.append("把下面的字和正确的拼音连起来：")
        ex_lines.append("")
        for ch in sample_chars[:4]:
            ex_lines.append(f"| {ch['char']} | — | {ch['pinyin']} |")
        ex_lines.append("")
        ex_lines.append("### 二、选一选")
        ex_lines.append("选出正确的字填空：")
        ex_lines.append("")
        if len(sample_chars) >= 2:
            a, b = sample_chars[0], sample_chars[1]
            ex_lines.append(f"1. 我学会了新___字。（{a['char']} / {b['char']}）")
        if len(sample_chars) >= 4:
            c, d = sample_chars[2], sample_chars[3]
            ex_lines.append(f"2. ___天天气真好！（{c['char']} / {d['char']}）")
        ex_lines.append("")
        ex_lines.append("### 三、写一写")
        ex_lines.append("在田字格中书写以下汉字，每个写3遍：")
        ex_lines.append("")
        write_chars = '、'.join(c['char'] for c in sample_chars[:4])
        ex_lines.append(f"> {write_chars}")
        ex_lines.append("")
        ex_lines.append("### 四、读一读")
        ex_lines.append("大声朗读下列词语：")
        ex_lines.append("")
        word_list = [f"{c['char']}（{c['words']}）" for c in sample_chars[:6]]
        ex_lines.append('、'.join(word_list))
        
        exercise_section = '\n'.join(ex_lines)
    else:
        exercise_section = """## 五、配套练习

### 一、认一认
认读本课生字，说出它们的拼音。

### 二、写一写
在田字格中练习书写本课生字。

### 三、读一读
朗读课文，注意生字的发音。
"""
    
    # Find where to insert sections
    # Remove old 【教育目标】 block and **自检清单**
    content = re.sub(r'\n【教育目标】[\s\S]*?(?=\*\*自检|\n##\s*六|\n##\s*五)', '', content)
    content = re.sub(r'\n\*\*自检清单[\s\S]*?(?=\n##\s*六|\n##\s*五|\Z)', '', content)
    
    # Insert before ## 六、插画需求单 (or before end if no 六)
    ill_match = re.search(r'\n##\s*六[、．]', content)
    if ill_match:
        insert_pos = ill_match.start()
        new_sections = f"\n\n{edu_section}\n\n{exercise_section}\n\n"
        content = content[:insert_pos] + new_sections + content[insert_pos:]
    else:
        content = content.rstrip() + f"\n\n{edu_section}\n\n{exercise_section}\n"
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    return f"DONE: {filepath.name}"


def main():
    for num in range(75, 85):
        matches = list(CONTENT_DIR.glob(f'L4-0{num}_*.md'))
        for fp in matches:
            result = fix_sections(fp)
            print(f"  {result}")

if __name__ == '__main__':
    main()
