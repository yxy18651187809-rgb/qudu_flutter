#!/usr/bin/env python3
"""
生成L1汉字占位音频文件
用于补充后端音频资源
"""

import json
import os
from pathlib import Path

# 配置
L1_JSON_PATH = "/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容/L1完整字300_后端导入.json"
AUDIO_DIR = "/Users/yangxiaoyan/WorkBuddy/20260420213331/03-后端/qudu-api/uploads/audio"

def main():
    # 读取L1汉字数据
    with open(L1_JSON_PATH, 'r', encoding='utf-8') as f:
        characters = json.load(f)

    # 提取所有汉字
    all_chars = [c['character'] for c in characters]
    print(f"L1汉字总数: {len(all_chars)}")

    # 检查已有音频
    existing = set()
    audio_dir = Path(AUDIO_DIR)
    if audio_dir.exists():
        for f in audio_dir.glob("*.mp3"):
            # 移除.mp3后缀
            existing.add(f.stem)

    print(f"已有音频: {len(existing)}")

    # 找出缺失的汉字
    missing = [c for c in all_chars if c not in existing]
    print(f"缺失音频: {len(missing)}")

    # 为缺失的汉字生成占位音频（空文件，48字节）
    placeholder_content = b'\x00' * 48

    created = 0
    for char in missing:
        filepath = audio_dir / f"{char}.mp3"
        if not filepath.exists():
            with open(filepath, 'wb') as f:
                f.write(placeholder_content)
            created += 1

    print(f"已生成占位音频: {created}个")

    # 最终统计
    final_count = len(list(audio_dir.glob("*.mp3")))
    print(f"最终音频总数: {final_count}/301")

if __name__ == "__main__":
    main()
