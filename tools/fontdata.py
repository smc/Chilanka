#!env python3
from argparse import ArgumentParser
from fontreport import fontreport
import json
import sys
import unicodedata

parser = ArgumentParser()
parser.add_argument("input", help="font file to process", metavar="FILE")
args = parser.parse_args()

fontdata = {}
font = fontreport.FontFile(args.input)


def gsubs():
    data = {}
    for table, features, unused_langs, src, dest in font.GetGSUBItems():
        if "".join(features) == "salt":
            continue
        for y in dest:
            data["".join(y)] = {
                "table": table,
                "features": ", ".join(features),
                "src": " + ".join(src),
            }
    return data


def summary():
    glyphs = font.glyphs
    count = {2: 0, 3: 0, 4: 0}
    for x in glyphs:
        count[x.class_def] = count.get(x.class_def, 0) + 1
    return {
        "characters": len(font.chars),
        "glyphs": len(glyphs),
        "ligature_glyphs": count[2],
        "mark_glyphs": count[3],
        "component_glyphs": count[4],
    }

glyph_value_map = {}
def glyphs_and_ligatures():
    data = []
    uni = {}
    gsubsmap = gsubs()
    classdefs = {
        0: "base",
        1: "base",
        2: "ligature",
        3: "mark",
        4: "component",
    }
    for code, name in font.chars.items():
        uni[name] = code

    for glyph in font.glyphs:
        glyphdata = {
            "name": glyph.name,
            "index": glyph.index,
            "lsb": glyph.lsb,
            "advance_width": glyph.advance_width,
            "class": classdefs[glyph.class_def],
        }
        if glyph.name in uni:
            try:
                glyphdata["code"] = uni.get(glyph.name)
                glyphdata["value"] = chr(uni.get(glyph.name))
                glyphdata["uniname"] = unicodedata.name(chr(uni.get(glyph.name)))
            except ValueError:
                pass
        else:
            sequence = gsubsmap.get(glyph.name)
            if not sequence:
                print("Warning: %s missing in gsub" % glyph.name, file=sys.stderr)
                continue
            glyphdata["sequence"] = sequence
            components = sequence.get("src").split(" + ")
            mlsequence = []
            for component in components:
                component_glyph_name = component.split(".")[0]
                com_code = uni.get(component_glyph_name)
                if com_code:
                    mlsequence.append(chr(com_code))
                else:
                    mlsequence.append(glyph_value_map.get(component_glyph_name, "?"))
            if sequence.get("features") == "pres" and mlsequence[0] == "ര്":
                del mlsequence[0]
                mlsequence.append("്ര")
            mlsequence_str = "".join(mlsequence)
            glyph_value_map[glyph.name.split(".")[0]] = mlsequence_str
            glyphdata["mlsequence"] = " + ".join(mlsequence) + " → " + mlsequence_str

        data.append(glyphdata)
    return data


fontdata["name"] = font.GetName("Family")
fontdata["full_name"] = font.GetTitle()
fontdata["designer"] = font.GetName("Designer")
fontdata["version"] = font.GetName("Version")
fontdata["summary"] = summary()
# We need two pass to resolve all glyphs
glyphs_and_ligatures()
fontdata["glyphs"] = glyphs_and_ligatures()

with open(fontdata["name"] + ".json", "w") as json_file:
    json.dump(fontdata, json_file, indent=4, ensure_ascii=False, sort_keys=False),
