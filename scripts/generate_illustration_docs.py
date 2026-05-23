#!/usr/bin/env python3
"""
从L4/L5教案MD中提取数据，生成插画需求单MD文件。
参照L1插画需求单模板格式（插画需求单_L1_第11-20篇.md）。

输出：
- 插画需求单_L4_第65-84篇.md
- 插画需求单_L5_第85-104篇.md
"""

import re
import os
import glob

CONTENT_DIR = "/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容"
OUTPUT_DIR = CONTENT_DIR

# ============================================================
# 解析教案MD
# ============================================================

def parse_lesson(filepath):
    """解析单个教案MD，提取结构化数据"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    result = {}

    # 1. 提取故事编号和名称
    # 格式: # L4-065：《孔融让梨》 或 # L5-085：《论语故事》
    m = re.search(r'#\s*(?:字趣阅读APP\s*·\s*L\d+\w+级故事教案\s*\n##\s*)?(L\d+-\d+)[:：]《(.+?)》', content)
    if not m:
        m = re.search(r'(L\d+-\d+)[:：]《(.+?)》', content.split('\n')[0])
    if m:
        result['id'] = m.group(1)
        result['title'] = m.group(2)
    else:
        # Fallback from filename
        basename = os.path.basename(filepath)
        m2 = re.match(r'(L\d+-\d+)_(.+?)\.md', basename)
        if m2:
            result['id'] = m2.group(1)
            result['title'] = m2.group(2)
        else:
            return None

    # 2. 提取故事信息表
    info_section = re.split(r'##\s*一[、.]\s*故事信息表', content)
    if len(info_section) < 2:
        return None
    info_text = info_section[1]
    # 取到下一个 ## 之前
    info_text = re.split(r'\n##\s', info_text)[0]

    # 主题
    m = re.search(r'\|\s*主题\s*\|\s*(.+?)\s*\|', info_text)
    result['theme'] = m.group(1).strip() if m else ''

    # 新字数
    m = re.search(r'\|\s*新字数\s*\|\s*(.+?)\s*\|', info_text)
    result['new_char_count'] = m.group(1).strip() if m else ''

    # 页数
    m = re.search(r'\|\s*页数\s*\|\s*(\d+)', info_text)
    result['page_count'] = int(m.group(1)) if m else 0

    # 总字数
    m = re.search(r'\|\s*总字数\s*\|\s*(\d+)', info_text)
    result['total_words'] = int(m.group(1)) if m else 0

    # 级别
    result['level'] = result['id'].split('-')[0]

    # 3. 提取新字表
    char_section = re.split(r'##\s*二[、.]\s*新字表', content)
    chars = []
    if len(char_section) >= 2:
        char_text = re.split(r'\n##\s', char_section[1])[0]
        # 解析表格行: | 汉字 | 拼音 | 笔画 | 部首 | 组词示例 | 是否核心 | 备注 |
        for line in char_text.split('\n'):
            line = line.strip()
            if not line or line.startswith('|--') or line.startswith('| 汉字') or line.startswith('|--'):
                continue
            cells = [c.strip() for c in line.split('|')]
            cells = [c for c in cells if c]  # 去掉空元素
            if len(cells) >= 6:
                char_info = {
                    'char': cells[0],
                    'pinyin': cells[1],
                    'strokes': cells[2],
                    'radical': cells[3],
                    'example': cells[4],
                    'is_core': '是' in cells[5],
                    'note': cells[6] if len(cells) > 6 else ''
                }
                # 判断是否复习字（兼容多种格式）
                note = char_info['note']
                char_info['is_review'] = '复习' in note
                # 判断是否超纲/扩展
                char_info['is_extra'] = '超纲' in note or '扩展' in note
                chars.append(char_info)
    result['chars'] = chars

    # 4. 提取分页脚本
    script_section = re.split(r'##\s*三[、.]\s*故事正文（分页脚本）', content)
    pages = []
    if len(script_section) >= 2:
        script_text = re.split(r'\n##\s', script_section[1])[0]
        # 按 ### Page N 分割
        page_blocks = re.split(r'###\s*Page\s*(\d+)', script_text)
        for i in range(1, len(page_blocks), 2):
            page_num = int(page_blocks[i])
            block_text = page_blocks[i+1] if i+1 < len(page_blocks) else ''

            # 提取画面描述
            m_desc = re.search(r'【画面描述】(.+?)(?=\n【|$)', block_text, re.DOTALL)
            desc = m_desc.group(1).strip() if m_desc else ''

            # 提取文字
            m_text = re.search(r'【文字】(.+?)(?=\n【|$)', block_text, re.DOTALL)
            text = m_text.group(1).strip() if m_text else ''

            # 提取拼音
            m_pinyin = re.search(r'【拼音】(.+?)(?=\n【|$)', block_text, re.DOTALL)
            pinyin = m_pinyin.group(1).strip() if m_pinyin else ''

            # 提取新字标注（兼容两种格式）
            m_chars = re.search(r'【新字[标注]】(.+?)(?=\n|$)', block_text)
            new_chars = m_chars.group(1).strip() if m_chars else ''

            pages.append({
                'num': page_num,
                'desc': desc,
                'text': text,
                'pinyin': pinyin,
                'new_chars': new_chars
            })
    result['pages'] = pages

    # 5. 提取插画需求单中的额外信息
    illu_section = re.split(r'##\s*六[、.]\s*插画需求单', content)
    if len(illu_section) >= 2:
        illu_text = re.split(r'\n---', illu_section[1])[0]
        result['illustration_raw'] = illu_text.strip()
    else:
        result['illustration_raw'] = ''

    return result


def get_level_style(level):
    """返回不同级别的风格配置"""
    if level == 'L3':
        return {
            'level_name': 'L3发展级',
            'style': 'Q版可爱+丰富色彩，角色圆润亲切，场景饱满但不复杂，适合7-8岁',
            'line': '柔和线条2.5-3px，保持可爱感同时有一定细节',
            'colors': '色彩丰富鲜艳但不过于低幼，暖色调为主，根据主题灵活调整',
            'size': '800×1000px（4:5竖版）',
            'format': 'PNG（透明背景）+ JPG预览',
            'annotation': '半透明暖黄色气泡标注',
            'dpi': '150dpi'
        }
    elif level == 'L4':
        return {
            'level_name': 'L4提升级',
            'style': '中国风+现代融合，场景更丰富，角色表现力更强',
            'line': '中等线条2-3px，兼顾细节和可爱感',
            'colors': '根据故事主题变化（传统文化用中国风色调，科学主题用科技色调）',
            'size': '800×1000px（4:5竖版）',
            'format': 'PNG（透明背景）+ JPG预览',
            'annotation': '半透明暖黄色气泡标注',
            'dpi': '150dpi'
        }
    else:
        return {
            'level_name': 'L5进阶级',
            'style': '精致写实+插画风格，场景复杂度高，角色情感表达细腻',
            'line': '中等线条2px，注重细节和氛围感',
            'colors': '根据故事主题变化（传统文化用古朴色调，科学主题用科技色调）',
            'size': '800×1000px（4:5竖版）',
            'format': 'PNG（透明背景）+ JPG预览',
            'annotation': '半透明暖黄色气泡标注',
            'dpi': '150dpi'
        }


def get_theme_keywords(theme):
    """从主题中提取关键词，用于配色和场景建议"""
    if '传统' in theme or '文化' in theme:
        return '传统色系（赭石、墨色、朱红、金色）'
    elif '科学' in theme or '自然' in theme:
        return '科学自然色系（蓝色、绿色、白色）'
    elif '社交' in theme or '友谊' in theme:
        return '温暖社交色系（橙黄、粉色、浅蓝）'
    elif '成长' in theme:
        return '成长励志色系（明黄、天蓝、绿色）'
    elif '认知' in theme:
        return '明亮认知色系（多彩、对比鲜明）'
    elif '生活' in theme:
        return '温馨生活色系（暖橙、米白、浅粉）'
    else:
        return '温暖明亮色系'


def generate_overview_table(lessons, level_style):
    """生成概览表"""
    lines = []
    lines.append('## 📋 概览表\n')
    lines.append('| 编号 | 故事名 | 新字数 | 页数 | 主题 | 优先级 |')
    lines.append('|------|--------|--------|------|------|--------|')
    for ls in lessons:
        short_id = ls['id'].replace(f'{ls["level"]}-0', f'{ls["level"]}-')
        lines.append(f"| {ls['id']} | 《{ls['title']}》 | {ls['new_char_count']} | {ls['page_count']}页 | {ls['theme']} | P1 |")
    lines.append('')
    return '\n'.join(lines)


def generate_style_section(level_style):
    """生成风格统一规范section"""
    lines = []
    lines.append(f'## 🎨 {level_style["level_name"]}风格统一规范（所有篇目共用）\n')
    lines.append('| 项目 | 规范 |')
    lines.append('|------|------|')
    lines.append(f'| **画风** | {level_style["style"]} |')
    lines.append(f'| **线条** | {level_style["line"]} |')
    lines.append(f'| **配色** | {level_style["colors"]} |')
    lines.append(f'| **尺寸** | {level_style["size"]} |')
    lines.append(f'| **格式** | {level_style["format"]} |')
    lines.append(f'| **新字标注** | {level_style["annotation"]} |')
    lines.append(f'| **分辨率** | {level_style["dpi"]} |')
    lines.append('')
    return '\n'.join(lines)


def generate_single_book(ls, level_style):
    """为单篇故事生成插画需求单"""
    lines = []
    id_short = ls['id']

    # 标题
    lines.append(f'# 插画需求单 - {id_short}《{ls["title"]}》')
    lines.append('')

    # 基本信息
    lines.append('## 基本信息\n')
    lines.append('| 项目 | 内容 |')
    lines.append('|------|------|')
    lines.append(f'| 故事编号 | {ls["id"]} |')
    lines.append(f'| 故事名称 | 《{ls["title"]}》 |')
    lines.append(f'| 级别 | {ls["level"]} |')
    lines.append(f'| 总页数 | {ls["page_count"]}页 + 1封面 |')
    lines.append(f'| 主题标签 | {ls["theme"]} |')
    lines.append(f'| 优先级 | P1 |')
    lines.append('')

    # 新字统计
    core_chars = [c for c in ls['chars'] if c['is_core'] and not c['is_review'] and not c['is_extra']]
    review_chars = [c for c in ls['chars'] if c['is_review']]
    extra_chars = [c for c in ls['chars'] if c['is_extra'] and not c['is_review']]

    lines.append('## 新字概览\n')
    lines.append(f'- **新字总数**：{len(ls["chars"])}字')
    lines.append(f'- **核心新字**：{len(core_chars)}字（' + '、'.join([c['char'] for c in core_chars[:20]]) + ('...' if len(core_chars) > 20 else '') + '）')
    if review_chars:
        lines.append(f'- **跨级复习字**：{len(review_chars)}字（' + '、'.join([c['char'] for c in review_chars[:15]]) + ('...' if len(review_chars) > 15 else '') + '）')
    if extra_chars:
        lines.append(f'- **超纲/扩展字**：{len(extra_chars)}字（' + '、'.join([c['char'] for c in extra_chars[:15]]) + ('...' if len(extra_chars) > 15 else '') + '）')
    lines.append('')

    # 角色设定 - 从分页脚本和插画需求单中提取
    lines.append('## 角色设定\n')

    # 尝试从插画需求单中提取角色信息
    characters = extract_characters(ls)
    if characters:
        for i, char in enumerate(characters):
            if i == 0:
                lines.append('### 主角\n')
                lines.append('| 属性 | 描述 |')
                lines.append('|------|------|')
                lines.append(f'| 姓名 | {char["name"]} |')
                lines.append(f'| 描述 | {char["desc"]} |')
                lines.append('')
            else:
                lines.append(f'| 配角 | 描述 |')
                lines.append('|------|------|')
                lines.append(f'| {char["name"]} | {char["desc"]} |')
                lines.append('')
    else:
        lines.append('> 角色设定需教研员补充。\n')

    # 场景设定
    lines.append('## 场景设计\n')
    scenes = extract_scenes(ls)
    if scenes:
        for i, scene in enumerate(scenes, 1):
            lines.append(f'### 场景{i}（{scene["pages_range"]}）')
            lines.append(f'- 环境描述：{scene["desc"]}')
            lines.append(f'- 关键元素：{scene["elements"]}')
            lines.append(f'- 配色建议：{get_theme_keywords(ls["theme"])}')
            lines.append('')
    else:
        # 从分页脚本自动生成场景
        lines.append('> 场景需根据分页脚本画面描述整理，以下为自动提取：\n')
        for page in ls['pages'][:5]:
            if page['desc']:
                lines.append(f'- {page["desc"]}')
                lines.append('')
    lines.append('')

    # 分镜需求（核心部分）
    lines.append('## 分镜需求\n')

    # 封面
    if ls['pages']:
        first_page = ls['pages'][0]
        lines.append('### 封面')
        lines.append(f'- **画面描述**：{first_page["desc"] if first_page["desc"] else "参照第1页画面"}')
        lines.append(f'- **文字内容**：{ls["title"]}')
        lines.append(f'- **新字标注**：{first_page["new_chars"] if first_page["new_chars"] else "参照第1页新字"}')
        lines.append(f'- **插画重点**：故事主题元素突出，角色形象鲜明')
        lines.append('')

    # 逐页分镜
    for page in ls['pages']:
        lines.append(f'### P{page["num"]}（第{page["num"]}页）')
        if page['desc']:
            lines.append(f'- **画面描述**：{page["desc"]}')
        if page['text']:
            lines.append(f'- **文字内容**：{page["text"]}')
        if page['pinyin']:
            lines.append(f'- **拼音**：{page["pinyin"]}')
        if page['new_chars']:
            lines.append(f'- **新字标注**：{page["new_chars"]}')
        lines.append('')

    # 新字图片需求表
    lines.append('## 新字图片需求表\n')
    lines.append('| 新字 | 图片描述 | 出现页 | 备注 |')
    lines.append('|------|----------|--------|------|')

    # 建立新字→出现页的映射
    char_page_map = {}
    for page in ls['pages']:
        nc = page['new_chars']
        if nc and nc not in ['（复习字）', '复习字', '总结复习', '']:
            for ch in nc.replace('、', ',').replace('，', ',').split(','):
                ch = ch.strip()
                if ch and len(ch) <= 2:
                    if ch not in char_page_map:
                        char_page_map[ch] = []
                    char_page_map[ch].append(f"P{page['num']}")

    for c in ls['chars']:
        if c['is_extra'] and not c['is_core']:
            note = '超纲/扩展'
        elif c['is_review']:
            note = '复习字'
        else:
            note = '核心新字'
        pages_str = '、'.join(char_page_map.get(c['char'], ['—']))[:20]
        lines.append(f"| {c['char']} | {c['example']} | {pages_str} | {note} |")
    lines.append('')

    # 风格要求
    lines.append('## 风格要求')
    lines.append(f'- **画风**：{level_style["style"]}')
    lines.append(f'- **线条**：{level_style["line"]}')
    lines.append(f'- **配色**：{get_theme_keywords(ls["theme"])}')
    lines.append(f'- **尺寸**：{level_style["size"]}')
    lines.append(f'- **格式**：{level_style["format"]}')
    lines.append(f'- **新字标注**：{level_style["annotation"]}')
    lines.append('')

    return '\n'.join(lines)


def extract_characters(ls):
    """从教案中提取角色信息"""
    chars = []

    # 从插画需求单原始文本中提取
    raw = ls.get('illustration_raw', '')
    if raw:
        # 尝试提取角色设计
        m = re.search(r'角色设计\s*\n(.+?)(?:\n###|\n\d+\.|$)', raw, re.DOTALL)
        if m:
            char_text = m.group(1).strip()
            # 解析 "角色名（描述）、角色名（描述）" 格式
            parts = re.split(r'[、，,]', char_text)
            for part in parts:
                part = part.strip()
                if not part:
                    continue
                m2 = re.match(r'(.+?)[（(](.+?)[)）]', part)
                if m2:
                    chars.append({'name': m2.group(1).strip(), 'desc': m2.group(2).strip()})
                else:
                    chars.append({'name': part, 'desc': ''})

    # 如果没有从插画需求单提取到，从分页脚本画面描述中推断
    if not chars:
        # 收集所有画面描述中的角色名
        role_names = set()
        for page in ls['pages']:
            desc = page['desc']
            if '小明' in desc:
                role_names.add('小明')
            # 尝试提取引号内的人名
            for m in re.finditer(r'([\u4e00-\u9fff]{1,4})(?:（.+?）|老师|爸爸|妈妈|小朋友|教授|科学家)', desc):
                role_names.add(m.group(1))

        if '小明' in role_names:
            chars.append({'name': '小明', 'desc': '故事主角，根据场景穿着相应服装'})
            role_names.discard('小明')
        for name in sorted(role_names):
            chars.append({'name': name, 'desc': ''})

    return chars


def extract_scenes(ls):
    """从教案中提取场景信息"""
    scenes = []

    raw = ls.get('illustration_raw', '')
    if raw:
        m = re.search(r'场景设定\s*\n(.+?)(?:\n###|\n\d+\.|$)', raw, re.DOTALL)
        if m:
            scene_text = m.group(1).strip()
            parts = re.split(r'[、，,]', scene_text)
            scenes.append({
                'desc': scene_text,
                'elements': '',
                'pages_range': '全篇'
            })

    return scenes


def generate_delivery_table(lessons):
    """生成交付清单"""
    lines = []
    lines.append('## 📊 交付清单总览\n')
    lines.append('| 故事编号 | 封面 | 内页 | 新字图片 | 文件命名格式 |')
    lines.append('|----------|------|------|----------|--------------|')
    for ls in lessons:
        num = get_id_num(ls['id'])
        lines.append(f"| {ls['id']} | ✓ | {ls['page_count']}页 | {len(ls['chars'])}张 | story_{num}_* |")
    lines.append('')
    lines.append('### 文件命名规范')
    lines.append('```')
    lines.append('story_XX_cover.png          # 封面')
    lines.append('story_XX_page01.png        # 第1页')
    lines.append('story_XX_page02.png        # 第2页')
    lines.append('...')
    lines.append('story_XX_character.png     # 角色设定图')
    lines.append('story_XX_spritesheet.png   # 角色表情/动作素材表')
    lines.append('story_XX_char_XX.png      # 新字图片素材')
    lines.append('```')
    lines.append('')
    lines.append('### 尺寸与格式要求')
    lines.append('- **尺寸**：800×1000px（4:5竖版比例）')
    lines.append('- **格式**：PNG（透明背景）+ JPG（预览用）')
    lines.append('- **色彩模式**：sRGB')
    lines.append('- **分辨率**：150dpi')
    lines.append('')
    return '\n'.join(lines)


def get_id_num(lesson_id):
    """从lesson id中提取编号数字，如 L4-065 -> 065"""
    m = re.search(r'(\d+)$', lesson_id)
    return m.group(1) if m else '0'


def generate_full_doc(lessons, level):
    """生成完整的插画需求单文档"""
    level_style = get_level_style(level)

    lines = []
    # 文档头
    first_num = get_id_num(lessons[0]['id'])
    last_num = get_id_num(lessons[-1]['id'])
    lines.append(f'# 字趣阅读 · 插画需求汇总 - {level_style["level_name"]}第{first_num}-{last_num}篇')
    lines.append('')
    lines.append(f'> **版本**：v1.0')
    lines.append(f'> **创建日期**：2026-05-18')
    lines.append(f'> **创建人**：教研员-插画需求整合')
    lines.append(f'> **适用范围**：{level_style["level_name"]}第{first_num}-{last_num}篇故事插画制作')
    lines.append('')
    lines.append('---')
    lines.append('')

    # 概览表
    lines.append(generate_overview_table(lessons, level_style))
    lines.append('---')

    # 风格规范
    lines.append(generate_style_section(level_style))
    lines.append('---')

    # 逐篇需求单
    for ls in lessons:
        lines.append(generate_single_book(ls, level_style))
        lines.append('---')
        lines.append('---')

    # 交付清单
    lines.append(generate_delivery_table(lessons))
    lines.append('')
    lines.append('---')
    lines.append('')
    lines.append(f'**文档版本**：v1.0')
    lines.append(f'**创建日期**：2026-05-18')
    lines.append(f'**编写人**：教研员-插画需求整合')
    lines.append(f'**适用范围**：字趣阅读APP {level_style["level_name"]}第{first_num}-{last_num}篇故事插画制作')
    lines.append('')

    return '\n'.join(lines)


# ============================================================
# 主流程
# ============================================================

def process_level(level, file_pattern, output_name_pattern):
    """处理单个级别的教案，生成插画需求单"""
    files = sorted(glob.glob(os.path.join(CONTENT_DIR, file_pattern)))
    print(f"找到 {level} 教案: {len(files)} 个")

    lessons = []
    for f in files:
        lesson = parse_lesson(f)
        if lesson:
            lessons.append(lesson)
            print(f"  解析成功: {lesson['id']}《{lesson['title']}》- {len(lesson['chars'])}字, {lesson['page_count']}页")
        else:
            print(f"  解析失败: {f}")

    if lessons:
        doc = generate_full_doc(lessons, level)
        first_num = get_id_num(lessons[0]['id'])
        last_num = get_id_num(lessons[-1]['id'])
        output = os.path.join(OUTPUT_DIR, output_name_pattern.format(first=first_num, last=last_num))
        with open(output, 'w', encoding='utf-8') as f:
            f.write(doc)
        print(f"\n✅ {level}文档已生成: {output}")
        print(f"   总计 {len(lessons)} 篇, {len(doc)} 字符")
        return output
    return None


def main():
    # 处理L3 (045-064) — 使用通配模式，实际只有20个文件
    l3_output = process_level('L3', 'L3-0[4-6][0-9]_*.md', '插画需求单_L3_第{first}-{last}篇.md')

    # 处理L4 (065-084)
    l4_output = process_level('L4', 'L4-*.md', '插画需求单_L4_第{first}-{last}篇.md')

    # 处理L5 (085-104)
    l5_output = process_level('L5', 'L5-*.md', '插画需求单_L5_第{first}-{last}篇.md')


if __name__ == '__main__':
    main()
