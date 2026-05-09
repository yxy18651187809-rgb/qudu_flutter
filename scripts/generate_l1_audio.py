#!/usr/bin/env python3
"""
L1 301字MP3音频生成脚本
使用 macOS say 命令 + ffmpeg 生成真实拼音音频
"""
import subprocess
import os
import time
import sys

# 配置
AUDIO_DIR = "/Users/yangxiaoyan/WorkBuddy/20260420213331/03-后端/qudu-api/uploads/audio"
TEMP_DIR = "/tmp/audio_gen"
VOICE = "Ting-Ting"  # macOS 中文语音

os.makedirs(TEMP_DIR, exist_ok=True)

# L1 301字完整列表（来自 MongoDB）
CHARS = [
    "一","二","三","四","五","六","七","八","九","十","百","千","万","个","只","条","朵","双","半",
    "日","月","天","地","山","水","火","风","云","雨","雪","石","土","田","木","林","花","草","树","河","海","星","光","气",
    "人","口","手","足","头","耳","目","心","牙","舌","发","毛","骨","肉","身","生","死","老","少",
    "爸","妈","爷","奶","哥","弟","叔","男","女","子","友","王","张","李","中","大","小",
    "牛","马","羊","猪","狗","猫","鸟","鱼","虫","鸡","鸭","兔","龙","虎","蛇","鹿","象","鹰","蝶","蜂",
    "走","跑","跳","飞","站","坐","爬","拿","打","拉","推","抱","丢","找","看","听","说","答","笑","哭","吃","睡","起","洗","穿","画","唱","玩","学","读",
    "来","去","出","入","回","开","关","上","下","有","无","在","多","长","短","高","低","好","坏","新","旧","的","错","真","假","快","慢","亮","丑","干","湿","左","右","前","后","里","外","东","西","南","北","远",
    "我","你","他","她","它","那","谁","什","自","了","是","不","没","会","能","要","想","知","觉","把","让","和","都","最",
    "米","饭","面","菜","蛋","茶","瓜","果","衣","裤","鞋","帽","门","窗","床","桌","椅","车","书","笔","纸","字","文","数","语","音","图","歌","故","事","班","校","师","同","国","家",
    "红","黄","蓝","绿","白","黑","金","紫","灰","青","今","明","年","早","晚","先","春","秋","冬","分","爱","喜","怕","急","安","忙","病","瘦","胖","困","醒","刷",
    "太","阳","零","两","匹","棵","座","冰","泉","岛","沙","洞","鼻","眉","指","肚","糖","豆","桃","苹","蛙","龟","猴","做","用","种","吹","拍","提","骑","游","钓","浇",
    "圆","方","脸","眼","问"
]

def generate_audio(char: str) -> bool:
    """为一个汉字生成MP3音频"""
    aiff_path = os.path.join(TEMP_DIR, f"{char}.aiff")
    mp3_path = os.path.join(TEMP_DIR, f"{char}.mp3")
    dest_path = os.path.join(AUDIO_DIR, f"{char}.mp3")

    try:
        # Step 1: say 生成 AIFF
        result = subprocess.run(
            ["say", "-v", VOICE, char, "-o", aiff_path],
            capture_output=True, timeout=15
        )
        if result.returncode != 0:
            return False

        # Step 2: ffmpeg 转换为 MP3
        result = subprocess.run(
            ["ffmpeg", "-y", "-i", aiff_path,
             "-codec:a", "libmp3lame", "-q:a", "2",
             mp3_path],
            capture_output=True, timeout=15
        )
        if result.returncode != 0:
            return False

        # Step 3: 复制到目标目录
        subprocess.run(["cp", mp3_path, dest_path], check=True)

        # 清理临时文件
        os.remove(aiff_path)
        os.remove(mp3_path)
        return True

    except Exception:
        return False

def main():
    total = len(CHARS)
    success = 0
    failed = []

    print(f"🎙️  开始生成 L1 {total} 字音频...")
    print(f"📁  目标目录: {AUDIO_DIR}")
    print(f"🎤  语音: {VOICE}")
    print("-" * 50)

    start_time = time.time()

    for i, char in enumerate(CHARS):
        dest_path = os.path.join(AUDIO_DIR, f"{char}.mp3")

        # 检查是否已有有效音频（>1KB，跳过占位文件）
        if os.path.exists(dest_path) and os.path.getsize(dest_path) > 1024:
            print(f"[{i+1:3d}/{total}] {char} ✅ (已有)")
            success += 1
            continue

        ok = generate_audio(char)
        if ok:
            size = os.path.getsize(dest_path)
            print(f"[{i+1:3d}/{total}] {char} ✅ ({size:,} bytes)")
            success += 1
        else:
            failed.append(char)
            print(f"[{i+1:3d}/{total}] {char} ❌")

        # 每20个打印进度
        if (i + 1) % 20 == 0:
            elapsed = time.time() - start_time
            rate = (i + 1) / elapsed
            remaining = (total - i - 1) / rate if rate > 0 else 0
            print(f"  📊 进度: {i+1}/{total} ({rate:.1f}字/秒, 预计剩余 {remaining:.0f}秒)")

    elapsed = time.time() - start_time
    print("-" * 50)
    print(f"✅ 完成！成功: {success}/{total}, 失败: {len(failed)}, 耗时: {elapsed:.1f}秒")
    if failed:
        print(f"❌ 失败字符: {''.join(failed)}")

    return len(failed) == 0

if __name__ == "__main__":
    ok = main()
    sys.exit(0 if ok else 1)
