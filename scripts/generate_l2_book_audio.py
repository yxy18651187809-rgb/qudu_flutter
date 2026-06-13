#!/usr/bin/env python3
"""
L2 绘本页面朗读MP3生成脚本
为 L2 10本绘本 x 14页 = 140个页面生成整页朗读音频
使用 edge-tts (微软语音合成，免费，音质好)

输入: 01-内容/绘本XX-XXX_L2文案v1.md
输出目录: 03-后端/qudu-api/uploads/audio/books/
文件名: L2_book_XX_pN.mp3 (与 ttsController preGenerated URL 一致)
"""

import asyncio
import os
import re
import sys
import time
from pathlib import Path

import edge_tts

# 配置
VOICE = "zh-CN-XiaoxiaoNeural"  # 晓晓（女声，适合儿童APP）
RATE = "-5%"  # 稍慢一点，适合儿童
BASE_DIR = Path(__file__).resolve().parent.parent
CONTENT_DIR = BASE_DIR / "01-内容"
AUDIO_DIR = BASE_DIR / "03-后端" / "qudu-api" / "uploads" / "audio" / "books"


def extract_pages_from_md(filepath: Path) -> dict:
    """
    从L2绘本MD文件中提取每页朗读文本。
    
    L2文案格式:
    ### 【第N页】
    文字：
    > 朗读文本行1
    > **【新字：X、Y、Z】**
    
    返回 {page_num: text_str}
    """
    if not filepath.exists():
        print(f"  ❌ 文件不存在: {filepath}")
        return {}

    content = filepath.read_text(encoding="utf-8")
    pages = {}

    # 匹配每一页的文字段落
    # 格式: ### 【第N页】 ... **文字**：\n> 实际文本...
    page_sections = re.split(r'### 【第(\d+)页】', content)

    for i in range(1, len(page_sections), 2):
        try:
            page_num = int(page_sections[i])
            section_text = page_sections[i + 1] if i + 1 < len(page_sections) else ""

            # 提取「文字」段落（在**文字**：和**拼音**：之间，或下一个###之前）
            text_match = re.search(
                r'\*\*文字\*\*[：:]\s*\n((?:\s*>[^\n]*\n?)+)',
                section_text
            )
            if not text_match:
                continue

            raw_lines = text_match.group(1).strip()
            # 清理: 去除>标记、**【新字：...】**标注、*斜体注释*、空行
            clean_lines = []
            for line in raw_lines.split('\n'):
                line = line.strip()
                if not line:
                    continue
                # 去除开头的 >
                line = re.sub(r'^>\s*', '', line)
                # 去除 **【新字：...】** 标注
                line = re.sub(r'\*\*【[^】]*】\*\*', '', line)
                # 去除 *(注释)* 
                line = re.sub(r'\*（[^）]*）\*', '', line)
                line = re.sub(r'\*\([^)]*\)\*', '', line)
                line = line.strip()
                if line and not line.startswith('【') and not line.startswith('*'):
                    clean_lines.append(line)

            text = ''.join(clean_lines)
            if text:
                pages[page_num] = text

        except (ValueError, IndexError):
            continue

    return pages


async def generate_page_audio(book_id: str, page_num: int, text: str) -> bool:
    """为单个页面生成MP3朗读音频"""
    filename = f"{book_id}_p{page_num}.mp3"
    output_path = AUDIO_DIR / filename

    # 如果文件已存在且大于1KB，跳过
    if output_path.exists() and output_path.stat().st_size > 1024:
        return True

    try:
        communicate = edge_tts.Communicate(text, VOICE, rate=RATE)
        await communicate.save(str(output_path))
        return output_path.exists() and output_path.stat().st_size > 0
    except Exception as e:
        print(f"  ❌ {book_id} P{page_num}: {e}")
        return False


def find_l2_books() -> list:
    """扫描01-内容目录，找到所有L2绘本文案文件"""
    books = []
    if not CONTENT_DIR.exists():
        print(f"❌ 内容目录不存在: {CONTENT_DIR}")
        return books

    for f in sorted(CONTENT_DIR.glob("*L2文案*.md")):
        # 提取绘本编号: 绘本01, 绘本02, ...
        match = re.search(r'绘本(\d+)-', f.name)
        if match:
            num = int(match.group(1))
            title_match = re.search(r'绘本\d+-(.+?)_L2', f.name)
            title = title_match.group(1) if title_match else f"绘本{num:02d}"
            books.append({
                "num": num,
                "book_id": f"L2_book_{num:02d}",
                "title": title,
                "filepath": f
            })

    return sorted(books, key=lambda b: b["num"])


async def main():
    print("=" * 60)
    print("L2 绘本页面朗读音频生成工具")
    print("=" * 60)
    print(f"语音: {VOICE}")
    print(f"语速: {RATE}")
    print(f"内容目录: {CONTENT_DIR}")
    print(f"输出目录: {AUDIO_DIR}")
    print("-" * 60)

    os.makedirs(AUDIO_DIR, exist_ok=True)

    books = find_l2_books()
    if not books:
        print("❌ 未找到L2绘本文案文件")
        return False

    print(f"绘本数: {len(books)}")
    for b in books:
        print(f"  📖 {b['book_id']}《{b['title']}》({b['filepath'].name})")

    # 检查 edge-tts 是否已安装
    try:
        import edge_tts
    except ImportError:
        print("\n❌ 请先安装 edge-tts: pip install edge-tts")
        return False

    print("-" * 60)

    total_success = 0
    total_failed = 0
    total_skipped = 0
    start_time = time.time()

    for book in books:
        book_id = book["book_id"]
        print(f"\n📖 {book_id}《{book['title']}》")

        pages = extract_pages_from_md(book["filepath"])
        if not pages:
            print(f"  ⚠️  未提取到页面文本")
            continue

        print(f"  页面数: {len(pages)}")

        for page_num in sorted(pages.keys()):
            text = pages[page_num]
            filename = f"{book_id}_p{page_num}.mp3"
            output_path = AUDIO_DIR / filename

            if output_path.exists() and output_path.stat().st_size > 1024:
                size = output_path.stat().st_size
                preview = text[:25] + "..." if len(text) > 25 else text
                print(f"  ⏭️  P{page_num}: {preview} ({size:,} bytes, 已存在)")
                total_skipped += 1
                total_success += 1
                continue

            ok = await generate_page_audio(book_id, page_num, text)
            if ok:
                size = output_path.stat().st_size
                preview = text[:25] + "..." if len(text) > 25 else text
                print(f"  ✅ P{page_num}: {preview} ({size:,} bytes)")
                total_success += 1
            else:
                preview = text[:25] + "..." if len(text) > 25 else text
                print(f"  ❌ P{page_num}: {preview}")
                total_failed += 1

    elapsed = time.time() - start_time
    print("\n" + "=" * 60)
    print("生成完成")
    print("=" * 60)
    print(f"📖 绘本数: {len(books)}")
    print(f"✅ 成功: {total_success}")
    print(f"⏭️  跳过(已存在): {total_skipped}")
    print(f"❌ 失败: {total_failed}")
    print(f"⏱️  耗时: {elapsed:.1f}秒")
    print(f"📁 输出: {AUDIO_DIR}")

    return total_failed == 0


if __name__ == "__main__":
    ok = asyncio.run(main())
    sys.exit(0 if ok else 1)
