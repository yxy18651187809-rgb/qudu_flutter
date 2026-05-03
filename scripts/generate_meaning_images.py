#!/usr/bin/env python3
"""
meaning_select 题型图片批量生成
为177道 meaning_select 题目生成图片（每个汉字一个图片）
使用 Pillow 生成简单清晰的彩色图标式图片
"""

import os
import json
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("❌ Pillow 未安装，请运行: pip3 install Pillow")
    exit(1)

# 配置
OUTPUT_DIR = "/Users/yangxiaoyan/WorkBuddy/20260420213331/03-后端/qudu-api/public/images/meaning"
CHAR_JSON = "/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容/L1完整字300_后端导入.json"
IMAGE_SIZE = (200, 200)
BG_COLOR = (255, 255, 255, 0)  # 透明背景

# 汉字→图片描述映射（用于生成简单图形）
# 如果没有具体描述，就用汉字本身+彩色背景
CHAR_DESCRIPTIONS = {
    # 身体部位
    "人": "人", "口": "口", "手": "手", "足": "足", "头": "头",
    "耳": "耳", "心": "心", "目": "目", "牙": "牙", "舌": "舌",
    "发": "发", "脸": "脸", "鼻": "鼻", "眉": "眉", "指": "指",
    "肚": "肚",
    # 形容
    "大": "大", "小": "小", "多": "多", "少": "少", "高": "高",
    "低": "低", "长": "长", "短": "短", "快": "快", "慢": "慢",
    "红": "红", "黄": "黄", "蓝": "蓝", "绿": "绿", "白": "白",
    "黑": "黑", "金": "金", "紫": "紫", "灰": "灰", "青": "青",
    # 代词
    "我": "我", "你": "你", "他": "他", "她": "她", "它": "它",
    # 食物
    "米": "米", "饭": "饭", "面": "面", "菜": "菜", "蛋": "蛋",
    "茶": "茶", "瓜": "瓜", "果": "果", "糖": "糖", "豆": "豆",
    "桃": "桃", "苹": "苹", "梨": "梨",
    # 衣物
    "衣": "衣", "裤": "裤", "鞋": "鞋", "帽": "帽",
    # 家具
    "门": "门", "窗": "窗", "床": "床", "桌": "桌", "椅": "椅",
    # 学习
    "书": "书", "笔": "笔", "纸": "纸", "字": "字", "文": "文",
    "数": "数", "语": "语", "音": "音", "图": "图", "歌": "歌",
    "故": "故", "事": "事",
    # 自然
    "山": "山", "水": "水", "火": "火", "木": "木", "土": "土",
    "日": "日", "月": "月", "星": "星", "云": "云", "雨": "雨",
    "雪": "雪", "风": "风", "雷": "雷",
    # 动物
    "牛": "牛", "羊": "羊", "马": "马", "鱼": "鱼", "鸟": "鸟",
    "虫": "虫", "猫": "猫", "狗": "狗", "兔": "兔", "鸡": "鸡",
    "鸭": "鸭", "猪": "猪", "猴": "猴", "蛙": "蛙", "龟": "龟",
    # 植物
    "花": "花", "草": "草", "树": "树", "叶": "叶", "根": "根",
    "种": "种",
    # 动作
    "吃": "吃", "喝": "喝", "走": "走", "跑": "跑", "跳": "跳",
    "看": "看", "听": "听", "说": "说", "读": "读", "写": "写",
    "画": "画", "唱": "唱", "笑": "笑", "哭": "哭", "打": "打",
    "开": "开", "关": "关", "进": "进", "出": "出", "上": "上",
    "下": "下", "前": "前", "后": "后", "左": "左", "右": "右",
    "来": "来", "去": "去", "起": "起", "坐": "坐", "站": "站",
    "睡": "睡", "醒": "醒", "刷": "刷", "洗": "洗", "穿": "穿",
    "脱": "脱", "拿": "拿", "放": "放", "找": "找", "给": "给",
    "用": "用", "做": "做", "提": "提", "拍": "拍", "骑": "骑",
    "游": "游", "钓": "钓", "浇": "浇", "吹": "吹", "种": "种",
    # 抽象
    "爱": "爱", "喜": "喜", "怕": "怕", "急": "急", "安": "安",
    "忙": "忙", "病": "病", "瘦": "瘦", "胖": "胖", "困": "困",
    "太": "太", "很": "很", "真": "真", "最": "最", "分": "分",
    # 其他
    "一": "一", "二": "二", "三": "三", "四": "四", "五": "五",
    "六": "六", "七": "七", "八": "八", "九": "九", "十": "十",
    "百": "百", "千": "千", "万": "万", "个": "个", "只": "只",
    "条": "条", "朵": "朵", "双": "双", "半": "半",
}

# 背景颜色列表（儿童友好色彩）
BG_COLORS = [
    (255, 200, 200),  # 浅红
    (255, 255, 200),  # 浅黄
    (200, 255, 200),  # 浅绿
    (200, 200, 255),  # 浅蓝
    (255, 200, 255),  # 浅紫
    (200, 255, 255),  # 浅青
    (255, 220, 180),  # 浅橙
    (220, 255, 180),  # 浅黄绿
]


def get_characters_from_json():
    """从JSON文件读取所有L1汉字"""
    with open(CHAR_JSON, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return [item['character'] for item in data]


def generate_image(char, output_path):
    """为单个汉字生成图片"""
    # 创建透明背景图片
    img = Image.new('RGBA', IMAGE_SIZE, BG_COLOR)
    draw = ImageDraw.Draw(img)
    
    # 选择背景颜色（基于字符hash）
    color_idx = hash(char) % len(BG_COLORS)
    bg_color = BG_COLORS[color_idx]
    
    # 绘制圆角矩形背景
    margin = 10
    draw.rounded_rectangle(
        [margin, margin, IMAGE_SIZE[0] - margin, IMAGE_SIZE[1] - margin],
        radius=20,
        fill=bg_color + (180,),  # 半透明
        outline=(50, 50, 50),
        width=2
    )
    
    # 尝试加载中文字体
    font_large = None
    font_paths = [
        '/System/Library/Fonts/PingFang.ttc',
        '/System/Library/Fonts/STHeiti Light.ttc',
        '/System/Library/Fonts/Hiragino Sans GB.ttc',
    ]
    for font_path in font_paths:
        if os.path.exists(font_path):
            try:
                font_large = ImageFont.truetype(font_path, 80)
                break
            except:
                continue
    
    if font_large is None:
        font_large = ImageFont.load_default()
    
    # 绘制汉字（居中）
    bbox = draw.textbbox((0, 0), char, font=font_large)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    x = (IMAGE_SIZE[0] - text_width) // 2
    y = (IMAGE_SIZE[1] - text_height) // 2 - 10
    
    # 绘制文字阴影
    draw.text((x + 2, y + 2), char, fill=(0, 0, 0, 100), font=font_large)
    # 绘制文字
    draw.text((x, y), char, fill=(50, 50, 50), font=font_large)
    
    # 保存
    img.save(output_path, 'PNG')
    return True


def main():
    print("=" * 60)
    print("meaning_select 题型图片批量生成")
    print("=" * 60)
    
    # 确保输出目录存在
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # 获取所有L1汉字
    all_chars = get_characters_from_json()
    print(f"\n📊 L1总字数: {len(all_chars)}")
    
    # 检查已存在的图片
    existing = {f.stem for f in Path(OUTPUT_DIR).glob("*.png")}
    print(f"📁 已存在图片: {len(existing)} 个")
    
    # 需要生成的
    to_generate = [c for c in all_chars if c not in existing]
    print(f"🎯 需要生成: {len(to_generate)} 个")
    
    if not to_generate:
        print("\n✅ 所有图片已生成，无需操作")
        return
    
    print(f"\n📂 输出目录: {OUTPUT_DIR}")
    print(f"🖼️  图片尺寸: {IMAGE_SIZE[0]}×{IMAGE_SIZE[1]}px")
    print(f"\n开始生成...")
    print("-" * 60)
    
    success = 0
    failed = 0
    
    for i, char in enumerate(to_generate, 1):
        output_path = os.path.join(OUTPUT_DIR, f"{char}.png")
        try:
            generate_image(char, output_path)
            print(f"[{i}/{len(to_generate)}] ✅ {char}")
            success += 1
        except Exception as e:
            print(f"[{i}/{len(to_generate)}] ❌ {char} - {e}")
            failed += 1
    
    # 统计
    print("\n" + "=" * 60)
    print("生成完成")
    print("=" * 60)
    print(f"✅ 成功: {success}")
    print(f"❌ 失败: {failed}")
    print(f"📁 总计图片文件: {len(existing) + success}")
    
    if failed > 0:
        print(f"\n⚠️  有 {failed} 个图片生成失败，请检查错误信息")


if __name__ == "__main__":
    main()
