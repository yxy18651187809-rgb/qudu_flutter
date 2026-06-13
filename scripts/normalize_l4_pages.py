#!/usr/bin/env python3
"""
L4教案页数标准化脚本：全部标准化为14页
- 压缩：合并相邻页（保留四要素）
- 扩展：拆分合并页或插入过渡页
"""
import re
from pathlib import Path

CONTENT_DIR = Path("/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容")
TARGET = 14

def extract_pages(content):
    """提取所有页面内容，返回 [(page_num, block_text), ...]"""
    # Find the story section - flexible end detection
    # Section 三 can end at 四、五、六 or --- or end of file
    story_match = re.search(
        r'(##\s*三[、．][\s\S]*?)(?=\n##\s*(?:四|五|六)[、．]|\n---\s*\n|\n##\s*插画|\Z)',
        content
    )
    if not story_match:
        # Try looser match
        story_match = re.search(r'(##\s*三[、．].*?)(?=\n##\s*(?:四|五|六))', content, re.DOTALL)
    
    if not story_match:
        return [], content, 0, 0
    
    story_section = story_match.group(1)
    pre_story = content[:story_match.start()]
    post_story = content[story_match.end():]
    
    # Split by ### Page markers
    page_blocks = re.split(r'(###\s*Page\s+\d+[-–—\d]*\s*\n)', story_section)
    
    pages = []
    if len(page_blocks) > 1:
        header = page_blocks[0]
        i = 1
        while i < len(page_blocks) - 1:
            marker = page_blocks[i]
            body = page_blocks[i+1]
            num_match = re.search(r'Page\s+(\d+)', marker)
            if num_match:
                pages.append({
                    'num': int(num_match.group(1)),
                    'marker': marker,
                    'body': body.strip(),
                })
            i += 2
    else:
        header = story_section
    
    return pages, pre_story, post_story, header


def merge_two_pages(p1, p2):
    """合并两个相邻页面为一个"""
    # Extract elements from each page
    def extract_elements(body):
        desc = re.search(r'【画面描述】(.*?)(?=\n【|$)', body, re.DOTALL)
        text = re.search(r'【文字】(.*?)(?=\n【|$)', body, re.DOTALL)
        pinyin = re.search(r'【拼音】(.*?)(?=\n【|$)', body, re.DOTALL)
        new_chars = re.search(r'【新字[标注]*】(.*?)(?=\n|$)', body, re.DOTALL)
        return {
            'desc': desc.group(1).strip() if desc else '',
            'text': text.group(1).strip() if text else '',
            'pinyin': pinyin.group(1).strip() if pinyin else '',
            'new_chars': new_chars.group(1).strip() if new_chars else '',
        }
    
    e1 = extract_elements(p1['body'])
    e2 = extract_elements(p2['body'])
    
    # Merge descriptions
    desc = f"{e1['desc']}；{e2['desc']}" if e2['desc'] and e2['desc'] != e1['desc'] else e1['desc']
    
    # Merge text - combine into coherent sentences
    t1 = e1['text'].rstrip('。！？')
    t2 = e2['text']
    text = f"{t1}。{t2}"
    
    # Merge pinyin
    p1_clean = e1['pinyin'].rstrip('。！？')
    p2_clean = e2['pinyin']
    pinyin = f"{p1_clean}。{p2_clean}"
    
    # Merge new chars (deduplicate)
    chars1 = [c.strip() for c in e1['new_chars'].replace('、', '，').replace(',', '，').split('，') if c.strip() and c.strip() != '（复习字）']
    chars2 = [c.strip() for c in e2['new_chars'].replace('、', '，').replace(',', '，').split('，') if c.strip() and c.strip() != '（复习字）']
    all_chars = []
    seen = set()
    for c in chars1 + chars2:
        if c not in seen:
            seen.add(c)
            all_chars.append(c)
    
    char_label = '【新字标注】' if '新字标注' in p1['body'] or '新字标注' in p2['body'] else '【新字】'
    new_chars = '、'.join(all_chars) if all_chars else '（复习字）'
    
    new_body = f"""【画面描述】{desc}
【文字】{text}
【拼音】{pinyin}
{char_label}{new_chars}"""
    
    return {
        'num': p1['num'],
        'marker': p1['marker'],
        'body': new_body,
    }


def compress_pages(pages, target=TARGET):
    """将页面压缩到目标数量。多次尝试直到达标。"""
    current = len(pages)
    to_remove = current - target
    
    # Strategy: merge adjacent pairs, preferring shorter pages
    # Try iteratively until we reach target
    max_iterations = target  # safety limit
    iteration = 0
    
    while len(pages) > target and iteration < max_iterations:
        iteration += 1
        current = len(pages)
        to_remove = current - target
        
        # Build merge candidates
        candidates = []
        for i in range(current - 1):
            p1_len = len(pages[i]['body'])
            p2_len = len(pages[i+1]['body'])
            candidates.append((p1_len + p2_len, i))
        
        candidates.sort()
        
        # Select which pairs to merge (non-overlapping)
        merge_indices = set()
        for _, idx in candidates:
            if len(merge_indices) >= to_remove:
                break
            if idx in merge_indices or (idx - 1) in merge_indices:
                continue
            merge_indices.add(idx)
        
        if not merge_indices:
            # Can't compress further - merge all remaining pages
            break
        
        # Perform merges (from highest index to lowest)
        merged_pages = []
        skip_next = False
        for i in range(current):
            if skip_next:
                skip_next = False
                continue
            if i in merge_indices:
                merged = merge_two_pages(pages[i], pages[i+1])
                merged_pages.append(merged)
                skip_next = True
            else:
                merged_pages.append(pages[i])
        
        pages = merged_pages
    
    return pages


def expand_pages(pages, content, target=TARGET):
    """扩展页面到目标数量 - 拆分合并页或插入过渡页"""
    current = len(pages)
    to_add = target - current
    
    # Check for combined page markers like "Page 11-21"
    combined_pages = []
    normal_pages = []
    for p in pages:
        if '-' in str(p['num']) or '–' in str(p['num']) or '—' in str(p['num']):
            combined_pages.append(p)
        else:
            normal_pages.append(p)
    
    if combined_pages:
        # Split combined page into individual pages
        new_pages = list(normal_pages)
        for cp in combined_pages:
            # Extract the range
            nums = re.findall(r'\d+', str(cp['num']))
            if len(nums) >= 2:
                start, end = int(nums[0]), int(nums[-1])
                # Unpack the combined description into brief pages
                desc = re.search(r'【画面描述】(.*?)(?=\n【|$)', cp['body'], re.DOTALL)
                text = re.search(r'【文字】(.*?)(?=\n【|$)', cp['body'], re.DOTALL)
                pinyin = re.search(r'【拼音】(.*?)(?=\n【|$)', cp['body'], re.DOTALL)
                new_chars_match = re.search(r'【新字[标注]*】(.*?)(?=\n|$)', cp['body'], re.DOTALL)
                
                desc_text = desc.group(1).strip() if desc else ''
                body_text = text.group(1).strip() if text else ''
                pinyin_text = pinyin.group(1).strip() if pinyin else ''
                new_chars_text = new_chars_match.group(1).strip() if new_chars_match else ''
                
                # Create individual pages for the range
                pages_needed = min(end - start + 1, target - len(new_pages))
                for j in range(pages_needed):
                    page_num = start + j
                    if j == 0:
                        pb = cp['body']
                    else:
                        char_label = '【新字标注】' if '新字标注' in cp['body'] else '【新字】'
                        pb = f"""【画面描述】{desc_text}
【文字】（续）{body_text}
【拼音】{pinyin_text}
{char_label}"""
                    new_pages.append({
                        'num': page_num,
                        'marker': f'### Page {page_num}\n',
                        'body': pb.strip(),
                    })
                
                if len(new_pages) >= target:
                    break
        
        return new_pages[:target]
    
    # No combined pages - insert transition pages
    new_pages = list(normal_pages)
    insert_positions = []
    step = len(normal_pages) // (to_add + 1)
    for i in range(1, to_add + 1):
        insert_positions.append(i * step)
    
    offset = 0
    for pos in sorted(insert_positions):
        actual_pos = min(pos + offset, len(new_pages))
        # Get context from before and after
        prev_page = new_pages[actual_pos - 1] if actual_pos > 0 else None
        next_page = new_pages[actual_pos] if actual_pos < len(new_pages) else None
        
        prev_text = ''
        if prev_page:
            tm = re.search(r'【文字】(.*?)(?=\n【|$)', prev_page['body'], re.DOTALL)
            prev_text = tm.group(1).strip() if tm else ''
        
        next_text = ''
        if next_page:
            tm = re.search(r'【文字】(.*?)(?=\n【|$)', next_page['body'], re.DOTALL)
            next_text = tm.group(1).strip() if tm else ''
        
        char_label = '【新字标注】' if prev_page and '新字标注' in prev_page['body'] else '【新字】'
        
        transition = f"""【画面描述】故事情节推进。
【文字】接着，故事继续发展……
【拼音】jiē zhe，gù shì jì xù fā zhǎn……
{char_label}"""
        
        new_pages.insert(actual_pos, {
            'num': 0,  # Will be renumbered
            'marker': '### Page X\n',
            'body': transition,
        })
        offset += 1
    
    return new_pages


def rebuild_file(pre_story, pages, post_story, header):
    """用标准化后的页面重建文件"""
    story_lines = [header.rstrip()]
    
    for i, p in enumerate(pages):
        page_num = i + 1
        marker = f'### Page {page_num}'
        story_lines.append(f'\n{marker}')
        story_lines.append(p['body'])
    
    new_story = '\n'.join(story_lines) + '\n'
    
    # Update page count in info table
    content = pre_story + new_story + post_story
    content = re.sub(
        r'(页数\s*\|\s*)\d+页',
        f'\\g<1>{TARGET}页',
        content
    )
    
    return content


def normalize_file(filepath):
    """标准化单个文件"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    pages, pre, post, header = extract_pages(content)
    
    if not pages:
        return f"SKIP: {filepath.name} - 无页面"
    
    current = len(pages)
    
    if current == TARGET:
        return f"SKIP: {filepath.name} - 已14页"
    
    if current > TARGET:
        pages = compress_pages(pages, TARGET)
    else:
        pages = expand_pages(pages, content, TARGET)
    
    new_content = rebuild_file(pre, pages, post, header)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    return f"DONE: {filepath.name} | {current}→{len(pages)}页"


def main():
    all_files = sorted(CONTENT_DIR.glob('L4-0*.md'))
    files = [f for f in all_files if '插画需求' not in f.name and '审核' not in f.name and '创作规范' not in f.name]
    
    results = []
    for fp in files:
        result = normalize_file(fp)
        results.append(result)
        print(f"  {result}")
    
    done = sum(1 for r in results if r.startswith('DONE'))
    skip = sum(1 for r in results if r.startswith('SKIP'))
    print(f"\n处理完成: {done}篇修改 / {skip}篇跳过 / 总计{len(results)}篇")
    
    # Verify
    print("\n--- 验证 ---")
    for fp in files:
        with open(fp, 'r') as f:
            content = f.read()
        pages = len(re.findall(r'###\s*Page\s+\d+\s*\n', content))
        name = fp.name
        status = '✅' if pages == TARGET else f'❌ {pages}页'
        print(f"  {status} {name}")

if __name__ == '__main__':
    main()
