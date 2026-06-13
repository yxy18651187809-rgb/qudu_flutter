#!/usr/bin/env python3
"""
L5-095~104 targeted page adjustment to exactly 14 pages.
Current state after v1 fix:
  L5-095: 16 → need -2 (merge 2 pairs)
  L5-099: 15 → need -1 (merge 1 pair)
  L5-100: 18 → need -4 (merge 4 pairs)
  L5-101: 16 → need -2 (merge 2 pairs)
  L5-102: 16 → need -2 (merge 2 pairs)
  L5-103: 16 → need -2 (merge 2 pairs)
  L5-104: 15 → need -1 (merge 1 pair)
"""
import re
from pathlib import Path

CONTENT_DIR = Path("/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容")


def fix_to_14_pages(filepath):
    """Fix file to exactly 14 pages by merging adjacent pages from the end."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split at story section
    parts = content.split('## 三、故事正文（分页脚本）')
    if len(parts) < 2:
        return False
    before = parts[0]
    after = parts[1]
    
    # Split at post-story
    post_match = re.search(r'(\n## [四五六][、．])', after)
    if post_match:
        story_raw = after[:post_match.start()]
        post_story = after[post_match.start():]
    else:
        story_raw = after
        post_story = ''
    
    # Extract real page blocks
    lines = story_raw.split('\n')
    pages = []
    cur = []
    for line in lines:
        if re.match(r'###\s*Page\s+\d+$', line.strip()):
            if cur:
                pages.append('\n'.join(cur))
            cur = [line]
        elif re.match(r'###\s*Page\s+\S+', line.strip()):
            if cur:
                pages.append('\n'.join(cur))
            cur = [line]
        else:
            cur.append(line)
    if cur:
        pages.append('\n'.join(cur))
    
    current_count = len(pages)
    need_to_remove = current_count - 14
    
    if need_to_remove <= 0:
        # Already at or below 14, just renumber
        pass
    else:
        # Merge pages from the end (merge pairs: last-1+last, then last-3+last-2, etc.)
        # Prefer merging consecutive pages near the end (usually summary/transition pages)
        merged = 0
        while merged < need_to_remove and len(pages) > 14:
            # Find the last pair of pages to merge
            merge_idx = len(pages) - 2  # Merge second-to-last into last
            
            block1 = pages[merge_idx]
            block2 = pages[merge_idx + 1]
            
            def extract_field(block, field):
                for bl in block.split('\n'):
                    if bl.startswith(f'【{field}】'):
                        return bl.replace(f'【{field}】', '').strip()
                return ''
            
            desc1 = extract_field(block1, '画面描述')
            desc2 = extract_field(block2, '画面描述')
            text1 = extract_field(block1, '文字')
            text2 = extract_field(block2, '文字')
            pinyin1 = extract_field(block1, '拼音')
            pinyin2 = extract_field(block2, '拼音')
            chars1 = extract_field(block1, '新字')
            chars2 = extract_field(block2, '新字')
            
            # Clean chars2 trailing 】if present
            chars2 = chars2.rstrip('】')
            
            desc = desc1
            text = text1 + text2
            pinyin = pinyin1 + pinyin2
            
            all_chars = []
            seen = set()
            for c in (chars1 + '、' + chars2).split('、'):
                c = c.strip()
                if c and c not in seen:
                    seen.add(c)
                    all_chars.append(c)
            
            new_block = f"### Page TEMP\n【画面描述】{desc}\n【文字】{text}\n【拼音】{pinyin}\n【新字】{'、'.join(all_chars)}"
            pages[merge_idx] = new_block
            del pages[merge_idx + 1]
            merged += 1
    
    # Renumber pages
    final_blocks = []
    for i, block in enumerate(pages):
        new_block = re.sub(r'###\s*Page\s+\S+', f'### Page {i+1}', block)
        final_blocks.append(new_block)
    
    # Rebuild
    new_story = '\n\n'.join(final_blocks)
    new_content = before + '## 三、故事正文（分页脚本）\n\n' + new_story + '\n' + post_story
    
    # Update page count in info table
    new_content = re.sub(r'(\|\s*页数\s*\|\s*)\d+页', f'\\g<1>14页', new_content)
    
    # Clean delivery confirmation
    new_content = re.sub(
        r'\n---\n\n\*\*教研员交付确认\*\*：.*?交付给team-lead，请审阅\n',
        '\n',
        new_content,
        flags=re.DOTALL
    )
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    # Verify
    actual = sum(1 for line in new_content.split('\n') if re.match(r'###\s*Page\s+\d+$', line.strip()))
    status = "✅" if actual == 14 else "❌"
    return f"{status} {filepath.name}: {current_count}→{actual}页"


def main():
    files = [
        "L5-095_三国故事.md",
        "L5-099_编程的乐趣.md",
        "L5-100_长征路上.md",
        "L5-101_看不见的力量.md",
        "L5-102_我的未来城市.md",
        "L5-103_山海经选读.md",
        "L5-104_成长的意义.md",
    ]
    
    print("=" * 60)
    print("L5-095~104 页面调整至14页")
    print("=" * 60)
    
    for fname in files:
        fp = CONTENT_DIR / fname
        if not fp.exists():
            print(f"  ❌ {fname}: 不存在")
            continue
        result = fix_to_14_pages(fp)
        print(f"  {result}")
    
    # Final check
    print("\n--- 最终验证 ---")
    all_ok = True
    for fname in files:
        fp = CONTENT_DIR / fname
        if fp.exists():
            with open(fp) as f:
                c = f.read()
            count = sum(1 for l in c.split('\n') if re.match(r'###\s*Page\s+\d+$', l.strip()))
            status = "✅" if count == 14 else "❌"
            if count != 14:
                all_ok = False
            print(f"  {status} {fname}: {count}页")
    
    if all_ok:
        print("\n🎉 全部文件已标准化为14页！")


if __name__ == '__main__':
    main()
