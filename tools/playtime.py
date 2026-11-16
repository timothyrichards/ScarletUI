"""Sum the /played totals Scarlet UI saved in every WoW client.

    python tools/playtime.py ["G:\\World of Warcraft"]

Reads db.global.playtime and db.global.playtimeClasses from each
WTF/Account/*/SavedVariables/ScarletUI.lua. A character counts once it has
logged in with Scarlet UI enabled; its class shows after a login on a version
that records it.
"""
import collections
import glob
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")  # names like Kylé on a cp1252 console

CLASSES = {"DEATHKNIGHT": "Death Knight", "DEMONHUNTER": "Demon Hunter"}


def table(text, name):
    block = re.search(r'\["%s"\] = \{(.*?)\}' % name, text, re.S)
    return re.findall(r'\["(.+?)"\] = "?(\w+)"?', block.group(1)) if block else []


root = sys.argv[1] if len(sys.argv) > 1 else r"G:\World of Warcraft"
total = 0
by_class = collections.Counter()
for path in sorted(glob.glob(root + "/*/WTF/Account/*/SavedVariables/ScarletUI.lua")):
    parts = path.replace("\\", "/").split("/")
    label = parts[-6] + " " + parts[-3]
    text = open(path, encoding="utf-8", errors="replace").read()
    chars = [(name, int(seconds)) for name, seconds in table(text, "playtime")]
    classes = dict(table(text, "playtimeClasses"))
    for name, seconds in sorted(chars, key=lambda c: -c[1]):
        token = classes.get(name)
        cls = CLASSES.get(token, token.title()) if token else "Unknown"
        by_class[cls] += seconds
        print(f"  {label:28} {name:32} {cls:13} {seconds / 3600:9.1f} h")
    subtotal = sum(seconds for _, seconds in chars)
    print(f"{label}: {len(chars)} characters, {subtotal / 86400:.1f} days")
    total += subtotal
print(f"TOTAL: {total / 86400:.1f} days ({total / 3600:.0f} hours)")
for cls, seconds in by_class.most_common():
    print(f"  {cls:13} {seconds / 3600:9.1f} h {100 * seconds / (total or 1):5.1f}%")
