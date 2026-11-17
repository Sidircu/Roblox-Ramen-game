import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from data1 import NAMES
from data2 import ITEMS, DYN
from data3 import UI, MSG, HINT, TUT
from data4 import NEW
rows = list(NAMES) + [("item."+i, e, it) for i, e, it in ITEMS] + list(DYN) + list(UI) + list(MSG) + list(HINT) + list(TUT) + list(NEW)
seen = {}
for k, e, it in rows:
    if k in seen:
        print("DUP", k)
    seen[k] = (e, it)
def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')
out = sys.argv[1]
for idx, lang in ((0, "en"), (1, "it")):
    lines = ["--!nonstrict", f"-- {'English' if lang == 'en' else 'Italian'} texts. Every key must exist in both en.luau and it.luau.", "return {"]
    for k in sorted(seen):
        lines.append(f'\t["{k}"] = "{esc(seen[k][idx])}",')
    lines.append("}")
    open(os.path.join(out, f"{lang}.luau"), "w", encoding="utf-8").write("\n".join(lines) + "\n")
print(len(seen), "keys")
