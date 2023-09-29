#!env python3
import sys
from fontTools.ttLib import TTFont
from argparse import ArgumentParser
from fontreport import fontreport
import itertools
import json
import unicodedata

parser = ArgumentParser()
parser.add_argument("input", help="font file to process", metavar="FILE")

args = parser.parse_args()
font = TTFont(args.input)
cmap = font["cmap"].getBestCmap()
codepoints = list(cmap.keys())
glyphset = font.getGlyphOrder()
revcmap = font["cmap"].buildReversed()

fontdata = {}
ff=fontreport.FontFile(args.input)

def gsubs():
    data={}
    for table, features, unused_langs, src, dest in ff.GetGSUBItems():
        for y in dest:
            data[''.join(y)]={
                "table": table,
                "features":', '.join(features),
                "src": ' + '.join(src)
            }
    return data


def ranges(i):
    for a, b in itertools.groupby(enumerate(i), lambda pair: pair[1] - pair[0]):
        b = list(b)
        yield b[0][1], b[-1][1]


def categorize_glyph(font, glyphname):
    classdefs = font["GDEF"].table.GlyphClassDef.classDefs
    if not glyphname in classdefs:
        return ("base", None)
    if classdefs[glyphname] == 1:
        return ("base", None)
    if classdefs[glyphname] == 2:
        return ("ligature", None)
    if classdefs[glyphname] == 3:
        # Now find attachment class
        mclass = None
        if font["GDEF"].table.MarkAttachClassDef:
            markAttachClassDef = font["GDEF"].table.MarkAttachClassDef.classDefs
            mclass = markAttachClassDef[glyphname]
        return ("mark", mclass)
    if classdefs[glyphname] == 4:
        return ("component", None)


fontdata["font_name"] = font["name"].getDebugName(1)
fontdata["font_version"] = font["name"].getDebugName(5)
fontdata["glyph_count"] = len(glyphset)

codepoints = list(cmap.keys())
coverage = ""
cplen = 4
if list(filter(lambda x: x > 0xFFFF, codepoints)):
    cplen = 6


def fmtcp(cp):
    return ("U+%0" + str(cplen) + "X") % cp


cp_ranges = ranges(codepoints)
for s, e in cp_ranges:
    if s == e:
        coverage += fmtcp(s) + " "
    else:
        coverage += fmtcp(s) + "-" + fmtcp(e) + " "
fontdata["font_coverage"] = coverage
glyphs = []
gsubsmap=gsubs()
for ix, g in enumerate(glyphset):
    glyph = {}
    category, cx = categorize_glyph(font, g)
    glyph["id"] = ix
    glyph["category"] = category
    glyph["glyph_name"] = g
    if g in revcmap:
        for rc in revcmap[g]:
            glyph["code"] = "U+%04X" % rc
            glyph["value"] = chr(rc)
            glyph["unicode_name"] = unicodedata.name(chr(rc), "UNKNOWN")
    if category == 'ligature':
        glyph["sequence"] = gsubsmap.get(g, g)

    advance, lsb = font["hmtx"][g]
    glyph["advance"] = advance
    glyph["lsb"] = lsb
    glyphs.append(glyph)


fontdata["glyphs"] = glyphs
print(json.dumps(fontdata, indent=4, ensure_ascii=False, sort_keys=False))
