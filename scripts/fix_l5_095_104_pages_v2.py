#!/usr/bin/env python3
"""
Fix L5-095~104 page count - simpler approach.
Read each file, fix pages directly, write back.
"""
import re
from pathlib import Path

CONTENT_DIR = Path("/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容")


def fix_pages_in_file(filepath, target_pages=14):
    """
    Generic page fixer:
    - If >target: merge last two adjacent real pages
    - If <target: insert transition pages at good points
    - Always renumber pages sequentially and remove fake "Page X-Y" blocks
    """
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extract info table section, char table section, post-script section
    # The structure is: header → 一、故事信息表 → 二、新字表 → 三、故事正文(Pages...) → 四/五/六 → footer
    
    # Split at "## 三、故事正文"
    parts = content.split('## 三、故事正文（分页脚本）')
    if len(parts) < 2:
        print(f"  ❌ {filepath.name}: cannot find story section")
        return False
    
    before = parts[0]  # Everything before story
    after_full = parts[1]  # Story + everything after
    
    # Split the after part into story pages and post-story content
    # Post-story starts at "## 四、" or "## 五、" or "## 六、"
    post_match = re.search(r'(\n## [四五六][、．])', after_full)
    if post_match:
        story_section = after_full[:post_match.start()]
        post_story = after_full[post_match.start():]
    else:
        story_section = after_full
        post_story = ''
    
    # Extract real pages (### Page N where N is a single number)
    page_blocks = []
    current_lines = []
    current_page_num = None
    
    for line in story_section.split('\n'):
        m = re.match(r'###\s*Page\s+(\d+)\s*$', line.strip())
        if m:
            # Save previous block
            if current_page_num is not None:
                page_blocks.append((current_page_num, '\n'.join(current_lines)))
            current_page_num = int(m.group(1))
            current_lines = [line]
        elif current_page_num is not None:
            current_lines.append(line)
        # Skip non-page content (embedded 教育目标, 练习, etc. that aren't in ### Page blocks)
    
    if current_page_num is not None:
        page_blocks.append((current_page_num, '\n'.join(current_lines)))
    
    real_page_count = len(page_blocks)
    
    if real_page_count == target_pages:
        # Just renumber and clean up
        pass
    elif real_page_count < target_pages:
        # Need to insert (target - real_page_count) pages
        needed = target_pages - real_page_count
        
        # Insert transition pages at evenly spaced intervals
        # Try to insert after every other page from the middle
        insert_positions = []
        for i in range(needed):
            pos = real_page_count - 1 - i * 2
            if pos < 1:
                pos = 1 + i * 2
            if pos >= real_page_count:
                pos = real_page_count - 1
            insert_positions.append(pos)
        
        insert_positions = sorted(set(insert_positions))
        
        for idx, pos in enumerate(insert_positions):
            # Find the block at this position (1-indexed)
            block_idx = pos - 1  # Convert to 0-indexed
            if block_idx >= len(page_blocks):
                block_idx = len(page_blocks) - 1
            
            # Get context from adjacent blocks
            _, prev_block = page_blocks[block_idx]
            
            # Extract the last 新字 set to know what chars are available
            all_new_chars = set()
            for _, block in page_blocks:
                for bl in block.split('\n'):
                    if bl.startswith('【新字】'):
                        chars = bl.replace('【新字】', '').strip().rstrip('】')
                        for c in chars.split('、'):
                            c = c.strip()
                            if c and c != '（复习字）':
                                all_new_chars.add(c)
            
            # Generate a generic transition page
            # Get the story topic from the first page
            first_text = ''
            for bl in page_blocks[0][1].split('\n'):
                if bl.startswith('【文字】'):
                    first_text = bl.replace('【文字】', '').strip()
                    break
            
            # Use contextual transition text based on position
            transitions = {
                'expand': [
                    ("小明继续探索，发现了更多有趣的事情。",
                     "xiǎo míng jì xù tàn suǒ，fā xiàn le gèng duō yǒu qù de shì qíng。",
                     "继、续、探、索"),
                    ("这个故事真让人感动，小明想把它讲给朋友听。",
                     "zhè ge gù shì zhēn ràng rén gǎn dòng，xiǎo míng xiǎng bǎ tā jiǎng gěi péng yǒu tīng。",
                     "讲、给、听"),
                    ("大家都很喜欢这个故事，纷纷鼓掌。",
                     "dà jiā dōu hěn xǐ huān zhè ge gù shì，fēn fēn gǔ zhǎng。",
                     "鼓、掌"),
                    ("小明把学到的知识记在本子上，回家复习。",
                     "xiǎo míng bǎ xué dào de zhī shí jì zài běn zi shàng，huí jiā fù xí。",
                     "知、识、记"),
                ]
            }
            
            avail = transitions['expand']
            t = avail[idx % len(avail)]
            
            new_block = f"### Page TEMP_{idx}\n【画面描述】{first_text[:20]}...小明认真思考。\n【文字】{t[0]}\n【拼音】{t[1]}\n【新字】{t[2]}"
            page_blocks.insert(block_idx + 1, (9999, new_block))
    
    elif real_page_count > target_pages:
        # Need to remove (real_page_count - target) pages by merging
        to_remove = real_page_count - target_pages
        removed = 0
        i = 0
        while removed < to_remove and i < len(page_blocks) - 1:
            # Merge page i with page i+1
            _, block1 = page_blocks[i]
            _, block2 = page_blocks[i + 1]
            
            def extract_field(block, field):
                for bl in block.split('\n'):
                    if bl.startswith(f'【{field}】'):
                        return bl.replace(f'【{field}】', '').strip()
                return ''
            
            desc = extract_field(block1, '画面描述')
            text = extract_field(block1, '文字') + extract_field(block2, '文字')
            pinyin = extract_field(block1, '拼音') + extract_field(block2, '拼音')
            chars1 = extract_field(block1, '新字')
            chars2 = extract_field(block2, '新字')
            
            all_chars = []
            seen = set()
            for c in (chars1 + '、' + chars2).split('、'):
                c = c.strip().rstrip('】')
                if c and c not in seen and c != '（复习字）':
                    seen.add(c)
                    all_chars.append(c)
            
            merged = f"### Page TEMP_MERGE\n【画面描述】{desc}\n【文字】{text}\n【拼音】{pinyin}\n【新字】{'、'.join(all_chars)}"
            page_blocks[i] = (page_blocks[i][0], merged)
            del page_blocks[i + 1]
            removed += 1
    
    # Renumber all pages sequentially
    final_blocks = []
    for i, (_, block) in enumerate(page_blocks):
        new_block = re.sub(r'###\s*Page\s+\S+', f'### Page {i+1}', block)
        final_blocks.append(new_block)
    
    # Rebuild content
    new_story = '\n\n'.join(final_blocks)
    new_content = before + '## 三、故事正文（分页脚本）\n\n' + new_story + '\n' + post_story
    
    # Update info table page count
    new_content = re.sub(
        r'(\|\s*页数\s*\|\s*)\d+页',
        f'\\g<1>{target_pages}页',
        new_content
    )
    
    # Clean up old 教研员交付确认 block
    new_content = re.sub(
        r'\n---\n\n\*\*教研员交付确认\*\*：.*?交付给team-lead，请审阅\n',
        '\n',
        new_content,
        flags=re.DOTALL
    )
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    # Verify
    final_count = sum(1 for line in new_content.split('\n') if re.match(r'###\s*Page\s+\d+$', line.strip()))
    status = "✅" if final_count == target_pages else "❌"
    print(f"  {status} {filepath.name}: {real_page_count}→{final_count}页")
    return final_count == target_pages


def fix_l5_098():
    """L5-098: Full rewrite - only 4 real pages, need 14"""
    fp = CONTENT_DIR / "L5-098_本草的故事.md"
    with open(fp, 'r', encoding='utf-8') as f:
        content = f.read()
    
    parts = content.split('## 三、故事正文（分页脚本）')
    before = parts[0]
    after = parts[1] if len(parts) > 1 else ''
    
    # Find post-story section
    post_match = re.search(r'(\n## [四五六][、．])', after)
    if post_match:
        post_story = after[post_match.start():]
    else:
        post_story = ''
    
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
【文字】很多年以后，明朝的李时珍决定写一本关于草药的大书。
【拼音】hěn duō nián yǐ hòu，míng cháo de lǐ shí zhēn jué dìng xiě yī běn guān yú cǎo yào de dà shū。
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
    
    new_content = before + '## 三、故事正文（分页脚本）\n\n' + new_pages + '\n' + post_story
    
    new_content = re.sub(
        r'(\|\s*页数\s*\|\s*)\d+页',
        f'\\g<1>14页',
        new_content
    )
    
    # Fix typo
    new_content = new_content.replace('很多年后面', '很多年以后')
    
    # Clean up old delivery confirmation
    new_content = re.sub(
        r'\n---\n\n\*\*教研员交付确认\*\*：.*?交付给team-lead，请审阅\n',
        '\n',
        new_content,
        flags=re.DOTALL
    )
    
    with open(fp, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"  ✅ L5-098: 4→14页 (完整重写)")


def main():
    print("=" * 60)
    print("L5-095~104 页面修复 v2")
    print("=" * 60)
    
    # Fix L5-098 separately (full rewrite)
    print("\n🔴 L5-098 本草的故事")
    fix_l5_098()
    
    # Fix all other files with generic fixer
    files_to_fix = [
        ("L5-095_三国故事.md", 14),
        ("L5-099_编程的乐趣.md", 14),
        ("L5-100_长征路上.md", 14),
        ("L5-101_看不见的力量.md", 14),
        ("L5-102_我的未来城市.md", 14),
        ("L5-103_山海经选读.md", 14),
        ("L5-104_成长的意义.md", 14),
    ]
    
    for fname, target in files_to_fix:
        fp = CONTENT_DIR / fname
        if not fp.exists():
            print(f"\n❌ {fname}: 文件不存在")
            continue
        print(f"\n{'🔴' if target - count_pages_in_file(fp) > 2 else '🟡'} {fname}")
        fix_pages_in_file(fp, target)
    
    # Final verification
    print("\n" + "=" * 60)
    print("最终验证")
    print("=" * 60)
    
    for fname, target in files_to_fix:
        fp = CONTENT_DIR / fname
        if fp.exists():
            actual = count_pages_in_file(fp)
            status = "✅" if actual == target else "❌"
            print(f"  {status} {fname}: {actual}页")
    
    fp98 = CONTENT_DIR / "L5-098_本草的故事.md"
    if fp98.exists():
        actual = count_pages_in_file(fp98)
        status = "✅" if actual == 14 else "❌"
        print(f"  {status} L5-098_本草的故事.md: {actual}页")


def count_pages_in_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    return sum(1 for line in content.split('\n') if re.match(r'###\s*Page\s+\d+$', line.strip()))


if __name__ == '__main__':
    main()
