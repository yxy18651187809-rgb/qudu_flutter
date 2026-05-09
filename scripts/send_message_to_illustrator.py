#!/usr/bin/env python3
"""
给插画师发送通知消息
"""

import json
from datetime import datetime, timezone

# 插画师inbox文件路径
inbox_file = "/Users/yangxiaoyan/.workbuddy/teams/ziqu-team/inboxes/插画师.json"

# 新消息内容
new_message = {
    "from": "team-lead",
    "text": "【5/7任务提醒】\n\n今日（5/7）任务：\n- 上午（09:15-12:00）：绘本04上色（P1-P5）\n- 下午（14:00-17:00）：绘本04上色（P6-P10）\n- 交付目标：10张上色图\n\n请确认今日计划，明日站会09:00见。\n\n如有任何阻塞，请立即告知。",
    "summary": "5/7任务提醒：绘本04上色10张图",
    "timestamp": datetime.now(timezone.utc).isoformat(),
    "read": False
}

try:
    # 读取现有消息
    with open(inbox_file, 'r', encoding='utf-8') as f:
        messages = json.load(f)
    
    # 添加新消息
    messages.append(new_message)
    
    # 写回文件
    with open(inbox_file, 'w', encoding='utf-8') as f:
        json.dump(messages, f, ensure_ascii=False, indent=2)
    
    print(f"✅ 消息已发送到插画师inbox")
    print(f"消息摘要: {new_message['summary']}")
    print(f"当前inbox消息总数: {len(messages)}")

except Exception as e:
    print(f"❌ 发送消息失败: {e}")
