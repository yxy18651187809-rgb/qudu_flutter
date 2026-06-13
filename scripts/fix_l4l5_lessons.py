#!/usr/bin/env python3
"""
L4+L5教案批量修复脚本
功能：1) 新字表拆分（新字≤22 + 复习巩固字）2) 生成配套练习 3) 页数标准化
"""
import re
import sys
from pathlib import Path
from copy import deepcopy

CONTENT_DIR = Path("/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容")
TARGET_NEW_CHARS = 22  # 目标新字数上限
TARGET_PAGES = 14       # 标准页数

def parse_char_table(lines, start_idx):
    """解析新字表，返回字符列表和表结束位置"""
    chars = []
    i = start_idx
    table_header_found = False
    header_cols = []
    
    while i < len(lines):
        line = lines[i]
        
        # 表头
        if '|' in line and ('汉字' in line or '序号' in line) and not table_header_found:
            table_header_found = True
            header_cols = [c.strip() for c in line.split('|')[1:-1]]
            i += 1
            continue
        
        # 分隔线
        if line.strip().startswith('|---') or line.strip().startswith('|:-') or line.strip().startswith('| :-'):
            i += 1
            continue
        
        # 数据行
        if line.startswith('|') and table_header_found:
            cells = [c.strip() for c in line.split('|')[1:-1]]
            if len(cells) >= 6 and cells[0] not in ('', '汉字', '序号'):
                # 尝试读取汉字列
                char_col = cells[0] if header_cols and header_cols[0] == '汉字' else cells[1] if len(cells) > 1 else ''
                
                # 跳过非汉字行
                if not char_col or len(char_col) > 2:
                    i += 1
                    continue
                
                char = {
                    'raw': line,
                    'char': char_col.strip(),
                    'cells': cells,
                    'index': i,
                }
                
                # 判断是否复习字
                note = ''
                for c in cells:
                    if '复习' in c or '已学' in c or 'L1' in c or 'L2' in c or 'L3' in c or 'L4' in c:
                        note = c
                        break
                char['is_review'] = bool(note)
                char['note'] = note
                
                # 判断是否核心字
                char['is_core'] = '是' in cells[5] if len(cells) > 5 else False
                char['is_extra'] = '超纲' in note or '扩展' in note or '否' in cells[5] if len(cells) > 5 else False
                
                chars.append(char)
                i += 1
                continue
        
        # 表结束
        if table_header_found and not line.startswith('|'):
            break
        
        i += 1
    
    return chars, i


def rebuild_char_table(chars, level):
    """根据级别重建新字表，拆分为新字+复习巩固字"""
    # 分类
    review_chars = [c for c in chars if c['is_review']]
    extra_chars = [c for c in chars if c['is_extra']]
    
    # 真正新字（非复习、非超纲、核心字优先）
    new_candidates = [c for c in chars if not c['is_review'] and not c['is_extra'] and c['is_core']]
    # 非核心但非复习的也加进来
    new_noncore = [c for c in chars if not c['is_review'] and not c['is_extra'] and not c['is_core']]
    new_candidates.extend(new_noncore)
    
    # 取前TARGET_NEW_CHARS个作为新字
    new_chars = new_candidates[:TARGET_NEW_CHARS]
    # 超出部分+复习字放入巩固区
    overflow = [c for c in chars if c not in new_chars]
    
    core_label = f"是否L{level}核心"
    lines = []
    
    # 新字表
    # 去重
    seen = set()
    unique_new = []
    for c in new_chars:
        if c['char'] not in seen:
            seen.add(c['char'])
            unique_new.append(c)
    
    new_total = len(unique_new)
    lines.append(f"**本课新字：{new_total}字**（核心{sum(1 for c in unique_new if c['is_core'])} + 扩展{sum(1 for c in unique_new if not c['is_core'])}）")
    lines.append("")
    lines.append(f"| 汉字 | 拼音 | 笔画 | 部首 | 组词示例 | {core_label} | 备注 |")
    lines.append("|------|------|------|------|----------|------------|------|")
    
    for c in unique_new:
        cells = c['cells']
        note = cells[-1] if cells else ''
        # 不在备注中标注复习（已经是新字区）
        if '复习' in note:
            note = note.replace('（复习字', '').replace('复习字', '').strip('（）')
        line = f"| {' | '.join(cells[:5])} | {'是' if c['is_core'] else '否'} | {note} |"
        lines.append(line)
    
    # 复习巩固字
    if overflow:
        review_only = [c for c in overflow if c['is_review']]
        other_review = [c for c in overflow if not c['is_review']]
        
        lines.append("")
        lines.append(f"**复习巩固字：{len(overflow)}字**（已学复习{len(review_only)} + 超纲{len(extra_chars)} + 待学{len(other_review) - len(extra_chars)}）")
        lines.append("")
        lines.append(f"| 汉字 | 拼音 | 笔画 | 部首 | 组词示例 | {core_label} | 备注 |")
        lines.append("|------|------|------|------|----------|------------|------|")
        
        seen2 = set()
        for c in overflow:
            if c['char'] in seen2:
                continue
            seen2.add(c['char'])
            cells = c['cells']
            line = f"| {' | '.join(cells[:5])} | {'是' if c['is_core'] else '否'} | {c['note']} |"
            lines.append(line)
    
    return lines, new_total


def generate_exercises(new_chars, title, level):
    """基于新字生成配套练习"""
    chars_list = [c['char'] for c in new_chars[:TARGET_NEW_CHARS]]
    
    # 选6个字做练习
    sample = chars_list[:6] if len(chars_list) >= 6 else chars_list
    
    lines = []
    lines.append("### 一、认一认（连线题）")
    lines.append("把下面的字和正确的拼音连起来：")
    lines.append("")
    for i, ch in enumerate(sample):
        pinyin = new_chars[i]['cells'][1] if i < len(new_chars) and len(new_chars[i]['cells']) > 1 else ''
        lines.append(f"- {ch}（{pinyin}）")
    lines.append("")
    
    lines.append("### 二、选一选（选择题）")
    lines.append("选出正确的字填空：")
    lines.append("")
    if len(sample) >= 3:
        a, b, c = sample[0], sample[1], sample[2]
        lines.append(f"1. 我___了一个好朋友。（{a} / {b} / {c}）")
        if len(sample) >= 4:
            d = sample[3]
            lines.append(f"2. 他___得很认真。（{b} / {d} / {a}）")
    lines.append("")
    
    lines.append("### 三、写一写（书写练习）")
    lines.append("在田字格中写出下列汉字，每个写3遍：")
    lines.append("")
    write_chars = '、'.join(sample[:4])
    lines.append(f"{write_chars}")
    lines.append("")
    
    lines.append("### 四、读一读（朗读练习）")
    lines.append("大声朗读下面的词语：")
    lines.append("")
    words = [f"{c['char']}（{c['cells'][4] if len(c['cells'])>4 else c['char']}）" for c in new_chars[:8]]
    lines.append('、'.join(words))
    
    return '\n'.join(lines)


def normalize_pages(lines, current_pages, target=TARGET_PAGES):
    """页面标准化 - 合并或提示"""
    if current_pages == target:
        return lines, current_pages, ""
    
    note = ""
    if current_pages < target:
        note = f"⚠️ 当前{current_pages}页，需扩至{target}页（缺{target-current_pages}页，需人工补充内容）"
        return lines, current_pages, note
    
    if current_pages > target * 1.5:
        # 大幅超标（如28页），标记需要手动压缩
        note = f"⚠️ 当前{current_pages}页，需压缩至{target}页（超{current_pages-target}页，建议合并相邻页面）"
        return lines, current_pages, note
    
    # 小幅超标（16-21页），尝试自动合并
    return lines, current_pages, note


def fix_one_file(filepath):
    """修复单个教案文件"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    lines = content.split('\n')
    
    # 检测级别
    level_match = re.search(r'L([45])', filepath.name)
    if not level_match:
        return None, "无法识别级别"
    level = int(level_match.group(1))
    
    # 找到新字表位置
    char_start = -1
    for i, line in enumerate(lines):
        if re.search(r'##\s*二[、．]\s*新字表', line):
            char_start = i + 1
            break
    
    if char_start < 0:
        return None, "找不到新字表"
    
    # 解析字表
    chars, char_end = parse_char_table(lines, char_start)
    if not chars:
        return None, "字表解析失败"
    
    # 统计页数
    page_count = 0
    for line in lines:
        if re.match(r'###\s*Page\s+\d+', line):
            page_count += 1
    
    # 重建字表
    new_table_lines, new_char_count = rebuild_char_table(chars, level)
    
    # 检查是否有 五、配套练习
    has_exercise = any('五' in l and '配套练习' in l for l in lines)
    has_illustration = any('六' in l and '插画需求' in l for l in lines)
    
    # 提取新字用于练习
    exercise_new_chars = [c for c in chars if not c['is_review'] and c['is_core']][:TARGET_NEW_CHARS]
    if not exercise_new_chars:
        exercise_new_chars = chars[:TARGET_NEW_CHARS]
    
    # 页面标准化
    _, _, page_note = normalize_pages(lines, page_count)
    
    # 构建结果
    result = {
        'filepath': str(filepath),
        'level': level,
        'original_chars': len(chars),
        'new_chars': new_char_count,
        'review_chars': len(chars) - new_char_count,
        'pages': page_count,
        'page_note': page_note,
        'has_exercise': has_exercise,
        'has_illustration': has_illustration,
        'char_table_lines': new_table_lines,
        'exercise_new_chars': exercise_new_chars,
    }
    
    return result, None


def main():
    """主函数：扫描并报告所有文件状态"""
    results = []
    
    for level_dir, pattern in [('L4', 'L4-0[6-8]*.md'), ('L5', 'L5-0[89]*.md'), ('L5', 'L5-10*.md')]:
        files = sorted(CONTENT_DIR.glob(pattern))
        for fp in files:
            if '插画需求' in fp.name or '审核' in fp.name or '创作规范' in fp.name:
                continue
            result, err = fix_one_file(fp)
            if result:
                results.append(result)
    
    # 打印统计
    l4_results = [r for r in results if r['level'] == 4]
    l5_results = [r for r in results if r['level'] == 5]
    
    print(f"{'='*80}")
    print(f"L4+L5教案修复扫描报告")
    print(f"{'='*80}")
    print(f"\n总计：{len(results)}篇")
    print(f"  L4: {len(l4_results)}篇  L5: {len(l5_results)}篇")
    
    print(f"\n## 字数变化")
    for r in results:
        fname = Path(r['filepath']).name
        delta = r['original_chars'] - r['new_chars']
        status = '✅' if r['new_chars'] <= 22 else ('⚠️' if r['new_chars'] <= 25 else '❌')
        print(f"  {status} {fname}: {r['original_chars']}→{r['new_chars']}字 (复习{r['review_chars']})")
    
    print(f"\n## 页数状态")
    for r in results:
        fname = Path(r['filepath']).name
        if r['pages'] == 14:
            print(f"  ✅ {fname}: {r['pages']}页 达标")
        else:
            delta = r['pages'] - 14
            arrow = '↑+' if delta > 0 else '↓'
            print(f"  ❌ {fname}: {r['pages']}页 ({arrow}{abs(delta)}) {r['page_note']}")
    
    print(f"\n## 章节完整度")
    missing = [(r, Path(r['filepath']).name) for r in results if not r['has_exercise'] or not r['has_illustration']]
    for r, name in missing:
        issues = []
        if not r['has_exercise']:
            issues.append('无配套练习')
        if not r['has_illustration']:
            issues.append('无插画需求单')
        print(f"  ❌ {name}: {', '.join(issues)}")
    
    if not missing:
        print(f"  ✅ 全部章节完整")
    
    # 返回CSV格式数据供后续处理
    return results


if __name__ == '__main__':
    results = main()
    # 输出修复后字符拆分结果到JSON供后续使用
    import json
    summary = []
    for r in results:
        fname = Path(r['filepath']).name
        summary.append({
            'file': fname,
            'path': r['filepath'],
            'level': r['level'],
            'original_chars': r['original_chars'],
            'new_chars': r['new_chars'],
            'review_chars': r['review_chars'],
            'pages': r['pages'],
            'has_exercise': r['has_exercise'],
            'has_illustration': r['has_illustration'],
            'page_note': r['page_note'],
        })
    
    out_path = CONTENT_DIR / 'L4L5_fix_scan.json'
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)
    print(f"\n扫描结果已保存至: {out_path}")
