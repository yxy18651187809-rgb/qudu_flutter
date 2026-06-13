#!/usr/bin/env python3
"""
Fix L5-095~104 page count issues.
- L5-095: 13→14 (+1 page)
- L5-099: 15→14 (-1 page, merge)
- L5-100: 11→14 (+3 pages)
- L5-101: 13→14 (+1 page)
- L5-102: 13→14 (+1 page)
- L5-103: 13→14 (+1 page)
- L5-104: 15→14 (-1 page, merge)
- L5-098: 4→14 (+10 pages) [CRITICAL]
"""
import re
from pathlib import Path

CONTENT_DIR = Path("/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容")


def count_real_pages(content):
    """Count actual Page N entries (not fake 'Page 13-32' entries)"""
    count = 0
    for line in content.split('\n'):
        if re.match(r'###\s*Page\s+\d+$', line.strip()):
            count += 1
    return count


def extract_pages(content):
    """Extract page blocks as list of (page_num, block_text)"""
    lines = content.split('\n')
    pages = []
    current_page = None
    current_block = []
    
    for line in lines:
        m = re.match(r'###\s*Page\s+(\d+)(?:-\d+)?\s*$', line.strip())
        if m:
            if current_page is not None:
                pages.append((current_page, '\n'.join(current_block)))
            current_page = int(m.group(1))
            current_block = [line]
        elif current_page is not None:
            current_block.append(line)
    
    if current_page is not None:
        pages.append((current_page, '\n'.join(current_block)))
    
    return pages


def extract_post_script(content):
    """Extract everything after the last real page block (教育目标, 练习, etc.)"""
    lines = content.split('\n')
    post_lines = []
    in_post = False
    
    for line in lines:
        # Detect fake page entries like "### Page 13-32" followed by non-page content
        if re.match(r'###\s*Page\s+\d+-\d+', line.strip()):
            in_post = True
        
        if in_post:
            post_lines.append(line)
    
    return '\n'.join(post_lines)


def build_page(num, desc, text, pinyin, new_chars):
    """Build a single page block"""
    return f"""### Page {num}
【画面描述】{desc}
【文字】{text}
【拼音】{pinyin}
【新字】{new_chars}"""


def insert_page_after(existing_pages, after_page_num, new_page_content):
    """Insert a new page after a specific page number, renumbering subsequent pages"""
    result = []
    new_num = 1
    inserted = False
    
    for page_num, block in existing_pages:
        if not inserted and page_num == after_page_num:
            result.append((new_num, block))
            new_num += 1
            result.append((new_num, new_page_content))
            new_num += 1
            inserted = True
        else:
            result.append((new_num, block))
            new_num += 1
    
    if not inserted:
        result.append((new_num, new_page_content))
        new_num += 1
    
    return result


def merge_adjacent_pages(pages, keep_first_idx):
    """Merge two adjacent pages (keep_first_idx and keep_first_idx+1)"""
    if keep_first_idx >= len(pages) - 1:
        return pages
    
    p1_num, p1_block = pages[keep_first_idx]
    p2_num, p2_block = pages[keep_first_idx + 1]
    
    # Extract content from both pages
    def extract_field(block, field):
        for line in block.split('\n'):
            if line.startswith(f'【{field}】'):
                return line.replace(f'【{field}】', '').strip()
        return ''
    
    desc = extract_field(p1_block, '画面描述') + '；' + extract_field(p2_block, '画面描述')
    text = extract_field(p1_block, '文字') + extract_field(p2_block, '文字')
    pinyin = extract_field(p1_block, '拼音') + extract_field(p2_block, '拼音')
    chars1 = extract_field(p1_block, '新字')
    chars2 = extract_field(p2_block, '新字')
    
    # Merge new chars
    all_chars = set()
    for c in (chars1 + '、' + chars2).split('、'):
        c = c.strip().rstrip('】')
        if c and c != '（复习字）':
            all_chars.add(c)
    
    merged_block = build_page(p1_num, desc, text, pinyin, '、'.join(all_chars))
    
    result = []
    new_num = 1
    for i, (num, block) in enumerate(pages):
        if i == keep_first_idx:
            result.append((new_num, merged_block))
        elif i == keep_first_idx + 1:
            continue  # skip merged page
        else:
            result.append((new_num, block))
        new_num += 1
    
    return result


def renumber_pages(pages):
    """Renumber all pages sequentially"""
    result = []
    for i, (_, block) in enumerate(pages):
        old_num_match = re.match(r'(###\s*Page\s+)\d+', block)
        if old_num_match:
            new_block = re.sub(r'###\s*Page\s+\d+', f'### Page {i+1}', block)
            result.append((i+1, new_block))
        else:
            result.append((i+1, block))
    return result


def update_info_table(content, page_count):
    """Update page count in info table"""
    content = re.sub(
        r'(\|\s*页数\s*\|\s*)\d+页',
        f'\\g<1>{page_count}页',
        content
    )
    return content


def fix_l5_098():
    """L5-098: 4 real pages → 14 pages (CRITICAL: expand from 4 to 14)"""
    fp = CONTENT_DIR / "L5-098_本草的故事.md"
    with open(fp, 'r') as f:
        content = f.read()
    
    # The file only has 4 real pages (Pages 1-4), then jumps to "Page 15-30"
    # We need to expand to 14 pages about 中医药文化/神农尝百草/李时珍
    
    new_pages = """### Page 1
【画面描述】远古时代，青山绿水间，一位白发老人在山上采药草。
【文字】很久很久以前，有位叫神农的人，他走遍千山万水采草药。
【拼音】hěn jiǔ hěn jiǔ yǐ qián，yǒu wèi jiào shén nóng de rén，tā zǒu biàn qiān shān wàn shuǐ cǎi cǎo yào。
【新字】神、农、百、草

### Page 2
【画面描述】神农在山洞里，周围摆满了各种草药，他正在仔细观察。
【文字】神农发现有些草可以治病，有些草有毒，他一一记下来。
【拼音】shén nóng fā xiàn yǒu xiē cǎo kě yǐ zhì bìng，yǒu xiē cǎo yǒu dú，tā yī yī jì xià lái。
【新字】治、病、安、全

### Page 3
【画面描述】神农在山上品尝草药，面露痛苦表情，周围有各种草药。
【文字】传说神农尝了上百种草药，为了帮人们找到治病的办法。
【拼音】chuán shuō shén nóng cháng le shàng bǎi zhǒng cǎo yào，wèi le bāng rén men zhǎo dào zhì bìng de bàn fǎ。
【新字】尝、根、药

### Page 4
【画面描述】古代药铺，墙上挂满草药，一位大夫在给病人把脉。
【文字】从此人们学会了用草药治病，中医药文化就这样开始了。
【拼音】cóng cǐ rén men xué huì le yòng cǎo yào zhì bìng，zhōng yī yào wén huà jiù zhè yàng kāi shǐ le。
【新字】中、医

### Page 5
【画面描述】明代，一位身穿长袍的读书人正在翻阅古籍，窗外是药园。
【文字】很多年后，明朝的李时珍决定写一本关于草药的大书。
【拼音】hěn duō nián hòu，míng cháo de lǐ shí zhēn jué dìng xiě yī běn guān yú cǎo yào de dà shū。
【新字】李、时、珍、著

### Page 6
【画面描述】李时珍背着药篓，走过田野山林，沿路采摘各种植物。
【文字】李时珍走遍各地，亲自采药、尝药，记录每一种草药的样子和功效。
【拼音】lǐ shí zhēn zǒu biàn gè dì，qīn zì cǎi yào、cháng yào，jì lù měi yī zhǒng cǎo yào de yàng zi hé gōng xiào。
【新字】记、录、功、效

### Page 7
【画面描述】李时珍在烛光下翻阅古籍，桌上摆满了草药标本。
【文字】他花了二十七年，终于写完了《本草纲目》这本书。
【拼音】tā huà le èr shí qī nián，zhōng yú xiě wán le 《běn cǎo gāng mù》zhè běn shū。
【新字】写、本、巨

### Page 8
【画面描述】厚厚的《本草纲目》翻开，里面有各种草药的手绘图。
【文字】《本草纲目》记录了一千多种草药，是一本了不起的科学巨著！
【拼音】《běn cǎo gāng mù》jì lù le yī qiān duō zhǒng cǎo yào，shì yī běn liǎo bù qǐ de kē xué jù zhù！
【新字】科、学

### Page 9
【画面描述】现代中药房，药柜整齐排列，药师在抓药。
【文字】到了现代，中药房里还有各种草药，中医师给病人诊断。
【拼音】dào le xiàn dài，zhōng yào fáng lǐ hái yǒu gè zhǒng cǎo yào，zhōng yī shī gěi bìng rén zhěn duàn。
【新字】诊、断

### Page 10
【画面描述】中医师在给病人把脉，桌上放着针灸器具。
【文字】中医用望闻问切来诊断，还用针灸来治疗疾病。
【拼音】zhōng yī yòng wàng wén wèn qiè lái zhěn duàn，hái yòng zhēn jiǔ lái zhì liáo jí bìng。
【新字】针、调、理

### Page 11
【画面描述】画面分两半：左边是阴（月亮、黑色），右边是阳（太阳、红色）。
【文字】中医讲究阴阳平衡，身体才会健康。
【拼音】zhōng yī jiǎng jiū yīn yáng píng héng，shēn tǐ cái huì jiàn kāng。
【新字】阴、阳、平、衡

### Page 12
【画面描述】各种常见中药材：枸杞、菊花、人参、当归等。
【文字】生活中有很多常见的中药材，比如菊花可以泡茶，枸杞可以煮汤。
【拼音】shēng huó zhōng yǒu hěn duō cháng jiàn de zhōng yào cái，bǐ rú jú huā kě yǐ pào chá，gǒu qǐ kě yǐ zhǔ tāng。
【新字】常、见

### Page 13
【画面描述】老师在课堂上给学生们讲中医药文化。
【文字】老师说："中医药是中华民族几千年智慧的结晶。"
【拼音】lǎo shī shuō："zhōng yī yào shì zhōng huá mín zú jǐ qiān nián zhì huì de jié jīng。"
【新字】文、化、智、慧

### Page 14
【画面描述】小明站在中医药展览馆里，看着各种中药材和古籍，面带敬仰。
【文字】小明说："中医药文化真了不起，我们要传承下去！"
【拼音】xiǎo míng shuō："zhōng yī yào wén huà zhēn liǎo bù qǐ，wǒ men yào chuán chéng xià qù！"
【新字】传、承、现、代"""
    
    # Replace the story content section
    # Find the section between "## 三、故事正文" and the post-script content
    pattern = re.compile(
        r'(## 三、故事正文（分页脚本）\s*\n)(.*?)(## 五、配套练习)',
        re.DOTALL
    )
    
    match = pattern.search(content)
    if match:
        content = content[:match.start()] + "## 三、故事正文（分页脚本）\n\n" + new_pages + "\n\n" + content[match.end() - len("## 五、配套练习"):]
    
    # Also clean up the old fake "Page 15-30" section and the embedded 教育目标/练习/插画需求
    # Remove the old 教研员交付确认 block
    content = re.sub(
        r'\n---\n\n\*\*教研员交付确认\*\*：.*?交付给team-lead，请审阅\n',
        '\n',
        content,
        flags=re.DOTALL
    )
    
    # Update info table
    content = update_info_table(content, 14)
    
    # Fix "很多年后面" typo
    content = content.replace('很多年后面', '很多年以后')
    
    with open(fp, 'w') as f:
        f.write(content)
    
    print(f"  ✅ L5-098: 4→14页 (+10页扩展完成)")


def fix_simple_expand(filepath, insert_after_page, new_page_content, char_label=""):
    """Expand a file by inserting 1 page after a specific page"""
    with open(filepath, 'r') as f:
        content = f.read()
    
    pages = extract_pages(content)
    
    # Build new page block
    new_block = f"### Page TEMP\n{new_page_content}"
    
    # Insert after specified page
    result = insert_page_after(pages, insert_after_page, new_block)
    result = renumber_pages(result)
    
    # Rebuild content
    page_section = '\n\n'.join(block for _, block in result)
    
    # Find and replace the pages section
    pattern = re.compile(
        r'(## 三、故事正文（分页脚本）\s*\n)(.*?)(?=\n## [四五六])',
        re.DOTALL
    )
    
    match = pattern.search(content)
    if match:
        content = content[:match.start()] + "## 三、故事正文（分页脚本）\n\n" + page_section + "\n" + content[match.end():]
    
    # Update info table
    content = update_info_table(content, len(result))
    
    # Clean up fake page ranges and embedded content
    content = re.sub(
        r'\n---\n\n\*\*教研员交付确认\*\*：.*?交付给team-lead，请审阅\n',
        '\n',
        content,
        flags=re.DOTALL
    )
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    print(f"  ✅ {filepath.name}: +1页 (在Page {insert_after_page}后插入)")


def fix_simple_merge(filepath, merge_after_page):
    """Merge two adjacent pages to reduce count by 1"""
    with open(filepath, 'r') as f:
        content = f.read()
    
    pages = extract_pages(content)
    
    # Find the index of the page to merge (merge merge_after_page with merge_after_page+1)
    merge_idx = None
    for i, (num, _) in enumerate(pages):
        if num == merge_after_page:
            merge_idx = i
            break
    
    if merge_idx is None or merge_idx >= len(pages) - 1:
        print(f"  ❌ {filepath.name}: 找不到Page {merge_after_page}")
        return
    
    result = merge_adjacent_pages(pages, merge_idx)
    result = renumber_pages(result)
    
    page_section = '\n\n'.join(block for _, block in result)
    
    pattern = re.compile(
        r'(## 三、故事正文（分页脚本）\s*\n)(.*?)(?=\n## [四五六])',
        re.DOTALL
    )
    
    match = pattern.search(content)
    if match:
        content = content[:match.start()] + "## 三、故事正文（分页脚本）\n\n" + page_section + "\n" + content[match.end():]
    
    content = update_info_table(content, len(result))
    
    content = re.sub(
        r'\n---\n\n\*\*教研员交付确认\*\*：.*?交付给team-lead，请审阅\n',
        '\n',
        content,
        flags=re.DOTALL
    )
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    print(f"  ✅ {filepath.name}: -1页 (合并Page {merge_after_page}和{merge_after_page+1})")


def fix_l5_100():
    """L5-100: 11→14 (+3 pages)"""
    fp = CONTENT_DIR / "L5-100_长征路上.md"
    with open(fp, 'r') as f:
        content = f.read()
    
    pages = extract_pages(content)
    
    # Insert 3 new pages at strategic points in the story
    new_pages_content = [
        # After Page 1 (start of journey): describe the scale
        (1, """### Page TEMP
【画面描述】地图上标注着长征路线，从江西出发，终点在陕西。
【文字】长征从江西出发，要走两万五千里，才能到达目的地。
【拼音】cháng zhēng cóng jiāng xī chū fā，yào zǒu liǎng wàn wǔ qiān lǐ，cái néng dào dá mù dì dì。
【新字】两、万、五、千、里、目、的"""),
        # After Page 4 (snow mountain): describe crossing details
        (4, """### Page TEMP
【画面描述】红军在风雪中艰难前行，有的战士互相搀扶。
【文字】雪山上风很大，战士们手拉手，一步一步往前走。
【拼音】xuě shān shàng fēng hěn dà，zhàn shì men shǒu lā shǒu，yī bù yī bù wǎng qián zǒu。
【新字】互、相、帮、助"""),
        # After Page 7 (arriving at destination): describe celebrations
        (7, """### Page TEMP
【画面描述】红军到达陕北，战士们欢呼，红旗飘扬。
【文字】大家高喊："我们胜利了！"所有的辛苦都值得了。
【拼音】dà jiā gāo hǎn："wǒ men shèng lì le！"suǒ yǒu de xīn kǔ dōu zhí dé le。
【新字】高、喊、所、有、值、得"""),
    ]
    
    # Process insertions in reverse order to maintain indices
    for after_page, new_content in reversed(new_pages_content):
        new_block = f"{new_content}"
        pages = insert_page_after(pages, after_page, new_block)
        pages = renumber_pages(pages)
    
    page_section = '\n\n'.join(block for _, block in pages)
    
    pattern = re.compile(
        r'(## 三、故事正文（分页脚本）\s*\n)(.*?)(?=\n## [四五六])',
        re.DOTALL
    )
    
    match = pattern.search(content)
    if match:
        content = content[:match.start()] + "## 三、故事正文（分页脚本）\n\n" + page_section + "\n" + content[match.end():]
    
    content = update_info_table(content, len(pages))
    
    content = re.sub(
        r'\n---\n\n\*\*教研员交付确认\*\*：.*?交付给team-lead，请审阅\n',
        '\n',
        content,
        flags=re.DOTALL
    )
    
    with open(fp, 'w') as f:
        f.write(content)
    
    print(f"  ✅ L5-100: 11→14页 (+3页扩展完成)")


def main():
    print("=" * 60)
    print("L5-095~104 页面修复")
    print("=" * 60)
    
    # 1. L5-098: 4→14 (CRITICAL - full rewrite of story section)
    print("\n🔴 L5-098 本草的故事: 4→14页（+10页）")
    fix_l5_098()
    
    # 2. L5-100: 11→14 (+3 pages)
    print("\n🔴 L5-100 长征路上: 11→14页（+3页）")
    fix_l5_100()
    
    # 3. L5-095: 13→14 (+1 page, insert after Page 9 赤壁之战 before 空城计)
    print("\n🟡 L5-095 三国故事: 13→14页（+1页）")
    fix_simple_expand(
        CONTENT_DIR / "L5-095_三国故事.md",
        insert_after_page=9,
        new_page_content="""【画面描述】三国时期，人们穿古装，用冷兵器打仗。
【文字】那时候没有手机和电脑，人们用智慧和勇气打天下。
【拼音】nà shí hou méi yǒu shǒu jī hé diàn nǎo，rén men yòng zhì huì hé yǒng qì dǎ tiān xià。
【新字】勇、敢"""
    )
    
    # 4. L5-101: 13→14 (+1 page, insert after Page 7 牛顿)
    print("\n🟡 L5-101 看不见的力量: 13→14页（+1页）")
    fix_simple_expand(
        CONTENT_DIR / "L5-101_看不见的力量.md",
        insert_after_page=7,
        new_page_content="""【画面描述】小明在家里做小实验：扔球、磁铁吸钉子。
【文字】小明也在家做实验，发现这些看不见的力量真有趣！
【拼音】xiǎo míng yě zài jiā zuò shí yàn，fā xiàn zhè xiē kàn bú jiàn de lì liàng zhēn yǒu qù！
【新字】实、验"""
    )
    
    # 5. L5-102: 13→14 (+1 page, insert after Page 8 废物回收)
    print("\n🟡 L5-102 我的未来城市: 13→14页（+1页）")
    fix_simple_expand(
        CONTENT_DIR / "L5-102_我的未来城市.md",
        insert_after_page=8,
        new_page_content="""【画面描述】未来城市的公园里，孩子们在绿草地上玩耍。
【文字】未来城市里，公园很大，孩子们可以在草地上快乐地玩。
【拼音】wèi lái chéng shì lǐ，gōng yuán hěn dà，hái zi men kě yǐ zài cǎo dì shàng kuài lè dì wán。
【新字】公、园"""
    )
    
    # 6. L5-103: 13→14 (+1 page, insert after Page 8 遨游太空)
    print("\n🟡 L5-103 山海经选读: 13→14页（+1页）")
    fix_simple_expand(
        CONTENT_DIR / "L5-103_山海经选读.md",
        insert_after_page=8,
        new_page_content="""【画面描述】小明和同学一起读《山海经》，讨论里面的神兽。
【文字】小明和同学一起读《山海经》，每个人画出自己最喜欢的神兽。
【拼音】xiǎo míng hé tóng xué yī qǐ dú 《shān hǎi jīng》，měi gè rén huà chū zì jǐ zuì xǐ huān de shén shòu。
【新字】同、学"""
    )
    
    # 7. L5-099: 15→14 (merge Page 11+12, both about fixing code)
    print("\n🟡 L5-099 编程的乐趣: 15→14页（-1页）")
    fix_simple_merge(CONTENT_DIR / "L5-099_编程的乐趣.md", merge_after_page=11)
    
    # 8. L5-104: 15→14 (merge Page 10+11, both about gratitude)
    print("\n🟡 L5-104 成长的意义: 15→14页（-1页）")
    fix_simple_merge(CONTENT_DIR / "L5-104_成长的意义.md", merge_after_page=10)
    
    # Verify all files
    print("\n" + "=" * 60)
    print("验证结果")
    print("=" * 60)
    
    all_ok = True
    for num in [95, 98, 99, 100, 101, 102, 103, 104]:
        fp = CONTENT_DIR / f"L5-{num}_*.md"
        files = list(CONTENT_DIR.glob(f"L5-{num}_*.md"))
        if not files:
            print(f"  ❌ L5-{num}: 文件不存在")
            all_ok = False
            continue
        
        with open(files[0], 'r') as f:
            content = f.read()
        
        page_count = count_real_pages(content)
        status = "✅" if page_count == 14 else "❌"
        if page_count != 14:
            all_ok = False
        print(f"  {status} L5-{num} {files[0].name}: {page_count}页")
    
    if all_ok:
        print("\n🎉 全部8个文件页数已标准化为14页！")
    else:
        print("\n⚠️ 部分文件仍需手动调整")


if __name__ == '__main__':
    main()
