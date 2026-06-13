#!/usr/bin/env python3
"""
L5-095~104: All files now have 13 pages, need exactly 14.
Strategy: insert 1 transition page at a strategic point in each file.
"""
import re
from pathlib import Path

CONTENT_DIR = Path("/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容")

# Insertion points and content for each file
INSERTIONS = {
    "L5-095_三国故事.md": (7, "诸葛亮在城墙上弹琴，司马懿的军队远远看着，不敢进攻。",
        "zhū gě liàng zài chéng qiáng shàng tán qín，sī mǎ yì de jūn duì yuǎn yuǎn kàn zhe，bù gǎn jìn gōng。",
        "城、墙、远"),
    "L5-099_编程的乐趣.md": (13, "小明把游戏展示给同学们看，大家都很喜欢。",
        "xiǎo míng bǎ yóu xì zhǎn shì gěi tóng xué men kàn，dà jiā dōu hěn xǐ huān。",
        "展、示、大"),
    "L5-100_长征路上.md": (5, "红军过草地的时候，沼泽很深，每一步都要小心。",
        "hóng jūn guò cǎo dì de shí hou，zhǎo zé hěn shēn，měi yī bù dōu yào xiǎo xīn。",
        "每、一、步、小、心"),
    "L5-101_看不见的力量.md": (4, "地球的重力让苹果落地，也让月亮绕着地球转。",
        "dì qiú de zhòng lì ràng píng guǒ luò dì，yě ràng yuè liàng rào zhe dì qiú zhuàn。",
        "让、月、亮、绕、转"),
    "L5-102_我的未来城市.md": (7, "未来城市的公园里有很多花草，空气很清新。",
        "wèi lái chéng shì de gōng yuán lǐ yǒu hěn duō huā cǎo，kōng qì hěn qīng xīn。",
        "空、气、清、新"),
    "L5-103_山海经选读.md": (6, "夸父追日的故事告诉我们：做事要有毅力，不怕困难。",
        "kuā fù zhuī rì de gù shì gào sù wǒ men：zuò shì yào yǒu yì lì，bù pà kùn nán。",
        "做、事、意、力"),
    "L5-104_成长的意义.md": (7, "小明翻开日记本，一页一页地看，每一页都写满了回忆。",
        "xiǎo míng fān kāi rì jì běn，yī yè yī yè dì kàn，měi yī yè dōu xiě mǎn le huí yì。",
        "翻、开、每、满"),
}


def insert_page_at(filepath, after_page_num, text, pinyin, new_chars):
    """Insert a new page after the specified page number, renumber all subsequent pages."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split at story section
    parts = content.split('## 三、故事正文（分页脚本）')
    if len(parts) < 2:
        return False
    before = parts[0]
    after = parts[1]
    
    post_match = re.search(r'(\n## [四五六][、．])', after)
    if post_match:
        story_raw = after[:post_match.start()]
        post_story = after[post_match.start():]
    else:
        story_raw = after
        post_story = ''
    
    # Split into individual page blocks
    page_blocks = re.split(r'(\n###\s*Page\s+\d+\s*\n)', story_raw)
    # page_blocks alternates: [preamble, page_header1, content1, page_header2, content2, ...]
    
    # Reassemble into (num, full_block) pairs
    pages = []
    i = 0
    if page_blocks and page_blocks[0].strip():
        # There's preamble text before first page
        pages.append((0, page_blocks[0]))  # preamble (num=0 means no page)
        i = 1
    
    while i < len(page_blocks) - 1:
        header = page_blocks[i]
        body = page_blocks[i + 1]
        num_match = re.search(r'Page\s+(\d+)', header)
        num = int(num_match.group(1)) if num_match else 0
        pages.append((num, header + body))
        i += 2
    
    # Find insertion point
    insert_idx = None
    for idx, (num, _) in enumerate(pages):
        if num == after_page_num:
            insert_idx = idx
            break
    
    if insert_idx is None:
        # Fallback: insert at position after_page_num (1-indexed from real pages)
        real_pages = [(num, block) for num, block in pages if num > 0]
        if after_page_num <= len(real_pages):
            insert_idx = after_page_num  # approximately
        else:
            insert_idx = len(pages) - 1
    
    # Get context for 画面描述 from the page before insertion
    _, before_block = pages[insert_idx]
    desc_line = ""
    for line in before_block.split('\n'):
        if line.startswith('【画面描述】'):
            desc_line = line
            break
    
    # Build new page block
    new_page = f"\n### Page TEMP\n【画面描述】{text[:30]}小明认真思考。\n【文字】{text}\n【拼音】{pinyin}\n【新字】{new_chars}\n"
    
    # Insert
    pages.insert(insert_idx + 1, (9999, new_page))
    
    # Renumber all real pages
    real_num = 1
    new_blocks = []
    for num, block in pages:
        if num == 0:
            new_blocks.append(block)
        else:
            new_block = re.sub(r'###\s*Page\s+\S+', f'### Page {real_num}', block)
            new_blocks.append(new_block)
            real_num += 1
    
    # Rebuild
    new_story = ''.join(new_blocks)
    new_content = before + '## 三、故事正文（分页脚本）' + new_story + post_story
    
    # Update page count
    new_content = re.sub(r'(\|\s*页数\s*\|\s*)\d+页', f'\\g<1>14页', new_content)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    # Verify
    actual = sum(1 for l in new_content.split('\n') if re.match(r'###\s*Page\s+\d+$', l.strip()))
    return actual == 14


def main():
    print("=" * 60)
    print("L5-095~104: 插入页面至14页")
    print("=" * 60)
    
    all_ok = True
    for fname, (after, text, pinyin, chars) in INSERTIONS.items():
        fp = CONTENT_DIR / fname
        if not fp.exists():
            print(f"  ❌ {fname}: 不存在")
            continue
        ok = insert_page_at(fp, after, text, pinyin, chars)
        actual = sum(1 for l in open(fp).read().split('\n') if re.match(r'###\s*Page\s+\d+$', l.strip()))
        status = "✅" if actual == 14 else "❌"
        if not ok:
            all_ok = False
        print(f"  {status} {fname}: {actual}页")
    
    if all_ok:
        print("\n🎉 全部7个文件已标准化为14页！")
    else:
        print("\n⚠️ 部分文件需进一步调整")


if __name__ == '__main__':
    main()
