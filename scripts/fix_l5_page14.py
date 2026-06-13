#!/usr/bin/env python3
"""
L5教案修复脚本：为6个文件的空Page 14添加故事结尾内容
用法：python3 scripts/fix_l5_page14.py
"""
import re
import os
from pathlib import Path

CONTENT_DIR = Path("/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容")

# Page 14内容：每课的故事结尾页
PAGE14_CONTENT = {
    "L5-095": """【画面描述】小明合上书，眼中闪烁着对历史的热爱。书架上还有很多历史书。
【文字】从三国故事中，小明学到了智慧比力量更重要。他决定多读历史书，学习更多智慧。
【拼音】cóng sān guó gù shì zhōng，xiǎo míng xué dào le zhì huì bǐ lì liàng gèng zhòng yào。tā jué dìng duō dú lì shǐ shū，xué xí gèng duō zhì huì。
【新字标注】智、慧
""",
    "L5-099": """【画面描述】小明在电脑前完成了一个小程序，开心地举起双手庆祝。
【文字】编程真有趣！小明用逻辑思维解决了问题，创造出了自己的小程序。
【拼音】biān chéng zhēn yǒu qù！xiǎo míng yòng luó jí sī wéi jiě jué le wèn tí，chuàng zào chū le zì jǐ de xiǎo chéng xù。
【新字标注】逻、辑
""",
    "L5-100": """【画面描述】小明站在山顶，回望走过的路，脸上写满坚毅。
【文字】长征路上虽然困难重重，但红军战士不怕苦、不怕难，坚持到底就是胜利！
【拼音】cháng zhēng lù shàng suī rán kùn nán chóng chóng，dàn hóng jūn zhàn shì bù pà kǔ、bù pà nán，jiān chí dào dǐ jiù shì shèng lì！
【新字标注】胜、利
""",
    "L5-101": """【画面描述】小明拿着磁铁和铁钉做实验，脸上露出恍然大悟的表情。
【文字】看不见的力量无处不在！重力让苹果落地，磁力让铁钉相吸，世界真奇妙！
【拼音】kàn bù jiàn de lì liàng wú chù bù zài！zhòng lì ràng píng guǒ luò dì，cí lì ràng tiě dīng xiāng xī，shì jiè zhēn qí miào！
【新字标注】奇、妙
""",
    "L5-102": """【画面描述】小明站在自己画的未来城市图前，想象着美好的未来。
【文字】未来城市需要我们用心设计，让城市变得更美好、更幸福！
【拼音】wèi lái chéng shì xū yào wǒ men yòng xīn shè jì，ràng chéng shì biàn de gèng měi hǎo、gèng xìng fú！
【新字标注】美、好
""",
    "L5-103": """【画面描述】小明翻开《山海经》，眼前浮现出各种神奇的画面。
【文字】《山海经》里的故事虽然神奇，但它们是中华文化的根基，让我们更加了解自己的文化。
【拼音】《shān hǎi jīng》lǐ de gù shì suī rán shén qí，dàn tā men shì zhōng huá wén huà de gēn jī，ràng wǒ men gèng jiā liǎo jiě zì jǐ de wén huà。
【新字标注】根、基
""",
    "L5-104": """【画面描述】小明回顾100篇故事中的精彩片段，脸上露出成长后的自信笑容。
【文字】成长的意义就是不断学习、不断思考、不断进步。100篇故事，让小明收获满满！
【拼音】chéng zhǎng de yì yì jiù shì bù duàn xué xí、bù duàn sī kǎo、bù duàn jìn bù。100 piān gù shì，ràng xiǎo míng shōu huò mǎn mǎn！
【新字标注】收、获
""",
}


def fix_page14(filepath):
    """修复空Page 14"""
    fname = os.path.basename(filepath)
    
    num_match = re.search(r'L5-(\d+)', fname)
    if not num_match:
        return f"SKIP: {fname}"
    
    num = f"L5-{num_match.group(1)}"
    if num not in PAGE14_CONTENT:
        return f"SKIP: {fname} - no Page 14 data"
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find Page 14 marker
    page14_match = re.search(r'(### Page 14\s*\n)', content)
    if not page14_match:
        return f"SKIP: {fname} - no Page 14"
    
    # Check if Page 14 has content
    after_p14 = content[page14_match.end():]
    # Find the next section header
    next_section = re.search(r'\n##\s*[四五六]', after_p14)
    if next_section:
        p14_content = after_p14[:next_section.start()].strip()
    else:
        p14_content = after_p14.strip()
    
    if len(p14_content) > 20:
        return f"SKIP: {fname} - Page 14 has content ({len(p14_content)} chars)"
    
    # Insert Page 14 content
    insert_pos = page14_match.end()
    new_content = PAGE14_CONTENT[num] + "\n"
    
    content = content[:insert_pos] + new_content + content[insert_pos:]
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return f"OK: {fname} - Page 14 已添加内容"


# Main
files = sorted([f for f in os.listdir(CONTENT_DIR) if f.startswith('L5-') and f.endswith('.md') and '创作规范' not in f and '审核报告' not in f])
results = {"OK": 0, "SKIP": 0, "FAIL": 0}

for fname in files:
    filepath = os.path.join(CONTENT_DIR, fname)
    result = fix_page14(filepath)
    if result.startswith("OK"):
        results["OK"] += 1
        print(f"  {result}")
    elif "SKIP" in result and "no Page 14 data" in result:
        pass  # Skip silently for files without Page 14 data
    else:
        results["SKIP"] += 1

print(f"\n完成：{results['OK']} 修复 / {results['SKIP']} 跳过")
