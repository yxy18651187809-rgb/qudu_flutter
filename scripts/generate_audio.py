#!/usr/bin/env python3
"""
批量生成L1汉字音频文件
使用edge-tts（微软语音合成，免费，音质好）
"""

import json
import os
import asyncio
from pathlib import Path

# 安装edge-tts: pip3 install edge-tts
import edge_tts

# 配置
CHARS_JSON = "/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容/L1完整字300_后端导入.json"
AUDIO_DIR = "/Users/yangxiaoyan/WorkBuddy/20260420213331/03-后端/qudu-api/public/audio"
VOICE = "zh-CN-XiaoxiaoNeural"  # 晓晓（女声，适合儿童APP）

def get_existing_audio():
    """获取已存在的音频文件列表"""
    return {f.stem for f in Path(AUDIO_DIR).glob("*.mp3")}

def get_all_chars():
    """从JSON文件读取所有L1汉字"""
    with open(CHARS_JSON, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return [item['character'] for item in data]

async def generate_audio(char, voice=VOICE):
    """为单个汉字生成音频"""
    output_path = os.path.join(AUDIO_DIR, f"{char}.mp3")
    
    # 如果文件已存在，跳过
    if os.path.exists(output_path):
        print(f"  ⏭️  跳过（已存在）: {char}")
        return True
    
    try:
        communicate = edge_tts.Communicate(char, voice)
        await communicate.save(output_path)
        print(f"  ✅ 生成成功: {char}")
        return True
    except Exception as e:
        print(f"  ❌ 生成失败: {char} - {e}")
        return False

async def main():
    """主函数"""
    print("=" * 60)
    print("L1汉字音频批量生成工具")
    print("=" * 60)
    
    # 获取所有汉字
    all_chars = get_all_chars()
    print(f"\n📊 L1总字数: {len(all_chars)}")
    
    # 获取已存在的音频
    existing = get_existing_audio()
    print(f"📁 已存在音频: {len(existing)} 个")
    
    # 计算需要生成的
    to_generate = [c for c in all_chars if c not in existing]
    print(f"🎯 需要生成: {len(to_generate)} 个")
    
    if not to_generate:
        print("\n✅ 所有音频已生成，无需操作")
        return
    
    # 确认
    print(f"\n🔊 使用语音: {VOICE}")
    print(f"📂 输出目录: {AUDIO_DIR}")
    print(f"\n开始生成...")
    print("-" * 60)
    
    # 批量生成
    success = 0
    failed = 0
    
    for i, char in enumerate(to_generate, 1):
        print(f"[{i}/{len(to_generate)}] {char}")
        result = await generate_audio(char)
        if result:
            success += 1
        else:
            failed += 1
    
    # 统计
    print("\n" + "=" * 60)
    print("生成完成")
    print("=" * 60)
    print(f"✅ 成功: {success}")
    print(f"❌ 失败: {failed}")
    print(f"📁 总计音频文件: {len(existing) + success}")
    
    if failed > 0:
        print(f"\n⚠️  有 {failed} 个音频生成失败，请检查错误信息")

if __name__ == "__main__":
    asyncio.run(main())
