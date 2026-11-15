#!/usr/bin/env python3
"""Builds build/SakuraRamenTycoon.rbxlx from default.project.json without Rojo.

It follows the Rojo file conventions used by this project:
  * a folder becomes a Folder (or the script defined by its init.luau / init.server.luau / init.client.luau)
  * Name.server.luau -> Script, Name.client.luau -> LocalScript, Name.luau -> ModuleScript
  * "$properties" support bool / number / string / known enums

Open the produced .rbxlx in Roblox Studio (File > Open from File).
Usage: python3 tools/build_place.py [output_path]
"""
import json
import os
import sys
from xml.sax.saxutils import escape

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ENUMS = {
    "Technology": {"Legacy": 0, "Voxel": 1, "Compatibility": 2, "ShadowMap": 3, "Future": 4},
}

_ref = [0]


def ref():
    _ref[0] += 1
    return f"RBX{_ref[0]:06d}"


def cdata(text):
    return "<![CDATA[" + text.replace("]]>", "]]]]><![CDATA[>") + "]]>"


def prop_xml(name, value):
    if name in ENUMS:
        return f'<token name="{name}">{ENUMS[name][value]}</token>'
    if isinstance(value, bool):
        return f'<bool name="{name}">{"true" if value else "false"}</bool>'
    if isinstance(value, (int, float)):
        return f'<float name="{name}">{value}</float>'
    if isinstance(value, str):
        return f'<string name="{name}">{escape(value)}</string>'
    raise ValueError(f"unsupported property {name}={value!r}")


def script_class(fname):
    for suffix, cls in ((".server.luau", "Script"), (".client.luau", "LocalScript"), (".luau", "ModuleScript")):
        if fname.endswith(suffix):
            return fname[: -len(suffix)], cls
    return None, None


def item(cls, name, props_xml="", children="", source=None):
    parts = [f'<Item class="{cls}" referent="{ref()}"><Properties>',
             f'<string name="Name">{escape(name)}</string>']
    if source is not None:
        parts.append(f'<ProtectedString name="Source">{cdata(source)}</ProtectedString>')
    parts.append(props_xml)
    parts.append("</Properties>")
    parts.append(children)
    parts.append("</Item>")
    return "".join(parts)


def from_fs(name, path):
    if os.path.isfile(path):
        base, cls = script_class(os.path.basename(path))
        return item(cls, name, source=open(path, encoding="utf-8").read())
    init_cls, init_src = "Folder", None
    for nm, cls in (("init.luau", "ModuleScript"), ("init.server.luau", "Script"), ("init.client.luau", "LocalScript")):
        p = os.path.join(path, nm)
        if os.path.exists(p):
            init_cls, init_src = cls, open(p, encoding="utf-8").read()
    children = []
    for entry in sorted(os.listdir(path)):
        full = os.path.join(path, entry)
        if entry.startswith("init.") and entry.endswith(".luau"):
            continue
        if os.path.isdir(full):
            children.append(from_fs(entry, full))
        else:
            base, cls = script_class(entry)
            if base:
                children.append(item(cls, base, source=open(full, encoding="utf-8").read()))
    return item(init_cls, name, children="".join(children), source=init_src)


def from_node(name, node):
    props = "".join(prop_xml(k, v) for k, v in node.get("$properties", {}).items())
    children = []
    for k, v in node.items():
        if not k.startswith("$") and isinstance(v, dict):
            children.append(from_node(k, v))
    if "$path" in node:
        inner = from_fs(name, os.path.join(ROOT, node["$path"]))
        if children or props:
            # splice extra children/properties into the generated item
            head, sep, tail = inner.rpartition("</Item>")
            inner = head + "".join(children) + sep + tail
        return inner
    cls = node.get("$className", "Folder")
    return item(cls, name, props_xml=props, children="".join(children))


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build", "SakuraRamenTycoon.rbxlx")
    proj = json.load(open(os.path.join(ROOT, "default.project.json")))
    tree = proj["tree"]
    body = []
    for k, v in tree.items():
        if not k.startswith("$"):
            body.append(from_node(k, v))
    xml = '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" version="4">' + "".join(body) + "</roblox>"
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        f.write(xml)
    print(f"wrote {os.path.relpath(out, ROOT)} ({len(xml) // 1024} KB, {_ref[0]} instances)")


if __name__ == "__main__":
    main()
