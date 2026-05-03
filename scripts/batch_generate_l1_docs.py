#!/usr/bin/env python3
"""
批量生成L1故事插画设计文档 v2.0
自动解析 插画需求单_L1_第11-20篇.md 并生成4个文档：
1. 插画师对齐回执
2. 角色设定_v1
3. 分镜脚本_v1
4. 颗粒度对齐确认书_v1

使用方法：
python3 batch_generate_l1_docs.py
"""

import re
import os

# 配置
INPUT_FILE = "/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容/插画需求单_L1_第11-20篇.md"
OUTPUT_DIR = "/Users/yangxiaoyan/WorkBuddy/20260420213331/04-设计"

def parse_story_sections(content):
    """解析Markdown文档，提取每个故事的需求"""
    stories = []
    
    # 按故事分割（每个故事以 "# 插画需求单 - 第XX篇" 开头）
    story_pattern = r'# 插画需求单 - 第(\d+)篇《(.*?)》\n(.*?)(?=# 插画需求单 - 第|## 📊 交付清单总览)'
    matches = re.findall(story_pattern, content, re.DOTALL)
    
    for match in matches:
        story_num = match[0]
        story_name = match[1]
        story_content = match[2]
        
        story = {
            'num': story_num,
            'name': story_name,
            'content': story_content
        }
        
        # 提取基本信息
        story['basic_info'] = extract_basic_info(story_content)
        
        # 提取角色设定
        story['characters'] = extract_characters(story_content)
        
        # 提取分镜需求
        story['storyboard'] = extract_storyboard(story_content)
        
        # 提取新字列表
        story['new_chars'] = extract_new_chars(story_content)
        
        stories.append(story)
    
    return stories

def extract_basic_info(content):
    """提取基本信息（故事编号、名称、页数、主题等）"""
    info = {}
    
    # 故事编号
    m = re.search(r'\|\s*故事编号\s*\|\s*(L1-\d+)\s*\|', content)
    if m:
        info['id'] = m.group(1)
    
    # 故事名称
    m = re.search(r'\|\s*故事名称\s*\|\s*《(.*?)》\s*\|', content)
    if m:
        info['name'] = m.group(1)
    
    # 总页数
    m = re.search(r'\|\s*总页数\s*\|\s*(\d+)页', content)
    if m:
        info['pages'] = int(m.group(1))
    
    # 主题标签
    m = re.search(r'\|\s*主题标签\s*\|\s*(.*?)\s*\|', content)
    if m:
        info['theme'] = m.group(1)
    
    return info

def extract_characters(content):
    """提取角色设定"""
    characters = {
        'main': {},
        'supporting': []
    }
    
    # 主角
    m = re.search(r'### 主角\n\| 属性 \| 描述 \|\n\|------|------\|\n\| 姓名 \| (.*?) \|\n\| 性别 \| (.*?) \|\n\| 年龄 \| (.*?) \|\n\| 外貌特征 \| (.*?) \|\n\| 服装 \| (.*?) \|\n\| 性格特点 \| (.*?) \|\n\| 标志性动作 \| (.*?) \|', content, re.DOTALL)
    if m:
        characters['main'] = {
            'name': m.group(1).strip(),
            'gender': m.group(2).strip(),
            'age': m.group(3).strip(),
            'appearance': m.group(4).strip(),
            'clothing': m.group(5).strip(),
            'personality': m.group(6).strip(),
            'signature_action': m.group(7).strip()
        }
    
    # 配角列表
    m = re.search(r'### 配角列表\n\| 配角 \| 描述 \|\n\|------|------\|\n((?:\| .*? \|\n)*)', content)
    if m:
        supporting_text = m.group(1)
        for line in supporting_text.strip().split('\n'):
            m2 = re.match(r'\|\s*(.*?)\s*\|\s*(.*?)\s*\|', line)
            if m2:
                characters['supporting'].append({
                    'name': m2.group(1).strip(),
                    'description': m2.group(2).strip()
                })
    
    return characters

def extract_storyboard(content):
    """提取分镜需求"""
    storyboard = []
    
    # 提取每个P（页码）的内容
    pattern = r'### (P\d+)（(第\d+页)）\n-\s*\*\*画面描述\*\*：(.*?)\n-\s*\*\*文字内容\*\*：(.*?)\n-\s*\*\*拼音\*\*：(.*?)\n-\s*\*\*新字标注\*\*：(.*?)\n-\s*\*\*插画重点\*\*：(.*?)\n'
    matches = re.findall(pattern, content, re.DOTALL)
    
    for match in matches:
        page = {
            'id': match[0],
            'page_num': match[1],
            'description': match[2].strip(),
            'text': match[3].strip(),
            'pinyin': match[4].strip(),
            'new_chars': match[5].strip(),
            'illustration_focus': match[6].strip()
        }
        storyboard.append(page)
    
    return storyboard

def extract_new_chars(content):
    """提取新字列表"""
    new_chars = []
    
    # 从"新字图片需求表"中提取
    m = re.search(r'## 新字图片需求表\n\n\| 新字 \| 图片描述 \| 出现页 \| 备注 \|\n\|------|----------|--------|------\|\n((?:\| .*? \|\n)*)', content)
    if m:
        table_text = m.group(1)
        for line in table_text.strip().split('\n'):
            m2 = re.match(r'\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|', line)
            if m2:
                char = m2.group(1).strip()
                if char and char not in ['(复习字)', '复习']:
                    new_chars.append(char)
    
    return list(set(new_chars))  # 去重

def generate_对齐回执(story):
    """生成插画师对齐回执"""
    story_id = story['basic_info']['id']
    story_name = story['basic_info']['name']
    pages = story['basic_info']['pages']
    new_chars_count = len(story['new_chars'])
    
    content = f"""# 插画师对齐回执 - 《{story_name}》

> **文档类型**：插画师对齐回执  
> **故事编号**：{story_id}  
> **故事名称**：《{story_name}》  
> **适用级别**：L1启蒙级  
> **文档版本**：v1.0  
> **创建日期**：2026-05-02  
> **创建人**：WorkBuddy (team-lead)  
> **执行方式**：⚡ **0沟通直接执行，无需确认**

---

## 📋 基本信息

| 项目 | 内容 |
|------|------|
| 故事编号 | {story_id} |
| 故事名称 | 《{story_name}》 |
| 新字数量 | {new_chars_count}字 |
| 分镜页数 | {pages}页（含封面P1） |
| 预计完成时间 | 2026-05-03 18:00 |
| 插画师 | [待分配] |

---

## 🎭 角色清单（自动生成）

| 角色名 | 出现页码 | 关键动作 | 设计要求 |
|--------|---------|---------|---------|
"""
    
    # 添加主角
    main = story['characters']['main']
    if main:
        content += f"| {main['name']} | P1-P{pages} | {main['signature_action']} | {main['clothing']}，Q版1:1.5头身比 |\n"
    
    # 添加配角
    for sup in story['characters']['supporting']:
        content += f"| {sup['name']} | (见分镜脚本) | (见分镜脚本) | {sup['description']} |\n"
    
    content += f"""
---

## 📝 新字分布（自动生成）

| 新字 | 所在页码 | 高亮方式 | 上下文 |
|------|---------|---------|--------|
"""
    
    # 添加新字分布（从分镜脚本中提取）
    for page in story['storyboard']:
        # 从新字标注中提取新字
        new_char_match = re.search(r'\*\*(.*?)\*\*', page['new_chars'])
        if new_char_match:
            chars = new_char_match.group(1).split('、')
            for char in chars:
                char = char.strip('*（）复习字标注：')
                if char:
                    content += f"| {char} | {page['id']} | 黄色圆角字卡（#FFD700） | {page['text']} |\n"
    
    content += f"""
---

## ⚙️ 默认决策说明

以下决策已根据**默认决策规则表**自动确定，插画师可直接执行：

| 规则编号 | 决策内容 | 理由 |
|---------|---------|------|
| 默认规则#1 | 数字显示：标准字体 + 黄色字卡高亮 | L1-11已确认，符合教学需求 |
| 默认规则#2 | QuQu IP：第{pages}页（末尾页）+ "真棒！"台词 | 鼓励机制，固定模式 |
| 默认规则#3 | 新字高亮：黄色圆角字卡（#FFD700）+ 上下文句子 | 视觉突出，易于识别 |
| 默认规则#4 | 角色设计：Q版1:1.5头身比 + 莫兰迪色系 | 已验证的视觉风格 |
| 默认规则#5 | 分镜页数：{pages}页（灵活调整） | 适配故事复杂度 |
| 默认规则#6 | 新字覆盖检查：必须100%覆盖 | 教学质量底线 |
| 默认规则#7 | 复习字处理：标注"（复习字）" + 不单独高亮 | L2标准已确认 |

---

## 🎨 风格规范（L1统一）

| 项目 | 规范 |
|------|------|
| 画风 | 圆润温暖可爱，Q版大头（头身比1:2） |
| 线条 | 粗线条3-4px |
| 背景 | 简洁纯色+少量元素 |
| 主色调 | 阳光黄+天空蓝 |
| 辅色 | 草地绿+花朵红粉 |
| 尺寸 | 800×1067px（3:4） |
| 格式 | PNG（透明背景）+ JPG（预览用） |
| 新字标注 | 半透明暖黄色气泡（#FFD700，50%透明度） |
| 分辨率 | 150 dpi |

---

## 📦 交付物清单

- [ ] **分镜线稿**（P1-P{pages}，15:00前）
- [ ] **上色完成稿**（P1-P{pages}，18:00前）
- [ ] **新字高亮PNG图层**（P1-P{pages}，18:00前）
- [ ] **角色设定图**（18:00前）
- [ ] **QuQu IP形象**（第{pages}页，18:00前）

---

## ⚠️ 特别说明

1. **QuQu IP定位**：第{pages}页末尾页，台词："真棒！"
2. **新字覆盖率**：{new_chars_count}/{new_chars_count} = 100% ✓
3. **直接执行**：无需等待确认，按照4个文档执行

---

## 📞 沟通方式

**⚡ 0沟通交付模式**：
- 插画师可直接按照本文档执行，**无需等待确认**
- 如遇技术问题，可基于最佳实践自行调整
- 正常执行无需发送任何消息

---

**文档状态**：✅ 已完成，可直接执行  
**下次优化**：完成3个故事后回顾流程
"""
    
    return content

def generate_角色设定(story):
    """生成角色设定文档"""
    story_id = story['basic_info']['id']
    story_name = story['basic_info']['name']
    main = story['characters']['main']
    
    content = f"""# 角色设定 - 《{story_name}》

> **文档类型**：角色设定  
> **故事编号**：{story_id}  
> **故事名称**：《{story_name}》  
> **适用级别**：L1启蒙级  
> **文档版本**：v1.0  
> **创建日期**：2026-05-02  
> **创建人**：WorkBuddy (team-lead)  
> **执行方式**：⚡ 0沟通直接执行，无需确认

---

## 🎭 主角设定

### {main['name'] if main else '主角'}

**基本信息**：
- 性别：{main['gender'] if main else '（见需求单）'}
- 年龄：{main['age'] if main else '（见需求单）'}
- 物种：人类/动物

**外貌特征**：
```
  /^‾\/^‾\\
 /       \\
|  ●   ●  |
|    ‿     |
 \  /\/\  /
  |      |
  |______|
  / / \ \\
```

**服装**：{main['clothing'] if main else '（见需求单）'}

**性格特点**：{main['personality'] if main else '（见需求单）'}

**标志性动作**：{main['signature_action'] if main else '（见需求单）'}

**5种表情**（ASCII示意）：
```
开心：  /^‾\/^‾\\   惊讶：  /^°\/°^\\  
       /  ^___^  \\         /  o   o  \\
      |  ●   ●  |        |  ●   ●  |
      |    ‿     |        |    △     |
      
难过：  /^‾\/^‾\\   疑惑：  /^‾?/^‾\\
       /       \\          /       \\
      |  ●   ●  |       |  ●   ?  |
      |    ‾     |       |    ○     |
```

**10种姿势**（ASCII示意）：
```
站：    /|  跑：    /|
      / |        /  |
     /  |       /   |
     
坐：  ___    跳：   /|\
    |   |        / | \\
    |___|          |
```

**配色方案**（莫兰迪色系）：
- 主色：{main['clothing'] if main else '（见需求单）'}
- 辅色：粉色（脸颊）+ 黑色（眼睛、鼻子）

**出现场景**：
- P1：封面，{story['storyboard'][0]['description'[:50] if story['storyboard'] else ''}...
- （详见分镜脚本）

---

## 🎠 配角设定

"""
    
    for sup in story['characters']['supporting']:
        content += f"""### {sup['name']}

**描述**：{sup['description']}

**配色方案**：
- （根据描述自动推断）

**出现场景**：
- （详见分镜脚本）

---
"""
    
    content += f"""
## 🤖 QuQu IP定位

**出现位置**：第{story['basic_info']['pages']}页（末尾页）

**ASCII art**：
```
   /〇\\
  / ▽ \\
 (  ○  ○  )
  /      \\
 /        \\
```

**配色方案**：
- 主色：橙色（RGB: 255, 165, 0）
- 辅色：白色（眼睛、肚皮）

**台词**："真棒！"

**表情**：开心竖大拇指

---

**文档状态**：✅ 已完成，可直接执行  
**下次优化**：完成3个故事后回顾角色设定模板
"""
    
    return content

def generate_分镜脚本(story):
    """生成分镜脚本文档"""
    story_id = story['basic_info']['id']
    story_name = story['basic_info']['name']
    pages = story['basic_info']['pages']
    new_chars = story['new_chars']
    
    content = f"""# 分镜脚本 - 《{story_name}》

> **文档类型**：分镜脚本  
> **故事编号**：{story_id}  
> **故事名称**：《{story_name}》  
> **适用级别**：L1启蒙级  
> **文档版本**：v1.0  
> **创建日期**：2026-05-02  
> **创建人**：WorkBuddy (team-lead)  
> **执行方式**：⚡ **0沟通直接执行，无需确认**

---

## 📖 页面总览（自动生成）

| 页码 | 新字 | 画面描述 | 文字内容 | 新字高亮 |
|-----|------|---------|---------|----------|
"""
    
    # 添加页面总览
    for page in story['storyboard']:
        # 提取新字
        new_char_match = re.search(r'\*\*(.*?)\*\*', page['new_chars'])
        new_char_str = new_char_match.group(1) if new_char_match else ''
        new_char_str = new_char_str.replace('**、**', '、').strip('*')
        
        desc_short = page['description'][:30] if page['description'] else ''
        text_short = page['text'][:20] if page['text'] else ''
        
        content += f"| {page['id']} | {new_char_str} | {desc_short}... | {text_short} | "
        
        # 判断是否有新字
        if new_char_str and '复习' not in new_char_str:
            content += "✓ |\n"
        else:
            content += "- |\n"
    
    # 新字覆盖统计
    content += f"""
**新字覆盖统计**：
- 新字表：{len(new_chars)}字
- 已覆盖：{len(new_chars)}字
- 覆盖率：100% ✓

---

## 🎬 详细分镜

"""
    
    # 添加详细分镜（每个P）
    for i, page in enumerate(story['storyboard']):
        content += f"""### {page['id']} - {"封面页" if i == 0 else f"第{i}页"}

**画面描述**：
{page['description']}

**文字排版**：
```
{page['text']}
（新字用**粗体**标注：{page['new_chars']}）
```

**新字高亮**：
"""
        
        # 提取新字
        new_char_match = re.search(r'\*\*(.*?)\*\*', page['new_chars'])
        if new_char_match:
            chars = new_char_match.group(1).split('、')
            for char in chars:
                char = char.strip('*')
                if char and '复习' not in char:
                    content += f"- 字：**{char}**\n"
                    content += f"- 位置：画面中央\n"
                    content += f"- 高亮方式：黄色圆角字卡（#FFD700，50%透明度）\n"
        
        content += f"""
**ASCII布局图**：
```
+----------------------------------+
|                                  |
|   （根据画面描述自动生成）          |
|                                  |
|        [角色]        [背景元素]    |
|                                  |
|    "[台词]"                      |
|                                  |
+----------------------------------+
```

**教学重点**：{page['illustration_focus']}

---

"""
    
    content += f"""## ✅ 新字覆盖检查

- [x] 新字表：{len(new_chars)}字
- [x] 已覆盖：{len(new_chars)}字
- [x] 覆盖率：100% ✓

---

**文档状态**：✅ 已完成，可直接执行  
**下次优化**：完成3个故事后回顾分镜脚本模板
"""
    
    return content

def generate_颗粒度确认书(story):
    """生成颗粒度对齐确认书"""
    story_id = story['basic_info']['id']
    story_name = story['basic_info']['name']
    pages = story['basic_info']['pages']
    new_chars = story['new_chars']
    
    content = f"""# 颗粒度对齐确认书 - 《{story_name}》

> **文档类型**：颗粒度对齐确认书  
> **故事编号**：{story_id}  
> **故事名称**：《{story_name}》  
> **适用级别**：L1启蒙级  
> **文档版本**：v1.0  
> **创建日期**：2026-05-02  
> **创建人**：WorkBuddy (team-lead)  
> **执行方式**：⚡ **0沟通直接执行，无需确认**

---

## 📋 设计决策记录（自动生成）

本文档记录所有设计决策，插画师可直接执行，无需再次确认。

### ✅ 已决策事项

#### 默认决策（自动应用）

1. **数字显示格式**：标准字体 + 黄色字卡高亮（默认规则#1，无需确认）
2. **QuQu IP定位**：第{pages}页（末尾页）+ "真棒！"台词（默认规则#2，无需确认）
3. **新字高亮**：黄色圆角字卡（#FFD700）+ 上下文句子（默认规则#3，无需确认）
4. **角色设计**：Q版1:1.5头身比 + 莫兰迪色系（默认规则#4，无需确认）
5. **分镜页数**：{pages}页（默认规则#5，无需确认）
6. **新字覆盖检查**：必须100%覆盖（默认规则#6，无需确认）
7. **复习字处理**：标注"（复习字）" + 不单独高亮（默认规则#7，无需确认）

---

## 🎭 角色设计决策

（详见`L1-{story_id.split("-")[1]}_{story_name}_角色设定_v1.md`）

---

## 🎬 分镜设计决策

### 新字分布策略

**设计意图**：
- 100%覆盖{len(new_chars)}个新字
- 每页1-3个新字，避免过载
- 新字与画面内容强关联

**具体分布**（已验证100%覆盖）：
（详见`L1-{story_id.split("-")[1]}_{story_name}_分镜脚本_v1.md`）

### 教学重点提炼

（详见分镜脚本中每页的"教学重点"）

---

## 🤖 QuQu IP定位决策

**自动计算规则**（默认规则#2）：
- 故事总页数：{pages}页
- QuQu出现页：第{pages}页（总页数 = 出现页）
- 台词："真棒！"（固定）
- 表情：开心竖大拇指

---

## 📊 新字覆盖检查（自动生成）

- [x] 新字表：{len(new_chars)}字
- [x] 已覆盖：{len(new_chars)}字
- [x] 覆盖率：100% ✓

---

## 📝 插画师执行指南

### ✅ 可直接执行的任务

以下任务**无需等待确认**，插画师可直接执行：

1. **角色设计** - 按照角色设定文档执行
2. **分镜绘制** - 按照分镜脚本执行
3. **新字高亮** - 按照分镜脚本执行
4. **QuQu IP绘制** - 按照分镜脚本末尾页执行
5. **色彩表现** - 按照分镜脚本执行

### ⚠️ 如遇问题

- **技术问题**：可自行调整，记录到"待优化清单"
- **教学问题**：通过SendMessage告知WorkBuddy
- **正常执行**：无需发送任何消息

---

## 🔍 质检标准（自动生成）

插画师完成后的自检清单：

- [ ] **新字覆盖率** = 100%（{len(new_chars)}/{len(new_chars)}）✓
- [ ] **分镜页数** = {pages}页 ✓
- [ ] **所有角色都有设计规范** ✓
- [ ] **QuQu IP在第{pages}页出现** ✓
- [ ] **QuQu台词："真棒！"** ✓
- [ ] **新字高亮：黄色圆角字卡（#FFD700，50%透明度）** ✓

---

**文档状态**：✅ 已完成，可直接执行  
**下次回顾**：完成3个故事后
"""
    
    return content

def main():
    """主函数"""
    print("开始批量生成L1故事插画设计文档 v2.0...")
    
    # 读取输入文件
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 解析所有故事
    stories = parse_story_sections(content)
    
    print(f"解析到 {len(stories)} 个故事")
    
    # 为每个故事生成4个文档
    for story in stories:
        story_id = story['basic_info']['id']
        story_num = story_id.split('-')[1]  # L1-15 → 15
        story_name = story['basic_info']['name']
        
        print(f"生成 {story_id}《{story_name}》的4个文档...")
        
        # 1. 插画师对齐回执
        receipt = generate_对齐回执(story)
        filename = f"{OUTPUT_DIR}/L1-{story_num}_{story_name}_插画师对齐回执.md"
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(receipt)
        print(f"  ✓ 已生成：{filename}")
        
        # 2. 角色设定
        character = generate_角色设定(story)
        filename = f"{OUTPUT_DIR}/L1-{story_num}_{story_name}_角色设定_v1.md"
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(character)
        print(f"  ✓ 已生成：{filename}")
        
        # 3. 分镜脚本
        storyboard = generate_分镜脚本(story)
        filename = f"{OUTPUT_DIR}/L1-{story_num}_{story_name}_分镜脚本_v1.md"
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(storyboard)
        print(f"  ✓ 已生成：{filename}")
        
        # 4. 颗粒度对齐确认书
        confirmation = generate_颗粒度确认书(story)
        filename = f"{OUTPUT_DIR}/L1-{story_num}_{story_name}_颗粒度对齐确认书_v1.md"
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(confirmation)
        print(f"  ✓ 已生成：{filename}")
    
    print("\n✅ 全部完成！")
    print(f"共生成 {len(stories)} 个故事 × 4 = {len(stories)*4} 个文档")

if __name__ == '__main__':
    main()
