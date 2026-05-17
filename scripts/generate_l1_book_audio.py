#!/usr/bin/env python3
"""
L1 绘本页面朗读MP3生成脚本
为 L1 10本绘本 x 10页 = 100个页面生成整页朗读音频
使用 edge-tts (微软语音合成，免费，音质好)

输出目录: 03-后端/qudu-api/uploads/audio/books/
文件名: L1_book_XX_pN.mp3 (与 ttsController preGenerated URL 一致)
"""

import asyncio
import os
import sys
import time
from pathlib import Path

import edge_tts

# 配置
VOICE = "zh-CN-XiaoxiaoNeural"  # 晓晓（女声，适合儿童APP）
RATE = "-5%"  # 稍慢一点，适合儿童
BASE_DIR = Path(__file__).resolve().parent.parent
AUDIO_DIR = BASE_DIR / "03-后端" / "qudu-api" / "uploads" / "audio" / "books"

# L1 绘本页面文本（从 MongoDB 查询得到）
BOOKS = {
    "L1_book_01": {
        "title": "我的身体",
        "pages": {
            1: "我是小明。",
            2: "这是我的头。",
            3: "我的人脸。大大的口。",
            4: "我有两只眼。",
            5: "这是耳。",
            6: "这是鼻。",
            7: "口，大！小，小。",
            8: "我有一双手。",
            9: "我有两只足。",
            10: "我的心。我会长大。",
        }
    },
    "L1_book_02": {
        "title": "早上好",
        "pages": {
            1: "太阳出来了！",
            2: "早上好，太阳！",
            3: "天亮了，我起来了。",
            4: "我刷牙，洗脸。",
            5: "我吃早饭。",
            6: "爸爸早上好！",
            7: "妈妈早上好！",
            8: "爷爷好！奶奶好！",
            9: "我去上学了。",
            10: "明天见！",
        }
    },
    "L1_book_03": {
        "title": "小兔子找妈妈",
        "pages": {
            1: "一只小兔。兔子在林里。",
            2: "兔子找妈妈。妈妈不在。",
            3: "兔子上了山。有多少石头？一、二、三……",
            4: "问小鸟：你有看到妈妈吗？",
            5: "花开了。花有多有少。",
            6: "木桥。水里有鱼。",
            7: "里面是家。妈妈在家里。",
            8: "妈妈！回来了！",
            9: "妈妈爱兔子。大兔子，小兔子。",
            10: "回家了。我爱妈妈。妈妈也爱我。",
        }
    },
    "L1_book_04": {
        "title": "一二三上学去",
        "pages": {
            1: "一、二、三——小明上学去。",
            2: "四只小鸟。一、二、三、四——",
            3: "小明到学校了。学校真大！",
            4: "小明看到新人。你好！你好！",
            5: "小明看到老师。老师好！",
            6: "小明坐好了。朋友也坐好了。我们是好朋友！",
            7: "五个苹果。一、二、三、四、五——",
            8: "小明举手。老师，我想去洗手间。",
            9: "放学了。明天见！老师好！同学好！",
            10: "一、二、三、四、五——我学会数数了！老师好！朋友好！明天还要上学！",
        }
    },
    "L1_book_05": {
        "title": "红红的太阳",
        "pages": {
            1: "天亮了。太阳出来了。",
            2: "红红的太阳。红，真好看。",
            3: "白天有云。云是白的。",
            4: "风来了。风真大。",
            5: "下雨了。天黑了。",
            6: "黄黄的雨衣。蓝蓝的天。",
            7: "绿色的草。绿，真好看。",
            8: "太阳又出来了。光真好。",
            9: "晚上有星星和月亮。",
            10: "红黄蓝绿白黑——我看到好多颜色！",
        }
    },
    "L1_book_06": {
        "title": "好吃的果子",
        "pages": {
            1: "好多果子！红的、黄的、绿的。",
            2: "大西瓜！小桃子。",
            3: "米和菜。米饭好吃！",
            4: "喝点水。茶也好好喝。",
            5: "糖真多！红的糖，黄的糖。",
            6: "豆子，一颗一颗。",
            7: "蛋！一个蛋。两个蛋。",
            8: "面条长长的。肉也好吃。",
            9: "果子少了一半。分给你一半！",
            10: "一起唱！好吃好吃真好吃！",
        }
    },
    "L1_book_07": {
        "title": "家的小动物",
        "pages": {
            1: "大牛跑得慢。牛，慢——",
            2: "小马跑得快！马，快——",
            3: "羊在山上。白白的羊。",
            4: "猪在泥里。猪好开心！",
            5: "小狗跑来了。狗是好朋友。",
            6: "小猫不跑，猫在睡觉。",
            7: "鸡会飞不高。鸡在地上。",
            8: "鸭子在水里游。鸭游得快！",
            9: "鱼也在水里游。小鱼好快！",
            10: "鸟在天上飞。虫在树上爬。大家都在笑！",
        }
    },
    "L1_book_08": {
        "title": "四季歌",
        "pages": {
            1: "春天来了。气暖暖的。",
            2: "先种树。树会长高。",
            3: "草长出来了。浇浇水。",
            4: "土湿了。泉水在土里。",
            5: "河里有水。沙子在河边。",
            6: "秋来了。叶变黄了。",
            7: "大雁飞走了。天气变冷了。",
            8: "冬来了。下雪了。冰好冷！",
            9: "小动物在洞里。好暖和。",
            10: "一年有四季。春夏秋冬，年年有好日子！",
        }
    },
    "L1_book_09": {
        "title": "小明的家",
        "pages": {
            1: "这是我的家。家好大！",
            2: "爸是男的。妈是女的。",
            3: "爷爷是老人。爷爷好！",
            4: "奶奶也是老人。奶奶好！",
            5: "哥哥是男的。弟弟是男的。",
            6: "叔叔来了。叔叔也是男的。",
            7: "桌上好多菜。椅子也好多。",
            8: "我穿新衣。衣上有一个字。",
            9: "爸爸讲故事。故事真有趣！",
            10: "家好安。我爱我的家！",
        }
    },
    "L1_book_10": {
        "title": "去公园玩",
        "pages": {
            1: "今天去公园！坐车去。",
            2: "车站在前面。站上好多人。",
            3: "前方左转。左边有树。",
            4: "公园在外面。外面好大！",
            5: "东边是太阳。西边有山。",
            6: "北边好远。远处有大海。",
            7: "我拿纸和笔。画一幅画！",
            8: "我画了太阳和花。说说你的画。",
            9: "我还想读书。书里有好多字。",
            10: "公园真好玩！东西南北，我都知道！",
        }
    },
}


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


async def main():
    print("=" * 60)
    print("L1 绘本页面朗读音频生成工具")
    print("=" * 60)
    print(f"语音: {VOICE}")
    print(f"语速: {RATE}")
    print(f"输出目录: {AUDIO_DIR}")
    print(f"绘本数: {len(BOOKS)}")
    total_pages = sum(len(b["pages"]) for b in BOOKS.values())
    print(f"总页数: {total_pages}")
    print("-" * 60)

    os.makedirs(AUDIO_DIR, exist_ok=True)

    success = 0
    failed = 0
    skipped = 0
    start_time = time.time()

    for book_id, book_data in BOOKS.items():
        print(f"\n📖 {book_id}《{book_data['title']}》")
        for page_num, text in sorted(book_data["pages"].items()):
            filename = f"{book_id}_p{page_num}.mp3"
            output_path = AUDIO_DIR / filename

            if output_path.exists() and output_path.stat().st_size > 1024:
                size = output_path.stat().st_size
                print(f"  ⏭️  P{page_num}: {text[:20]}... ({size:,} bytes, 已存在)")
                skipped += 1
                success += 1
                continue

            ok = await generate_page_audio(book_id, page_num, text)
            if ok:
                size = output_path.stat().st_size
                print(f"  ✅ P{page_num}: {text[:20]}... ({size:,} bytes)")
                success += 1
            else:
                print(f"  ❌ P{page_num}: {text[:20]}...")
                failed += 1

    elapsed = time.time() - start_time
    print("\n" + "=" * 60)
    print("生成完成")
    print("=" * 60)
    print(f"✅ 成功: {success}/{total_pages} (其中跳过: {skipped})")
    print(f"❌ 失败: {failed}")
    print(f"⏱️  耗时: {elapsed:.1f}秒")
    print(f"📁 输出: {AUDIO_DIR}")

    return failed == 0


if __name__ == "__main__":
    ok = asyncio.run(main())
    sys.exit(0 if ok else 1)
