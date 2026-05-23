#!/usr/bin/env python3
"""
L2教案 → 绘本文案 转换脚本
读取L2-001~010教案文件，输出对标L1绘本v2格式的绘本文案。
"""
import re
import os
from pathlib import Path

CONTENT_DIR = Path("/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容")
OUTPUT_DIR = CONTENT_DIR

def parse_lesson_plan(text, book_num):
    """解析单个L2教案，返回结构化数据"""
    data = {
        "book_num": book_num,
        "title": "",
        "theme": "",
        "pages": 14,
        "total_chars": "",
        "goal": "",
        "characters": [],  # list of dicts
        "pages_content": [],  # list of dicts {page_num, desc, text, pinyin, new_chars}
        "edu_goals": {},
        "exercises": [],
        "illustration": {},
    }
    
    lines = text.split("\n")
    
    # Extract title
    for line in lines:
        # Format: | 名称 | 《小马的河》 |
        title_match = re.search(r'名称[：:]\s*《(.+?)》', line)
        if title_match:
            data["title"] = title_match.group(1)
            break
        # Format: # 第N篇：《书名》
        story_match = re.match(r'#\s*第\d+篇[：:]\s*《(.+?)》', line)
        if story_match:
            data["title"] = story_match.group(1)
            break
        # Format: # L2-00X 《书名》
        l2_title_match = re.match(r'#\s*L2-\d+\s*《(.+?)》', line)
        if l2_title_match:
            data["title"] = l2_title_match.group(1)
            break
    
    # Extract info table
    in_info_table = False
    for line in lines:
        if "故事信息表" in line:
            in_info_table = True
            continue
        if in_info_table:
            if line.startswith("|---") or line.startswith("| :---"):
                continue
            if not line.startswith("|"):
                break
            cells = [c.strip() for c in line.split("|")[1:-1]]
            if len(cells) >= 2:
                key = cells[0].strip()
                val = cells[1].strip()
                if "主题" in key:
                    data["theme"] = val
                elif "页数" in key:
                    try:
                        data["pages"] = int(re.search(r'\d+', val).group())
                    except:
                        pass
                elif "总字数" in key:
                    data["total_chars"] = val
                elif "教育目标" in key:
                    data["goal"] = val
    
    # Extract character table
    in_char_table = False
    char_lines = []
    for line in lines:
        if "新字表" in line and ("## 二" in line or re.match(r'^##?\s*新字表', line)):
            in_char_table = True
            continue
        if in_char_table:
            if line.startswith("|---") or line.startswith("| :---"):
                continue
            if not line.startswith("|"):
                # Check if we've moved on to another section
                if line.startswith("## ") or line.startswith("# "):
                    break
                if line.strip() == "":
                    if char_lines:
                        break
                    continue
                continue
            cells = [c.strip() for c in line.split("|")[1:-1]]
            if len(cells) >= 5:
                char_lines.append(cells)
    
    for cells in char_lines:
        char = {
            "character": cells[0] if len(cells) > 0 else "",
            "pinyin": cells[1] if len(cells) > 1 else "",
            "strokes": cells[2] if len(cells) > 2 else "",
            "radical": cells[3] if len(cells) > 3 else "",
            "words": cells[4] if len(cells) > 4 else "",
            "is_core": cells[5] if len(cells) > 5 else "",
            "note": cells[6] if len(cells) > 6 else "",
        }
        if char["character"] and char["character"] != "汉字":
            data["characters"].append(char)
    
    # Extract page scripts
    in_script = False
    current_page = None
    page_buf = {}
    
    for line in lines:
        page_match = re.match(r'###?\s*Page\s*(\d+)', line)
        if page_match:
            if current_page is not None and page_buf:
                data["pages_content"].append(page_buf)
            current_page = int(page_match.group(1))
            page_buf = {"page_num": current_page, "desc": "", "text": "", "pinyin": "", "new_chars": ""}
            continue
        
        if current_page is not None:
            # Check if we've moved to next section
            if line.startswith("## ") and "故事正文" not in line and "分页" not in line:
                if page_buf:
                    data["pages_content"].append(page_buf)
                current_page = None
                page_buf = {}
                continue
            
            desc_match = re.search(r'【画面描述】(.+)', line)
            text_match = re.search(r'【文字】(.+)', line)
            pinyin_match = re.search(r'【拼音】(.+)', line)
            newchar_match = re.search(r'【新字[标注]*】(.+)', line)
            
            if desc_match:
                page_buf["desc"] = desc_match.group(1).strip()
            elif text_match:
                page_buf["text"] = text_match.group(1).strip()
            elif pinyin_match:
                page_buf["pinyin"] = pinyin_match.group(1).strip()
            elif newchar_match:
                page_buf["new_chars"] = newchar_match.group(1).strip()
    
    # Don't forget the last page
    if current_page is not None and page_buf:
        data["pages_content"].append(page_buf)
    
    # Extract education goals
    in_edu = False
    edu_lines = []
    for line in lines:
        if "教育目标" in line and ("## 四" in line or "## 教育" in line or re.match(r'^##?\s*教育目标', line)):
            in_edu = True
            continue
        if in_edu:
            if line.startswith("## ") or line.startswith("# "):
                break
            # Handle bullet format: - **识字目标**：...
            if line.startswith("- **"):
                edu_lines.append(line.strip("- *"))
            # Handle numbered format: 1. **识字目标**：...
            elif re.match(r'^\d+\.\s*\*\*', line):
                edu_lines.append(line.strip())
    
    if edu_lines:
        data["edu_goals"] = {"raw": "\n".join(edu_lines)}
    
    # Extract exercises
    in_ex = False
    ex_lines = []
    for line in lines:
        if "配套练习" in line and ("## 五" in line or re.match(r'^##?\s*配套练习', line)):
            in_ex = True
            continue
        if in_ex:
            if line.startswith("## ") or line.startswith("# "):
                break
            if re.match(r'^\d+\.', line.strip()):
                ex_lines.append(line.strip())
    
    data["exercises"] = ex_lines
    
    # Extract illustration requirements
    in_illus = False
    illus_items = {}
    for line in lines:
        if "插画需求" in line and ("## 六" in line or re.match(r'^##?\s*插画需求', line)):
            in_illus = True
            continue
        if in_illus:
            if line.startswith("# ") or (line.startswith("---") and illus_items):
                break
            if line.startswith("|---") or line.startswith("| :---"):
                continue
            if line.startswith("|"):
                cells = [c.strip() for c in line.split("|")[1:-1]]
                if len(cells) >= 2:
                    illus_items[cells[0]] = cells[1]
    
    data["illustration"] = illus_items
    
    return data


def generate_picturebook(data):
    """将解析后的数据转为L1绘本v2格式的Markdown"""
    book_num = data["book_num"]
    title = data["title"]
    chars = data["characters"]
    pages = data["pages_content"]
    total_pages = len(pages)
    char_count = len(chars)
    core_count = sum(1 for c in chars if "是" in c.get("is_core", "") or "核心" in c.get("is_core", ""))
    review_count = sum(1 for c in chars if "复习" in c.get("note", ""))
    
    # Separate core and review chars
    new_chars = [c for c in chars if "复习" not in c.get("note", "")]
    review_chars = [c for c in chars if "复习" in c.get("note", "")]
    
    lines = []
    lines.append(f"# 绘本{book_num}：《{title}》")
    lines.append("")
    lines.append(f"> **级别**：L2 起步级（6-7岁）  ")
    lines.append(f"> **页数**：{total_pages}页+封面  ")
    lines.append(f"> **总字数**：约{data.get('total_chars', '')}  ")
    lines.append(f"> **新字**：{char_count}字（{core_count}核心+{char_count-core_count}扩展，{review_count}复习）  ")
    lines.append(f"> **创作日期**：2026-05-23  ")
    lines.append(f"> **生成方式**：基于教案AI转换  ")
    lines.append("")
    lines.append("---")
    lines.append("")
    
    # 绘本信息
    lines.append("## 绘本信息")
    lines.append("")
    lines.append("| 字段 | 内容 |")
    lines.append("|:---|:---|")
    lines.append(f"| 书名 | 《{title}》 |")
    theme = data.get("theme", "")
    lines.append(f"| 主题 | {theme} |")
    lines.append(f"| 难度 | ⭐⭐ L2起步级 |")
    lines.append("")
    lines.append("---")
    lines.append("")
    
    # 新字表
    lines.append(f"## 新字表（{char_count}字）")
    lines.append("")
    lines.append("| 序号 | 汉字 | 拼音 | 笔画 | 部首 | 组词示例 | 类型 |")
    lines.append("|:---:|:---:|:---:|:---:|:---:|:---|:---:|")
    for i, c in enumerate(chars, 1):
        ctype = "核心" if ("是" in c.get("is_core", "") or "核心" in c.get("is_core", "")) else "扩展"
        if "复习" in c.get("note", ""):
            ctype = "复习"
        lines.append(f"| {i} | {c['character']} | {c['pinyin']} | {c['strokes']} | {c['radical']} | {c['words']} | {ctype} |")
    lines.append("")
    lines.append("---")
    lines.append("")
    
    # 复习字
    if review_chars:
        review_str = "、".join(c['character'] for c in review_chars)
        lines.append("## 复习字（L1已学，自然巩固）")
        lines.append("")
        lines.append(f"```\n{review_str}\n```")
        lines.append("")
        lines.append("---")
        lines.append("")
    
    # 故事脚本
    lines.append("## 故事脚本")
    lines.append("")
    
    # 封面页
    if pages:
        first_page_title = pages[0].get("desc", title)
    else:
        first_page_title = title
    lines.append("### 【封面】")
    lines.append("")
    lines.append(f"**画面**：{title}——{theme}。{first_page_title[:50]}...")
    lines.append("")
    lines.append(f"**文字**：{title}  ")
    lines.append("")
    lines.append("---")
    lines.append("")
    
    # 逐页脚本
    for p in pages:
        page_num = p["page_num"]
        desc = p.get("desc", "")
        text = p.get("text", "")
        pinyin = p.get("pinyin", "")
        new_chars = p.get("new_chars", "")
        
        lines.append(f"### 【第{page_num}页】")
        lines.append("")
        lines.append(f"**画面**：{desc}")
        lines.append("")
        lines.append("**文字**：")
        lines.append(f"> {text}")
        
        # New chars annotation
        if new_chars and new_chars != "无" and new_chars != "无（巩固）":
            # Bold the new characters in the text
            new_char_list = re.split(r'[、，,]', new_chars)
            new_char_list = [c.strip() for c in new_char_list if c.strip()]
            bold_text = text
            for nc in new_char_list:
                if nc in bold_text:
                    bold_text = bold_text.replace(nc, f"**{nc}**")
            lines.append(f"> **【新字：{new_chars}】**")
        elif "巩固" in new_chars:
            lines.append(f"> *（巩固复习页，无新字）*")
        else:
            lines.append(f"> *（无强制新字，图中自然识字）*")
        
        lines.append("")
        lines.append("**拼音**：")
        lines.append(f"> [{pinyin}]")
        lines.append("")
        lines.append("---")
        lines.append("")
    
    # 教育目标
    lines.append("## 教育目标总结")
    lines.append("")
    raw_edu = data.get("edu_goals", {}).get("raw", "")
    if raw_edu:
        # Parse the bullet points
        edu_bullets = raw_edu.strip().split("\n")
        for eb in edu_bullets:
            eb = eb.strip()
            if eb:
                lines.append(f"- {eb}")
    lines.append("")
    lines.append("---")
    lines.append("")
    
    # 配套练习
    if data["exercises"]:
        lines.append("## 配套练习设计（5题）")
        lines.append("")
        for i, ex in enumerate(data["exercises"], 1):
            lines.append(f"### 练习{i}")
            lines.append(f"> {ex}")
            lines.append("")
        lines.append("---")
        lines.append("")
    
    # 插画风格建议
    illus = data.get("illustration", {})
    lines.append("## 插画风格建议")
    lines.append("")
    lines.append("| 元素 | 要求 |")
    lines.append("|:---|:---|")
    lines.append(f"| 画风 | 温暖明亮，圆润的儿童插画风格 |")
    lines.append("| 配色 | 暖色调为主 |")
    lines.append("| 比例 | 人物占画面60%，背景简洁 |")
    lines.append("| 新字提示 | 新学字对应的物体/角色用暖黄色半透明气泡标注 |")
    
    if illus.get("风格要求"):
        lines.append(f"| 风格要求 | {illus['风格要求']} |")
    if illus.get("配色方案"):
        lines.append(f"| 配色方案 | {illus['配色方案']} |")
    if illus.get("主角设定"):
        lines.append(f"| 主角设定 | {illus['主角设定']} |")
    if illus.get("场景列表"):
        lines.append(f"| 场景列表 | {illus['场景列表']} |")
    
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("**创作状态**：✅ 绘本化文案v1已完成  ")
    lines.append("**下一步**：交付插画师进行分镜绘制  ")
    lines.append(f"**绘本编号**：L2_book_{book_num:02d}")
    lines.append("")
    
    return "\n".join(lines)


def parse_file_with_multiple_stories(filepath):
    """解析包含多篇故事的L2文件，返回 {book_num: story_text} 字典"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split by "# 第N篇：" headers
    stories = {}
    pattern = r'^# 第(\d+)篇[：:]\s*《(.+?)》'
    
    parts = re.split(r'(?=^# 第\d+篇)', content, flags=re.MULTILINE)
    
    for part in parts:
        match = re.match(pattern, part, re.MULTILINE)
        if match:
            num = int(match.group(1))
            stories[num] = part.strip()
    
    return stories


def parse_single_story_file(filepath, book_num):
    """解析单篇L2文件（L2-009/010格式不同）"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    return {book_num: content}


def main():
    # Define the 10 picture books and their source files
    book_sources = {
        1: ("L2-001_小马过河.md", 1),
        2: ("L2-001_小马过河.md", 2),
        3: ("L2-003_我去上学.md", 3),
        4: ("L2-003_我去上学.md", 4),
        5: ("L2-005_谁最聪明.md", 5),
        6: ("L2-005_谁最聪明.md", 6),
        7: ("L2-007_春天的故事.md", 7),
        8: ("L2-007_春天的故事.md", 8),
        9: ("L2-009_小青蛙找家.md", 9),
        10: ("L2-010_数字王国.md", 10),
    }
    
    results = []
    
    # Process files with 2 stories each
    multi_story_files = {
        "L2-001_小马过河.md": [1, 2],
        "L2-003_我去上学.md": [3, 4],
        "L2-005_谁最聪明.md": [5, 6],
        "L2-007_春天的故事.md": [7, 8],
    }
    
    all_stories = {}
    
    for filename, book_nums in multi_story_files.items():
        filepath = CONTENT_DIR / filename
        if filepath.exists():
            stories = parse_file_with_multiple_stories(str(filepath))
            for bn in book_nums:
                if bn in stories:
                    all_stories[bn] = stories[bn]
                else:
                    print(f"⚠️ Book {bn} not found in {filename}")
        else:
            print(f"❌ File not found: {filepath}")
    
    # Process single-story files (009, 010)
    for bn in [9, 10]:
        filename = book_sources[bn][0]
        filepath = CONTENT_DIR / filename
        if filepath.exists():
            stories = parse_single_story_file(str(filepath), bn)
            if bn in stories:
                all_stories[bn] = stories[bn]
            else:
                print(f"⚠️ Book {bn} not found in {filename}")
        else:
            print(f"❌ File not found: {filepath}")
    
    # Generate picture book files
    for bn in range(1, 11):
        if bn not in all_stories:
            print(f"❌ Missing story text for book {bn}")
            continue
        
        print(f"📖 Processing book {bn}...")
        data = parse_lesson_plan(all_stories[bn], bn)
        
        if not data["title"]:
            print(f"  ⚠️ Could not extract title for book {bn}")
            continue
        
        picturebook_md = generate_picturebook(data)
        
        # Create a safe filename
        safe_title = data["title"].replace("/", "_").replace(" ", "_")
        out_filename = f"绘本{bn:02d}-{safe_title}_L2文案v1.md"
        out_path = OUTPUT_DIR / out_filename
        
        with open(out_path, 'w', encoding='utf-8') as f:
            f.write(picturebook_md)
        
        print(f"  ✅ Generated: {out_filename}")
        print(f"     Title: {data['title']}")
        print(f"     Characters: {len(data['characters'])}")
        print(f"     Pages: {len(data['pages_content'])}")
        results.append(out_filename)
    
    print(f"\n✅ Done! Generated {len(results)} picture book files.")
    return results


if __name__ == "__main__":
    main()
