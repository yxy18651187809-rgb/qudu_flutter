#!/usr/bin/env python3
"""
提取L4/L5教案中的插画需求单，生成汇总文档
"""

import re
import os

# 教案文件路径
base_dir = "/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容"
l4_files = [f"故事教案_71-80_L4-{i:03d}.md" for i in range(71, 81)]
l5_files = [f"故事教案_91-100_L5-{i:03d}.md" for i in range(91, 101)]

def extract_illustration_requirements(file_path):
    """提取插画需求单内容"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 提取故事信息
        story_info = {}
        
        # 提取编号和名称
        name_match = re.search(r'## 第(\d+)篇：《(.+?)》', content)
        if name_match:
            story_info['number'] = name_match.group(1)
            story_info['name'] = name_match.group(2)
        else:
            story_info['number'] = '未知'
            story_info['name'] = '未知'
        
        # 提取级别
        level_match = re.search(r'\*\*级别\*\*：(L\d+\s+\w+)', content)
        story_info['level'] = level_match.group(1) if level_match else '未知'
        
        # 提取新字数（表格格式）
        char_count_match = re.search(r'\| 新字数 \| (.+?) \|', content)
        story_info['char_count'] = char_count_match.group(1).strip() if char_count_match else '未知'
        
        # 提取页数（表格格式）
        page_match = re.search(r'\| 页数 \| (\d+页) \|', content)
        story_info['pages'] = page_match.group(1) if page_match else '未知'
        
        # 提取总字数（表格格式）
        total_chars_match = re.search(r'\| 总字数 \| (\d+字) \|', content)
        story_info['total_chars'] = total_chars_match.group(1) if total_chars_match else '未知'
        
        # 提取主题（表格格式）
        theme_match = re.search(r'\| 主题 \| ([^|]+) \|', content)
        story_info['theme'] = theme_match.group(1).strip() if theme_match else '未知'
        
        # 提取插画需求单
        illustration_match = re.search(r'【插画需求单】(.+?)(?=\n---|\n\*\*教研员交付确认)', content, re.DOTALL)
        
        if illustration_match:
            illustration_text = illustration_match.group(1).strip()
            story_info['illustration'] = illustration_text
            
            # 提取关键信息
            roles = re.search(r'\*\*角色\*\*：(.+)', illustration_text)
            scenes = re.search(r'\*\*场景\*\*：(.+)', illustration_text)
            highlights = re.search(r'\*\*新字高亮\*\*：(.+)', illustration_text)
            colors = re.search(r'\*\*配色\*\*：(.+)', illustration_text)
            special = re.search(r'\*\*(科学准确性|历史元素|特殊要求)\*\*：(.+)', illustration_text)
            
            story_info['roles'] = roles.group(1) if roles else ''
            story_info['scenes'] = scenes.group(1) if scenes else ''
            story_info['highlights'] = highlights.group(1) if highlights else ''
            story_info['colors'] = colors.group(1) if colors else ''
            story_info['special'] = special.group(1) if special else ''
        else:
            story_info['illustration'] = ''
            story_info['roles'] = ''
            story_info['scenes'] = ''
            story_info['highlights'] = ''
            story_info['colors'] = ''
            story_info['special'] = ''
        
        return story_info
    except Exception as e:
        print(f"处理文件 {file_path} 时出错: {e}")
        return None

def generate_summary(l4_data, l5_data):
    """生成汇总文档"""
    output = []
    output.append("# 字趣阅读 · L4/L5插画需求单汇总")
    output.append("")
    output.append("> **创建时间**：2026-05-06")
    output.append("> **创建人**：team-lead")
    output.append("> **说明**：汇总L4提升级（71-80篇）和L5进阶级（91-100篇）的插画需求")
    output.append("")
    output.append("---")
    output.append("")
    
    # L4部分
    output.append("## 一、L4提升级（第71-80篇）")
    output.append("")
    output.append("| 编号 | 故事名称 | 新字数 | 页数 | 主题 | 主要角色 | 场景 | 特殊要求 |")
    output.append("|------|----------|--------|------|------|----------|------|----------|")
    
    for data in l4_data:
        if data:
            name = data.get('name', '')
            number = data.get('number', '')
            char_count = data.get('char_count', '')
            pages = data.get('pages', '')
            theme = data.get('theme', '')
            roles = data.get('roles', '')
            scenes = data.get('scenes', '')
            special = data.get('special', '')
            
            row = f"| L4-{number} | 《{name}》 | {char_count} | {pages} | {theme} | {roles} | {scenes} | {special} |"
            output.append(row)
    
    output.append("")
    output.append("---")
    output.append("")
    
    # L5部分
    output.append("## 二、L5进阶级（第91-100篇）")
    output.append("")
    output.append("| 编号 | 故事名称 | 新字数 | 页数 | 主题 | 主要角色 | 场景 | 特殊要求 |")
    output.append("|------|----------|--------|------|------|----------|------|----------|")
    
    for data in l5_data:
        if data:
            name = data.get('name', '')
            number = data.get('number', '')
            char_count = data.get('char_count', '')
            pages = data.get('pages', '')
            theme = data.get('theme', '')
            roles = data.get('roles', '')
            scenes = data.get('scenes', '')
            special = data.get('special', '')
            
            row = f"| L5-{number} | 《{name}》 | {char_count} | {pages} | {theme} | {roles} | {scenes} | {special} |"
            output.append(row)
    
    output.append("")
    output.append("---")
    output.append("")
    
    # 详细插画需求单
    output.append("## 三、详细插画需求单")
    output.append("")
    
    # L4详细需求
    output.append("### 3.1 L4提升级详细需求")
    output.append("")
    
    for data in l4_data:
        if data and data.get('illustration'):
            output.append(f"#### L4-{data['name']}《{data['name']}》")
            output.append("")
            output.append("```")
            output.append(data['illustration'])
            output.append("```")
            output.append("")
    
    output.append("---")
    output.append("")
    
    # L5详细需求
    output.append("### 3.2 L5进阶级详细需求")
    output.append("")
    
    for data in l5_data:
        if data and data.get('illustration'):
            output.append(f"#### L5-{data['name']}《{data['name']}》")
            output.append("")
            output.append("```")
            output.append(data['illustration'])
            output.append("```")
            output.append("")
    
    output.append("")
    output.append("---")
    output.append("")
    output.append("**汇总完成时间**：2026-05-06")
    output.append("**下一步**：交付插画师，安排分批次绘制")
    
    return "\n".join(output)

# 主程序
l4_data = []
l5_data = []

print("开始提取L4教案...")
for filename in l4_files:
    file_path = os.path.join(base_dir, filename)
    print(f"处理: {filename}")
    data = extract_illustration_requirements(file_path)
    if data:
        l4_data.append(data)

print("\n开始提取L5教案...")
for filename in l5_files:
    file_path = os.path.join(base_dir, filename)
    print(f"处理: {filename}")
    data = extract_illustration_requirements(file_path)
    if data:
        l5_data.append(data)

print("\n生成汇总文档...")
output_content = generate_summary(l4_data, l5_data)

# 保存汇总文档
output_file = os.path.join(base_dir, "L4L5插画需求单汇总_v1.md")
with open(output_file, 'w', encoding='utf-8') as f:
    f.write(output_content)

print(f"\n✅ 汇总文档已保存: {output_file}")
print(f"L4教案处理: {len(l4_data)}/10")
print(f"L5教案处理: {len(l5_data)}/10")
