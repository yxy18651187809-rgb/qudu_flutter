#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成字趣阅读绘本封面图
使用Pillow创建10本绘本的封面（01-10）
"""

from PIL import Image, ImageDraw, ImageFont
import os
import random
import math

# 输出目录
OUTPUT_DIR = "/Users/yangxiaoyan/WorkBuddy/20260420213331/04-设计"

# 封面尺寸 (竖版绘本书籍)
WIDTH = 800
HEIGHT = 1000

# 趣趣IP颜色 (来自IP规范)
QUQU_BODY = (197, 225, 165)  # #C5E1A5 淡黄绿
QUQU_BELLY = (255, 248, 225)  # #FFF8E1 乳白
QUQU_BLUSH = (255, 171, 145)  # #FFAB91 粉红
QUQU_LEAF = (139, 195, 74)   # #8BC34A 春绿


def draw_ququ(draw, x, y, size=100):
    """绘制简化的趣趣IP形象"""
    # 身体 (椭圆)
    body_width = size
    body_height = int(size * 0.7)
    
    # 头部 (圆形)
    head_radius = int(size * 0.4)
    head_x = x
    head_y = y - head_radius
    
    # 画头部 (淡黄色)
    draw.ellipse([
        head_x - head_radius, head_y - head_radius,
        head_x + head_radius, head_y + head_radius
    ], fill=QUQU_BODY, outline=(100, 150, 50), width=2)
    
    # 画眼睛
    eye_radius = int(head_radius * 0.2)
    eye_y = head_y - eye_radius * 0.5
    # 左眼
    draw.ellipse([
        head_x - head_radius * 0.4 - eye_radius,
        eye_y - eye_radius,
        head_x - head_radius * 0.4 + eye_radius,
        eye_y + eye_radius
    ], fill=(33, 33, 33))  # 黑色瞳孔
    # 右眼
    draw.ellipse([
        head_x + head_radius * 0.4 - eye_radius,
        eye_y - eye_radius,
        head_x + head_radius * 0.4 + eye_radius,
        eye_y + eye_radius
    ], fill=(33, 33, 33))
    
    # 画高光
    highlight_radius = int(eye_radius * 0.4)
    draw.ellipse([
        head_x - head_radius * 0.4 - highlight_radius + 2,
        eye_y - highlight_radius + 2,
        head_x - head_radius * 0.4 + highlight_radius + 2,
        eye_y + highlight_radius + 2
    ], fill=(255, 255, 255))
    
    draw.ellipse([
        head_x + head_radius * 0.4 - highlight_radius + 2,
        eye_y - highlight_radius + 2,
        head_x + head_radius * 0.4 + highlight_radius + 2,
        eye_y + highlight_radius + 2
    ], fill=(255, 255, 255))
    
    # 画嘴巴 (微笑曲线)
    draw.arc([
        head_x - head_radius * 0.3,
        head_y + head_radius * 0.1,
        head_x + head_radius * 0.3,
        head_y + head_radius * 0.5
    ], start=0, end=180, fill=(33, 33, 33), width=2)
    
    # 画腮红
    blush_radius = int(head_radius * 0.25)
    # 左腮红
    draw.ellipse([
        head_x - head_radius * 0.7 - blush_radius,
        head_y + head_radius * 0.2 - blush_radius,
        head_x - head_radius * 0.7 + blush_radius,
        head_y + head_radius * 0.2 + blush_radius
    ], fill=QUQU_BLUSH)
    # 右腮红
    draw.ellipse([
        head_x + head_radius * 0.7 - blush_radius,
        head_y + head_radius * 0.2 - blush_radius,
        head_x + head_radius * 0.7 + blush_radius,
        head_y + head_radius * 0.2 + blush_radius
    ], fill=QUQU_BLUSH)
    
    # 画头顶叶子
    leaf_size = int(head_radius * 0.8)
    leaf_x = head_x
    leaf_y = head_y - head_radius - 5
    draw.ellipse([
        leaf_x - leaf_size // 2,
        leaf_y - leaf_size // 2,
        leaf_x + leaf_size // 2,
        leaf_y + leaf_size // 2
    ], fill=QUQU_LEAF, outline=(100, 150, 50), width=2)
    
    # 画身体 (简化，一节)
    body_x = head_x
    body_top = head_y + head_radius * 0.8
    draw.ellipse([
        body_x - body_width // 2,
        body_top,
        body_x + body_width // 2,
        body_top + body_height
    ], fill=QUQU_BODY, outline=(100, 150, 50), width=2)


def create_cover_01():
    """绘本01《我的身体》封面"""
    img = Image.new('RGB', (WIDTH, HEIGHT), color=(255, 248, 225))  # 温暖米白
    draw = ImageDraw.Draw(img)
    
    # 背景渐变效果 (简单模拟)
    for i in range(HEIGHT):
        color_val = int(255 - (i / HEIGHT) * 20)
        draw.line([(0, i), (WIDTH, i)], fill=(color_val, color_val - 10, color_val - 20))
    
    # 添加装饰元素 - 彩虹条纹 (代表身体的多样性)
    rainbow_colors = [
        (255, 100, 100),  # 红
        (255, 180, 50),   # 橙
        (255, 255, 50),   # 黄
        (100, 255, 100),  # 绿
        (100, 180, 255),  # 蓝
        (200, 100, 255),  # 紫
    ]
    
    stripe_height = 40
    for i, color in enumerate(rainbow_colors):
        y_start = HEIGHT - 150 + i * stripe_height
        draw.rectangle([(50, y_start), (WIDTH - 50, y_start + stripe_height - 5)], fill=color)
    
    # 绘制趣趣在中间
    draw_ququ(draw, WIDTH // 2, HEIGHT // 2 - 100, size=120)
    
    # 添加书名
    try:
        font_large = ImageFont.truetype("/System/Library/Fonts/STHeiti Light.ttc", 72)
        font_small = ImageFont.truetype("/System/Library/Fonts/STHeiti Light.ttc", 36)
    except:
        try:
            font_large = ImageFont.truetype("/System/Library/Fonts/STHeiti Medium.ttc", 72)
            font_small = ImageFont.truetype("/System/Library/Fonts/STHeiti Medium.ttc", 36)
        except:
            font_large = ImageFont.load_default()
            font_small = ImageFont.load_default()
    
    title = "我的身体"
    bbox = draw.textbbox((0, 0), title, font=font_large)
    text_width = bbox[2] - bbox[0]
    text_x = (WIDTH - text_width) // 2
    text_y = HEIGHT // 2 + 80
    
    # 画标题背景
    draw.rounded_rectangle([
        text_x - 20, text_y - 10,
        text_x + text_width + 20, text_y + 80
    ], radius=15, fill=(255, 255, 255, 200), outline=(255, 100, 100), width=3)
    
    draw.text((text_x, text_y), title, fill=(230, 50, 50), font=font_large)
    
    # 添加L1级别标识
    level_text = "L1 · 启蒙"
    bbox2 = draw.textbbox((0, 0), level_text, font=font_small)
    level_width = bbox2[2] - bbox2[0]
    draw.text(((WIDTH - level_width) // 2, HEIGHT // 2 + 180), level_text,
              fill=(100, 100, 100), font=font_small)
    
    # 保存
    output_path = os.path.join(OUTPUT_DIR, "book_cover_01.png")
    img.save(output_path, "PNG")
    print(f"✅ 已生成: {output_path}")
    return output_path


def create_cover_02():
    """绘本02《早上好》封面"""
    img = Image.new('RGB', (WIDTH, HEIGHT), color=(255, 240, 200))  # 朝阳色
    draw = ImageDraw.Draw(img)
    
    # 背景 - 天空渐变 (从上到下，从深蓝到浅橙)
    for i in range(HEIGHT):
        ratio = i / HEIGHT
        if ratio < 0.5:
            r = int(50 + ratio * 2 * 100)
            g = int(100 + ratio * 2 * 150)
            b = int(200 + ratio * 2 * 55)
        else:
            r = int(150 + (ratio - 0.5) * 2 * 105)
            g = int(200 + (ratio - 0.5) * 2 * 55)
            b = int(255 - (ratio - 0.5) * 2 * 55)
        draw.line([(0, i), (WIDTH, i)], fill=(r, g, b))
    
    # 画太阳
    sun_radius = 80
    sun_x = WIDTH - 150
    sun_y = 150
    draw.ellipse([
        sun_x - sun_radius, sun_y - sun_radius,
        sun_x + sun_radius, sun_y + sun_radius
    ], fill=(255, 200, 50), outline=(255, 150, 0), width=3)
    
    # 太阳光芒
    for angle in range(0, 360, 30):
        x1 = sun_x + int((sun_radius + 10) * math.cos(math.radians(angle)))
        y1 = sun_y + int((sun_radius + 10) * math.sin(math.radians(angle)))
        x2 = sun_x + int((sun_radius + 40) * math.cos(math.radians(angle)))
        y2 = sun_y + int((sun_radius + 40) * math.sin(math.radians(angle)))
        draw.line([(x1, y1), (x2, y2)], fill=(255, 200, 50), width=4)
    
    # 画云朵
    def draw_cloud(x, y, size):
        cloud_color = (255, 255, 255)
        draw.ellipse([x - size, y - size // 2, x + size, y + size // 2], fill=cloud_color)
        draw.ellipse([x - size * 1.5, y - size // 3, x - size * 0.5, y + size // 3], fill=cloud_color)
        draw.ellipse([x + size * 0.5, y - size // 3, x + size * 1.5, y + size // 3], fill=cloud_color)
    
    draw_cloud(150, 200, 40)
    draw_cloud(300, 180, 30)
    draw_cloud(500, 220, 35)
    
    # 绘制趣趣 (在中间偏下)
    draw_ququ(draw, WIDTH // 2, HEIGHT // 2 + 100, size=110)
    
    # 添加书名
    try:
        font_large = ImageFont.truetype("/System/Library/Fonts/STHeiti Light.ttc", 72)
        font_small = ImageFont.truetype("/System/Library/Fonts/STHeiti Light.ttc", 36)
    except:
        try:
            font_large = ImageFont.truetype("/System/Library/Fonts/STHeiti Medium.ttc", 72)
            font_small = ImageFont.truetype("/System/Library/Fonts/STHeiti Medium.ttc", 36)
        except:
            font_large = ImageFont.load_default()
            font_small = ImageFont.load_default()
    
    title = "早上好"
    bbox = draw.textbbox((0, 0), title, font=font_large)
    text_width = bbox[2] - bbox[0]
    text_x = (WIDTH - text_width) // 2
    text_y = HEIGHT // 2 - 150
    
    # 画标题背景 (半透明白色)
    img_with_alpha = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw_alpha = ImageDraw.Draw(img_with_alpha)
    draw_alpha.rounded_rectangle([
        text_x - 20, text_y - 10,
        text_x + text_width + 20, text_y + 80
    ], radius=15, fill=(255, 255, 255, 180))
    img = Image.alpha_composite(img.convert('RGBA'), img_with_alpha).convert('RGB')
    draw = ImageDraw.Draw(img)
    
    draw.text((text_x, text_y), title, fill=(255, 120, 0), font=font_large)
    
    # 添加L1级别标识
    level_text = "L1 · 启蒙"
    bbox2 = draw.textbbox((0, 0), level_text, font=font_small)
    level_width = bbox2[2] - bbox2[0]
    draw.text(((WIDTH - level_width) // 2, HEIGHT - 120), level_text,
              fill=(100, 100, 100), font=font_small)
    
    # 保存
    output_path = os.path.join(OUTPUT_DIR, "book_cover_02.png")
    img.save(output_path, "PNG")
    print(f"✅ 已生成: {output_path}")
    return output_path


def create_cover_03():
    """绘本03《小兔子找妈妈》封面"""
    img = Image.new('RGB', (WIDTH, HEIGHT), color=(200, 230, 200))  # 森林绿
    draw = ImageDraw.Draw(img)
    
    # 背景 - 森林
    # 画草地
    draw.rectangle([(0, HEIGHT - 300), (WIDTH, HEIGHT)], fill=(100, 180, 100))
    
    # 画树木 (简化)
    def draw_tree(x, y, size):
        # 树干
        trunk_width = size // 3
        trunk_height = size
        draw.rectangle([
            x - trunk_width // 2, y - trunk_height,
            x + trunk_width // 2, y
        ], fill=(139, 90, 43))
        
        # 树冠 (圆形)
        crown_radius = size // 2
        draw.ellipse([
            x - crown_radius, y - trunk_height - crown_radius,
            x + crown_radius, y - trunk_height + crown_radius
        ], fill=(34, 139, 34))
    
    draw_tree(100, HEIGHT - 300, 150)
    draw_tree(300, HEIGHT - 320, 180)
    draw_tree(600, HEIGHT - 300, 160)
    draw_tree(750, HEIGHT - 310, 140)
    
    # 画花朵
    def draw_flower(x, y, size, color):
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            draw.ellipse([
                x + dx * size - size // 2,
                y + dy * size - size // 2,
                x + dx * size + size // 2,
                y + dy * size + size // 2
            ], fill=color)
        draw.ellipse([x - size // 3, y - size // 3, x + size // 3, y + size // 3], fill=(255, 255, 0))
    
    draw_flower(200, HEIGHT - 250, 15, (255, 182, 193))
    draw_flower(400, HEIGHT - 280, 18, (255, 255, 255))
    draw_flower(550, HEIGHT - 260, 16, (255, 182, 193))
    draw_flower(700, HEIGHT - 240, 14, (255, 255, 255))
    
    # 绘制趣趣扮演小兔子 (添加兔子耳朵)
    ququ_x = WIDTH // 2
    ququ_y = HEIGHT // 2
    
    # 画兔子耳朵 (长椭圆形)
    draw.ellipse([ququ_x - 60, ququ_y - 200, ququ_x - 30, ququ_y - 80], fill=(255, 240, 240), outline=(200, 180, 180), width=2)
    draw.ellipse([ququ_x + 30, ququ_y - 200, ququ_x + 60, ququ_y - 80], fill=(255, 240, 240), outline=(200, 180, 180), width=2)
    
    # 画趣趣身体
    draw_ququ(draw, ququ_x, ququ_y, size=100)
    
    # 添加书名
    try:
        font_large = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 60)
        font_small = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 36)
    except:
        font_large = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    title = "小兔子找妈妈"
    bbox = draw.textbbox((0, 0), title, font=font_large)
    text_width = bbox[2] - bbox[0]
    text_x = (WIDTH - text_width) // 2
    text_y = 100
    
    # 画标题背景
    draw.rounded_rectangle([
        text_x - 20, text_y - 10,
        text_x + text_width + 20, text_y + 70
    ], radius=15, fill=(255, 255, 255, 200), outline=(139, 90, 43), width=3)
    
    draw.text((text_x, text_y), title, fill=(139, 90, 43), font=font_large)
    
    # 添加L1级别标识
    level_text = "L1 · 启蒙"
    bbox2 = draw.textbbox((0, 0), level_text, font=font_small)
    level_width = bbox2[2] - bbox2[0]
    draw.text(((WIDTH - level_width) // 2, HEIGHT - 100), level_text,
              fill=(100, 100, 100), font=font_small)
    
    # 保存
    output_path = os.path.join(OUTPUT_DIR, "book_cover_03.png")
    img.save(output_path, "PNG")
    print(f"✅ 已生成: {output_path}")
    return output_path


def create_cover_04():
    """绘本04《一二三上学去》封面"""
    img = Image.new('RGB', (WIDTH, HEIGHT), color=(255, 250, 200))  # 校园黄
    draw = ImageDraw.Draw(img)
    
    # 背景 - 校园场景
    # 画天空
    for i in range(HEIGHT // 2):
        draw.line([(0, i), (WIDTH, i)], fill=(135, 206, 235))
    
    # 画地面
    draw.rectangle([(0, HEIGHT // 2), (WIDTH, HEIGHT)], fill=(144, 238, 144))
    
    # 画学校建筑 (简化)
    building_color = (255, 220, 180)
    # 主楼
    draw.rectangle([(WIDTH // 2 - 150, HEIGHT // 2 - 200), (WIDTH // 2 + 150, HEIGHT // 2 + 50)], fill=building_color, outline=(200, 150, 100), width=3)
    # 屋顶
    draw.polygon([
        (WIDTH // 2 - 180, HEIGHT // 2 - 200),
        (WIDTH // 2 + 180, HEIGHT // 2 - 200),
        (WIDTH // 2, HEIGHT // 2 - 280)
    ], fill=(200, 150, 100))
    
    # 窗户
    for i in range(3):
        wx = WIDTH // 2 - 80 + i * 80
        draw.rectangle([(wx, HEIGHT // 2 - 150), (wx + 50, HEIGHT // 2 - 100)], fill=(135, 206, 235), outline=(200, 150, 100), width=2)
    
    # 门
    draw.rectangle([(WIDTH // 2 - 30, HEIGHT // 2 - 50), (WIDTH // 2 + 30, HEIGHT // 2 + 50)], fill=(139, 90, 43), outline=(100, 70, 30), width=2)
    
    # 画书包 (趣趣背着书包)
    draw_ququ(draw, WIDTH // 2, HEIGHT // 2 + 150, size=100)
    
    # 画书包 (红色)
    bag_x = WIDTH // 2 + 60
    bag_y = HEIGHT // 2 + 100
    draw.rectangle([
        bag_x - 30, bag_y - 40,
        bag_x + 30, bag_y + 50
    ], fill=(255, 50, 50), outline=(200, 0, 0), width=2)
    # 书包带子
    draw.line([(bag_x - 20, bag_y - 40), (bag_x - 40, bag_y - 80)], fill=(200, 0, 0), width=3)
    draw.line([(bag_x + 20, bag_y - 40), (bag_x + 40, bag_y - 80)], fill=(200, 0, 0), width=3)
    
    # 添加书名
    try:
        font_large = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 56)
        font_small = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 36)
    except:
        font_large = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    title = "一二三上学去"
    bbox = draw.textbbox((0, 0), title, font=font_large)
    text_width = bbox[2] - bbox[0]
    text_x = (WIDTH - text_width) // 2
    text_y = HEIGHT // 2 + 250
    
    # 画标题背景
    draw.rounded_rectangle([
        text_x - 20, text_y - 10,
        text_x + text_width + 20, text_y + 66
    ], radius=15, fill=(255, 255, 255, 200), outline=(255, 50, 50), width=3)
    
    draw.text((text_x, text_y), title, fill=(255, 50, 50), font=font_large)
    
    # 添加L1级别标识
    level_text = "L1 · 启蒙"
    bbox2 = draw.textbbox((0, 0), level_text, font=font_small)
    level_width = bbox2[2] - bbox2[0]
    draw.text(((WIDTH - level_width) // 2, HEIGHT - 100), level_text,
              fill=(100, 100, 100), font=font_small)
    
    # 保存
    output_path = os.path.join(OUTPUT_DIR, "book_cover_04.png")
    img.save(output_path, "PNG")
    print(f"✅ 已生成: {output_path}")
    return output_path


def create_cover_05():
    """绘本05《红红的太阳》封面"""
    img = Image.new('RGB', (WIDTH, HEIGHT), color=(255, 200, 100))  # 暖橙色
    draw = ImageDraw.Draw(img)
    
    # 背景 - 温暖的太阳光辉
    center_x = WIDTH // 2
    center_y = HEIGHT // 2
    
    for y in range(HEIGHT):
        for x in range(WIDTH):
            dist = ((x - center_x) ** 2 + (y - center_y) ** 2) ** 0.5
            max_dist = (WIDTH ** 2 + HEIGHT ** 2) ** 0.5 / 2
            ratio = dist / max_dist
            
            r = int(255 - ratio * 100)
            g = int(200 - ratio * 150)
            b = int(50 + ratio * 50)
            draw.point((x, y), fill=(r, g, b))
    
    # 画大太阳
    sun_radius = 150
    draw.ellipse([
        center_x - sun_radius, center_y - sun_radius - 100,
        center_x + sun_radius, center_y + sun_radius - 100
    ], fill=(255, 255, 100), outline=(255, 200, 0), width=5)
    
    # 太阳光芒 (更复杂的光芒效果)
    for i in range(12):
        angle = i * 30
        for length in range(sun_radius + 20, sun_radius + 80, 10):
            x1 = center_x + int(length * math.cos(math.radians(angle)))
            y1 = center_y - 100 + int(length * math.sin(math.radians(angle)))
            x2 = center_x + int((length + 15) * math.cos(math.radians(angle)))
            y2 = center_y - 100 + int((length + 15) * math.sin(math.radians(angle)))
            draw.line([(x1, y1), (x2, y2)], fill=(255, 255, 100), width=6)
    
    # 绘制趣趣 (在下方)
    draw_ququ(draw, center_x, center_y + 200, size=100)
    
    # 添加书名
    try:
        font_large = ImageFont.truetype("/System/Library/Fonts/STHeiti Light.ttc", 72)
        font_small = ImageFont.truetype("/System/Library/Fonts/STHeiti Light.ttc", 36)
    except:
        try:
            font_large = ImageFont.truetype("/System/Library/Fonts/STHeiti Medium.ttc", 72)
            font_small = ImageFont.truetype("/System/Library/Fonts/STHeiti Medium.ttc", 36)
        except:
            font_large = ImageFont.load_default()
            font_small = ImageFont.load_default()
    
    title = "红红的太阳"
    bbox = draw.textbbox((0, 0), title, font=font_large)
    text_width = bbox[2] - bbox[0]
    text_x = (WIDTH - text_width) // 2
    text_y = center_y + 320
    
    # 画标题背景
    draw.rounded_rectangle([
        text_x - 20, text_y - 10,
        text_x + text_width + 20, text_y + 80
    ], radius=15, fill=(255, 255, 255, 200), outline=(255, 100, 0), width=3)
    
    draw.text((text_x, text_y), title, fill=(255, 100, 0), font=font_large)
    
    # 添加L1级别标识
    level_text = "L1 · 启蒙"
    bbox2 = draw.textbbox((0, 0), level_text, font=font_small)
    level_width = bbox2[2] - bbox2[0]
    draw.text(((WIDTH - level_width) // 2, HEIGHT - 100), level_text,
              fill=(100, 100, 100), font=font_small)
    
    # 保存
    output_path = os.path.join(OUTPUT_DIR, "book_cover_05.png")
    img.save(output_path, "PNG")
    print(f"✅ 已生成: {output_path}")
    return output_path


def create_cover_06():
    """绘本06《好吃的果子》封面"""
    img = Image.new('RGB', (WIDTH, HEIGHT), color=(255, 240, 220))  # 温暖米色
    draw = ImageDraw.Draw(img)
    
    # 背景 - 果园场景
    # 画天空
    for i in range(HEIGHT // 3):
        color_val = int(200 + (i / (HEIGHT // 3)) * 55)
        draw.line([(0, i), (WIDTH, i)], fill=(135, 206, 235))
    
    # 画草地
    draw.rectangle([(0, HEIGHT // 3), (WIDTH, HEIGHT)], fill=(144, 238, 144))
    
    # 画果树
    def draw_fruit_tree(x, y, size, fruit_color):
        # 树干
        trunk_width = size // 4
        trunk_height = size
        draw.rectangle([
            x - trunk_width // 2, y - trunk_height,
            x + trunk_width // 2, y
        ], fill=(139, 90, 43))
        
        # 树冠
        crown_radius = size // 2
        draw.ellipse([
            x - crown_radius, y - trunk_height - crown_radius,
            x + crown_radius, y - trunk_height + crown_radius
        ], fill=(34, 139, 34))
        
        # 果实
        random.seed(x + y)
        for _ in range(8):
            fx = x + random.randint(-crown_radius + 10, crown_radius - 10)
            fy = y - trunk_height + random.randint(-crown_radius + 10, crown_radius - 10)
            fr = 8
            draw.ellipse([fx - fr, fy - fr, fx + fr, fy + fr], fill=fruit_color)
    
    # 画几棵果树
    draw_fruit_tree(150, HEIGHT // 3 + 50, 120, (255, 50, 50))  # 苹果树
    draw_fruit_tree(400, HEIGHT // 3 + 30, 140, (255, 165, 0))  # 橘子树
    draw_fruit_tree(650, HEIGHT // 3 + 60, 110, (255, 100, 100))  # 樱桃树
    
    # 画地上的果子
    draw.ellipse([200, HEIGHT - 150, 230, HEIGHT - 120], fill=(255, 50, 50))  # 苹果
    draw.ellipse([350, HEIGHT - 140, 380, HEIGHT - 110], fill=(255, 165, 0))  # 橘子
    draw.ellipse([500, HEIGHT - 145, 530, HEIGHT - 115], fill=(255, 100, 100))  # 樱桃
    
    # 绘制趣趣 (在中间)
    draw_ququ(draw, WIDTH // 2, HEIGHT // 2 + 100, size=100)
    
    # 趣趣手里拿着果子
    draw.ellipse([
        WIDTH // 2 + 80, HEIGHT // 2 + 50,
        WIDTH // 2 + 110, HEIGHT // 2 + 80
    ], fill=(255, 50, 50))
    
    # 添加书名
    try:
        font_large = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 60)
        font_small = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 36)
    except:
        font_large = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    title = "好吃的果子"
    bbox = draw.textbbox((0, 0), title, font=font_large)
    text_width = bbox[2] - bbox[0]
    text_x = (WIDTH - text_width) // 2
    text_y = 80
    
    # 画标题背景
    draw.rounded_rectangle([
        text_x - 20, text_y - 10,
        text_x + text_width + 20, text_y + 70
    ], radius=15, fill=(255, 255, 255, 200), outline=(255, 100, 50), width=3)
    
    draw.text((text_x, text_y), title, fill=(255, 100, 50), font=font_large)
    
    # 添加L1级别标识
    level_text = "L1 · 启蒙"
    bbox2 = draw.textbbox((0, 0), level_text, font=font_small)
    level_width = bbox2[2] - bbox2[0]
    draw.text(((WIDTH - level_width) // 2, HEIGHT - 100), level_text,
              fill=(100, 100, 100), font=font_small)
    
    # 保存
    output_path = os.path.join(OUTPUT_DIR, "book_cover_06.png")
    img.save(output_path, "PNG")
    print(f"✅ 已生成: {output_path}")
    return output_path


def create_cover_07():
    """绘本07《家的小动物》封面"""
    img = Image.new('RGB', (WIDTH, HEIGHT), color=(220, 240, 220))  # 清新绿
    draw = ImageDraw.Draw(img)
    
    # 背景 - 农场场景
    # 画天空
    for i in range(HEIGHT // 3):
        draw.line([(0, i), (WIDTH, i)], fill=(135, 206, 235))
    
    # 画草地
    draw.rectangle([(0, HEIGHT // 3), (WIDTH, HEIGHT)], fill=(144, 238, 144))
    
    # 画农场围栏
    for x in range(100, WIDTH - 50, 80):
        draw.rectangle([x, HEIGHT // 3, x + 10, HEIGHT - 100], fill=(139, 90, 43))
    draw.rectangle([100, HEIGHT // 3 + 50, WIDTH - 50, HEIGHT // 3 + 70], fill=(139, 90, 43))
    draw.rectangle([100, HEIGHT // 3 + 120, WIDTH - 50, HEIGHT // 3 + 140], fill=(139, 90, 43))
    
    # 画小动物 (简化版)
    # 牛 (左下方)
    draw.ellipse([150, HEIGHT - 250, 250, HEIGHT - 150], fill=(200, 200, 200))  # 牛身
    draw.rectangle([220, HEIGHT - 280, 240, HEIGHT - 250], fill=(200, 200, 200))  # 牛头
    draw.ellipse([225, HEIGHT - 290, 235, HEIGHT - 280], fill=(200, 200, 200))  # 牛角
    
    # 小鸡 (右下方)
    draw.ellipse([WIDTH - 250, HEIGHT - 200, WIDTH - 180, HEIGHT - 150], fill=(255, 255, 150))  # 鸡身
    draw.ellipse([WIDTH - 260, HEIGHT - 220, WIDTH - 230, HEIGHT - 190], fill=(255, 200, 0))  # 鸡头
    draw.line([(WIDTH - 180, HEIGHT - 175), (WIDTH - 150, HEIGHT - 160)], fill=(255, 200, 0), width=3)  # 翅膀
    
    # 小猪 (中间偏右)
    draw.ellipse([WIDTH - 400, HEIGHT - 220, WIDTH - 300, HEIGHT - 140], fill=(255, 200, 200))  # 猪身
    draw.ellipse([WIDTH - 410, HEIGHT - 240, WIDTH - 380, HEIGHT - 210], fill=(255, 200, 200))  # 猪头
    # 猪鼻子
    draw.ellipse([WIDTH - 405, HEIGHT - 230, WIDTH - 395, HEIGHT - 220], fill=(255, 150, 150))
    
    # 绘制趣趣 (在中间)
    draw_ququ(draw, WIDTH // 2, HEIGHT // 2 + 50, size=100)
    
    # 添加书名
    try:
        font_large = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 56)
        font_small = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 36)
    except:
        font_large = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    title = "家的小动物"
    bbox = draw.textbbox((0, 0), title, font=font_large)
    text_width = bbox[2] - bbox[0]
    text_x = (WIDTH - text_width) // 2
    text_y = 80
    
    # 画标题背景
    draw.rounded_rectangle([
        text_x - 20, text_y - 10,
        text_x + text_width + 20, text_y + 66
    ], radius=15, fill=(255, 255, 255, 200), outline=(100, 180, 100), width=3)
    
    draw.text((text_x, text_y), title, fill=(100, 150, 50), font=font_large)
    
    # 添加L1级别标识
    level_text = "L1 · 启蒙"
    bbox2 = draw.textbbox((0, 0), level_text, font=font_small)
    level_width = bbox2[2] - bbox2[0]
    draw.text(((WIDTH - level_width) // 2, HEIGHT - 100), level_text,
              fill=(100, 100, 100), font=font_small)
    
    # 保存
    output_path = os.path.join(OUTPUT_DIR, "book_cover_07.png")
    img.save(output_path, "PNG")
    print(f"✅ 已生成: {output_path}")
    return output_path


def create_cover_08():
    """绘本08《四季歌》封面"""
    img = Image.new('RGB', (WIDTH, HEIGHT), color=(255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    # 背景 - 四季拼贴
    # 春天 (左上) - 绿色+花朵
    draw.rectangle([(0, 0), (WIDTH // 2, HEIGHT // 2)], fill=(200, 240, 200))
    # 画小花
    for x, y in [(50, 100), (150, 150), (200, 80)]:
        draw.ellipse([x - 15, y - 15, x + 15, y + 15], fill=(255, 182, 193))  # 花瓣
        draw.ellipse([x - 8, y - 8, x + 8, y + 8], fill=(255, 255, 0))  # 花心
    
    # 夏天 (右上) - 深绿+太阳
    draw.rectangle([(WIDTH // 2, 0), (WIDTH, HEIGHT // 2)], fill=(50, 180, 50))
    # 画太阳
    draw.ellipse([WIDTH - 150, 50, WIDTH - 80, 120], fill=(255, 200, 0))
    
    # 秋天 (左下) - 金黄+落叶
    draw.rectangle([(0, HEIGHT // 2), (WIDTH // 2, HEIGHT)], fill=(255, 200, 100))
    # 画落叶
    for x, y in [(50, HEIGHT // 2 + 100), (150, HEIGHT // 2 + 150), (100, HEIGHT - 150)]:
        draw.ellipse([x - 12, y - 8, x + 12, y + 8], fill=(255, 140, 0))
    
    # 冬天 (右下) - 白+雪花
    draw.rectangle([(WIDTH // 2, HEIGHT // 2), (WIDTH, HEIGHT)], fill=(240, 248, 255))
    # 画雪花 (简化)
    for x, y in [(WIDTH // 2 + 100, HEIGHT // 2 + 100), (WIDTH - 150, HEIGHT // 2 + 150), (WIDTH - 100, HEIGHT - 100)]:
        draw.line([(x - 10, y), (x + 10, y)], fill=(200, 220, 255), width=2)
        draw.line([(x, y - 10), (x, y + 10)], fill=(200, 220, 255), width=2)
        draw.line([(x - 7, y - 7), (x + 7, y + 7)], fill=(200, 220, 255), width=2)
        draw.line([(x - 7, y + 7), (x + 7, y - 7)], fill=(200, 220, 255), width=2)
    
    # 绘制趣趣 (在中间)
    draw_ququ(draw, WIDTH // 2, HEIGHT // 2, size=100)
    
    # 添加书名
    try:
        font_large = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 56)
        font_small = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 36)
    except:
        font_large = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    title = "四季歌"
    bbox = draw.textbbox((0, 0), title, font=font_large)
    text_width = bbox[2] - bbox[0]
    text_x = (WIDTH - text_width) // 2
    text_y = HEIGHT // 2 - 120
    
    # 画标题背景
    draw.rounded_rectangle([
        text_x - 20, text_y - 10,
        text_x + text_width + 20, text_y + 66
    ], radius=15, fill=(255, 255, 255, 220), outline=(100, 150, 200), width=3)
    
    draw.text((text_x, text_y), title, fill=(70, 130, 180), font=font_large)
    
    # 添加L1级别标识
    level_text = "L1 · 启蒙"
    bbox2 = draw.textbbox((0, 0), level_text, font=font_small)
    level_width = bbox2[2] - bbox2[0]
    draw.text(((WIDTH - level_width) // 2, HEIGHT - 100), level_text,
              fill=(100, 100, 100), font=font_small)
    
    # 保存
    output_path = os.path.join(OUTPUT_DIR, "book_cover_08.png")
    img.save(output_path, "PNG")
    print(f"✅ 已生成: {output_path}")
    return output_path


def create_cover_09():
    """绘本09《小明的家》封面"""
    img = Image.new('RGB', (WIDTH, HEIGHT), color=(255, 248, 220))  # 温暖米黄
    draw = ImageDraw.Draw(img)
    
    # 背景 - 家的场景
    # 画天空
    for i in range(HEIGHT // 3):
        draw.line([(0, i), (WIDTH, i)], fill=(135, 206, 235))
    
    # 画草地
    draw.rectangle([(0, HEIGHT // 3), (WIDTH, HEIGHT)], fill=(144, 238, 144))
    
    # 画房子
    house_x = WIDTH // 2
    house_y = HEIGHT // 3 + 50
    
    # 主建筑
    draw.rectangle([
        house_x - 150, house_y,
        house_x + 150, house_y + 200
    ], fill=(255, 220, 180), outline=(200, 150, 100), width=3)
    
    # 屋顶
    draw.polygon([
        (house_x - 180, house_y),
        (house_x + 180, house_y),
        (house_x, house_y - 100)
    ], fill=(200, 150, 100))
    
    # 门
    draw.rectangle([
        house_x - 30, house_y + 100,
        house_x + 30, house_y + 200
    ], fill=(139, 90, 43), outline=(100, 70, 30), width=2)
    
    # 窗户 (左)
    draw.rectangle([
        house_x - 120, house_y + 50,
        house_x - 60, house_y + 100
    ], fill=(135, 206, 235), outline=(200, 150, 100), width=2)
    # 窗框
    draw.line([(house_x - 90, house_y + 50), (house_x - 90, house_y + 100)], fill=(200, 150, 100), width=2)
    draw.line([(house_x - 120, house_y + 75), (house_x - 60, house_y + 75)], fill=(200, 150, 100), width=2)
    
    # 窗户 (右)
    draw.rectangle([
        house_x + 60, house_y + 50,
        house_x + 120, house_y + 100
    ], fill=(135, 206, 235), outline=(200, 150, 100), width=2)
    # 窗框
    draw.line([(house_x + 90, house_y + 50), (house_x + 90, house_y + 100)], fill=(200, 150, 100), width=2)
    draw.line([(house_x + 60, house_y + 75), (house_x + 120, house_y + 75)], fill=(200, 150, 100), width=2)
    
    # 烟囱
    draw.rectangle([
        house_x + 80, house_y - 60,
        house_x + 120, house_y
    ], fill=(200, 150, 100), outline=(180, 130, 80), width=2)
    # 烟 (简化)
    draw.ellipse([house_x + 85, house_y - 90, house_x + 115, house_y - 60], fill=(220, 220, 220))
    draw.ellipse([house_x + 75, house_y - 120, house_x + 110, house_y - 90], fill=(230, 230, 230))
    
    # 绘制趣趣 (在门前)
    draw_ququ(draw, house_x, house_y + 280, size=100)
    
    # 添加书名
    try:
        font_large = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 56)
        font_small = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 36)
    except:
        font_large = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    title = "小明的家"
    bbox = draw.textbbox((0, 0), title, font=font_large)
    text_width = bbox[2] - bbox[0]
    text_x = (WIDTH - text_width) // 2
    text_y = 80
    
    # 画标题背景
    draw.rounded_rectangle([
        text_x - 20, text_y - 10,
        text_x + text_width + 20, text_y + 66
    ], radius=15, fill=(255, 255, 255, 200), outline=(200, 150, 100), width=3)
    
    draw.text((text_x, text_y), title, fill=(180, 100, 50), font=font_large)
    
    # 添加L1级别标识
    level_text = "L1 · 启蒙"
    bbox2 = draw.textbbox((0, 0), level_text, font=font_small)
    level_width = bbox2[2] - bbox2[0]
    draw.text(((WIDTH - level_width) // 2, HEIGHT - 100), level_text,
              fill=(100, 100, 100), font=font_small)
    
    # 保存
    output_path = os.path.join(OUTPUT_DIR, "book_cover_09.png")
    img.save(output_path, "PNG")
    print(f"✅ 已生成: {output_path}")
    return output_path


def create_cover_10():
    """绘本10《去公园玩》封面"""
    img = Image.new('RGB', (WIDTH, HEIGHT), color=(200, 230, 255))  # 天空蓝
    draw = ImageDraw.Draw(img)
    
    # 背景 - 公园场景
    # 画天空
    for i in range(HEIGHT // 2):
        color_val = int(135 + (i / (HEIGHT // 2)) * 50)
        draw.line([(0, i), (WIDTH, i)], fill=(135, 206, 235))
    
    # 画草地
    draw.rectangle([(0, HEIGHT // 2), (WIDTH, HEIGHT)], fill=(144, 238, 144))
    
    # 画公园设施 (简化)
    # 滑梯
    draw.polygon([
        (150, HEIGHT // 2),
        (250, HEIGHT // 2),
        (200, HEIGHT // 2 - 150)
    ], fill=(255, 150, 150))  # 滑梯梯子
    draw.rectangle([(230, HEIGHT // 2 - 150), (280, HEIGHT // 2)], fill=(255, 200, 200))  # 滑梯坡道
    
    # 秋千
    draw.rectangle([(WIDTH - 300, HEIGHT // 2 - 120), (WIDTH - 250, HEIGHT // 2)], fill=(150, 150, 150))  # 支架
    draw.line([(WIDTH - 275, HEIGHT // 2 - 120), (WIDTH - 275, HEIGHT // 2 - 180)], fill=(100, 100, 100), width=3)  # 绳子
    draw.ellipse([WIDTH - 295, HEIGHT // 2 - 190, WIDTH - 255, HEIGHT // 2 - 150], fill=(255, 200, 150))  # 座位
    
    # 画树
    for x in [350, 500, 600]:
        # 树干
        draw.rectangle([x - 15, HEIGHT // 2 - 80, x + 15, HEIGHT // 2], fill=(139, 90, 43))
        # 树冠
        draw.ellipse([x - 50, HEIGHT // 2 - 150, x + 50, HEIGHT // 2 - 50], fill=(34, 139, 34))
    
    # 画小径
    draw.polygon([
        (WIDTH // 2 - 50, HEIGHT // 2),
        (WIDTH // 2 + 50, HEIGHT // 2),
        (WIDTH // 2 + 100, HEIGHT),
        (WIDTH // 2 - 100, HEIGHT)
    ], fill=(210, 180, 140))
    
    # 绘制趣趣 (在中间)
    draw_ququ(draw, WIDTH // 2, HEIGHT // 2 + 100, size=100)
    
    # 趣趣拿着画笔和纸 (呼应封面描述)
    # 画纸
    draw.rectangle([
        WIDTH // 2 + 70, HEIGHT // 2 + 50,
        WIDTH // 2 + 120, HEIGHT // 2 + 90
    ], fill=(255, 255, 255), outline=(200, 200, 200), width=2)
    # 画笔
    draw.line([
        (WIDTH // 2 + 125, HEIGHT // 2 + 40),
        (WIDTH // 2 + 140, HEIGHT // 2 + 70)
    ], fill=(139, 90, 43), width=4)
    draw.ellipse([
        WIDTH // 2 + 138, HEIGHT // 2 + 65,
        WIDTH // 2 + 146, HEIGHT // 2 + 75
    ], fill=(255, 50, 50))  # 笔尖
    
    # 添加书名
    try:
        font_large = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 56)
        font_small = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 36)
    except:
        font_large = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    title = "去公园玩"
    bbox = draw.textbbox((0, 0), title, font=font_large)
    text_width = bbox[2] - bbox[0]
    text_x = (WIDTH - text_width) // 2
    text_y = 80
    
    # 画标题背景
    draw.rounded_rectangle([
        text_x - 20, text_y - 10,
        text_x + text_width + 20, text_y + 66
    ], radius=15, fill=(255, 255, 255, 200), outline=(50, 150, 50), width=3)
    
    draw.text((text_x, text_y), title, fill=(50, 150, 50), font=font_large)
    
    # 添加L1级别标识
    level_text = "L1 · 启蒙"
    bbox2 = draw.textbbox((0, 0), level_text, font=font_small)
    level_width = bbox2[2] - bbox2[0]
    draw.text(((WIDTH - level_width) // 2, HEIGHT - 100), level_text,
              fill=(100, 100, 100), font=font_small)
    
    # 保存
    output_path = os.path.join(OUTPUT_DIR, "book_cover_10.png")
    img.save(output_path, "PNG")
    print(f"✅ 已生成: {output_path}")
    return output_path


def main():
    """主函数：生成所有封面"""
    print("🎨 开始生成字趣阅读绘本封面...")
    print("=" * 50)
    
    # 创建输出目录 (如果不存在)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # 生成10张封面
    covers = [
        ("01《我的身体》", create_cover_01),
        ("02《早上好》", create_cover_02),
        ("03《小兔子找妈妈》", create_cover_03),
        ("04《一二三上学去》", create_cover_04),
        ("05《红红的太阳》", create_cover_05),
        ("06《好吃的果子》", create_cover_06),
        ("07《家的小动物》", create_cover_07),
        ("08《四季歌》", create_cover_08),
        ("09《小明的家》", create_cover_09),
        ("10《去公园玩》", create_cover_10),
    ]
    
    results = []
    for title, func in covers:
        print(f"\n📖 正在生成封面: {title}")
        try:
            path = func()
            results.append((title, path, True))
        except Exception as e:
            print(f"❌ 生成失败: {e}")
            results.append((title, None, False))
    
    # 汇总
    print("\n" + "=" * 50)
    print("📊 生成汇总:")
    success_count = sum(1 for _, _, success in results if success)
    print(f"✅ 成功: {success_count}/10")
    if success_count < 10:
        print(f"❌ 失败: {10 - success_count}/10")
    
    for title, path, success in results:
        status = "✅" if success else "❌"
        print(f"  {status} {title}: {path if path else 'FAILED'}")
    
    print("\n🎉 完成！")


if __name__ == "__main__":
    main()
