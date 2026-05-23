import re, os, json

base = "/Users/yangxiaoyan/WorkBuddy/20260420213331/01-内容"

# Load L1 chars
with open(base + "/L1完整字300_后端导入_ready.json") as f:
    l1 = set(item["character"] for item in json.load(f))

# Load L2 chars (JSON)
with open(base + "/L2完整字_后端导入.json") as f:
    l2_json = set(item["character"] for item in json.load(f))

def extract_chars(pattern):
    chars = set()
    files = sorted([f for f in os.listdir(base) if re.match(pattern, f)])
    per_file = {}
    for fname in files:
        path = os.path.join(base, fname)
        with open(path) as fh:
            content = fh.read()
        in_sec = False
        file_chars = set()
        for line in content.split("\n"):
            if "新字表" in line and line.startswith("#"):
                in_sec = True
                continue
            if in_sec:
                if line.startswith("#") or (line.startswith("---") and "|" not in line):
                    in_sec = False
                    continue
                if re.match(r'^\|[\s\-:|]+\|\s*$', line):
                    continue
                match = re.match(r'^\s*\|\s*([^\s\|]+)\s*\|', line)
                if match:
                    ch = match.group(1).strip()
                    if re.match(r'^[\u4e00-\u9fff]$', ch):
                        chars.add(ch)
                        file_chars.add(ch)
        if file_chars:
            per_file[fname] = file_chars
    return chars, per_file

l2m, l2f = extract_chars(r'^L2-\d+\.md$')
l3, l3f = extract_chars(r'^L3-\d+\.md$')
l4, l4f = extract_chars(r'^L4-\d+\.md$')
l5, l5f = extract_chars(r'^L5-\d+\.md$')

# L4-073 specific
l4_073 = l4f.get("L4-073_图书馆的故事.md", set())
print("=== L4-073 新字表 ===")
print(f"实际提取: {len(l4_073)} 字: {''.join(sorted(l4_073))}")

# Cross-level review analysis
print("\n=== 各等级复习字占比 ===")
levels = [
    ("L2(MD)", l2m, l1, l2f),
    ("L3", l3, l1 | l2m, l3f),
    ("L4", l4, l1 | l2m | l3, l4f),
    ("L5", l5, l1 | l2m | l3 | l4, l5f),
]
for name, all_c, lower_c, fdict in levels:
    total = len(all_c)
    review = all_c & lower_c
    new = all_c - lower_c
    pct = len(review) / total * 100 if total else 0
    print(f"  {name}: 总{total}字, 复习{len(review)}字({pct:.0f}%), 新字{len(new)}字({100-pct:.0f}%)")
    # per-story review count
    counts = []
    for fname, chars in fdict.items():
        r = len(chars & lower_c)
        counts.append(r)
    if counts:
        avg = sum(counts) / len(counts)
        print(f"    每篇复习字: min={min(counts)}, max={max(counts)}, avg={avg:.1f}")

# Check L4 新字表 header vs actual
print("\n=== L4 文件头新字数 vs 实际新字表 ===")
for fname in sorted(l4f.keys()):
    path = os.path.join(base, fname)
    with open(path) as fh:
        content = fh.read()
    m = re.search(r'\|\s*新字数\s*\|\s*(\d+)', content)
    hc = int(m.group(1)) if m else None
    ac = len(l4f[fname])
    diff = hc - ac if hc else 0
    if abs(diff) > 3:
        print(f"  ⚠️ {fname.replace('.md','')}: 头={hc}字, 表={ac}字, 差={diff}")

# Check L5 similarly
print("\n=== L5 文件头新字数 vs 实际新字表 ===")
for fname in sorted(l5f.keys()):
    path = os.path.join(base, fname)
    with open(path) as fh:
        content = fh.read()
    m = re.search(r'\|\s*新字数\s*\|\s*(\d+)', content)
    hc = int(m.group(1)) if m else None
    ac = len(l5f[fname])
    diff = hc - ac if hc else 0
    if abs(diff) > 3:
        print(f"  ⚠️ {fname.replace('.md','')}: 头={hc}字, 表={ac}字, 差={diff}")

# L4 创作规范要求: 每篇新字30-40字, 复习字5-8个
print("\n=== L4 每篇新字表字数分布 ===")
l4_counts = [(fname, len(chars)) for fname, chars in l4f.items()]
l4_counts.sort(key=lambda x: x[1])
for fname, cnt in l4_counts:
    flag = " ⚠️偏低" if cnt < 25 else (" ⚠️偏高" if cnt > 45 else "")
    print(f"  {fname.replace('.md','')}: {cnt}字{flag}")
cnts = [c for _, c in l4_counts]
print(f"  合计: min={min(cnts)}, max={max(cnts)}, avg={sum(cnts)/len(cnts):.1f}, median={sorted(cnts)[len(cnts)//2]}")
