"""Sum the /played totals Scarlet UI saved in every WoW client.

    python tools/playtime.py ["G:\\World of Warcraft"]

Reads db.global.played from each WTF/Account/*/SavedVariables/ScarletUI.lua.
A character counts once it has logged in with Scarlet UI enabled.
"""
import glob
import re
import sys

root = sys.argv[1] if len(sys.argv) > 1 else r"G:\World of Warcraft"
total = 0
for path in sorted(glob.glob(root + "/*/WTF/Account/*/SavedVariables/ScarletUI.lua")):
    parts = path.replace("\\", "/").split("/")
    label = parts[-6] + " " + parts[-3]
    text = open(path, encoding="utf-8", errors="replace").read()
    block = re.search(r'\["played"\] = \{(.*?)\}', text, re.S)
    chars = re.findall(r'\["(.+?)"\] = (\d+)', block.group(1)) if block else []
    for name, seconds in sorted(chars, key=lambda c: -int(c[1])):
        print(f"  {label:28} {name:32} {int(seconds) / 3600:9.1f} h")
    subtotal = sum(int(seconds) for _, seconds in chars)
    print(f"{label}: {len(chars)} characters, {subtotal / 86400:.1f} days")
    total += subtotal
print(f"TOTAL: {total / 86400:.1f} days ({total / 3600:.0f} hours)")
