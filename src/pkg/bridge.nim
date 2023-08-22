import std/[tables, strutils, paths, os]
import ./[max, mag, common]

proc loadDeps*(
    mll: var MagLayoutLookup, 
    depsLayouts: seq[string],
    searchPaths: seq[Path]) = 
    discard

func toMax*(mag: MagLayoutLookup, mainLayout: string): MaxLayout =
  discard


func toMagLayer(l: string): string =
  case l
  of "pdif": "pdiff"
  of "ndif": "ndiff"
  of "ct": "pcontact"
  else: l

func toMag(s: string): string =
  var lastc = '_'
  for c in s:
    let newc =
      case c
      of Letters, Digits, '_': c
      else: '_'

    if not (newc == '_' and lastc == '_'):
      result.add newc

    lastc = newc

func toMag(label: max.Label, layer: string): mag.Label =
  mag.Label(
    layer: layer,
    position: label.pos,
    kind: label.kind.int,
    text: label.text)

func toMag(use: max.Use, ins: Instance): mag.Use =
  result.cell = ins.comp.ident.toMag
  result.name = use.id # TODO choose a unique name
  result.transform = use.trans
  result.box = ins.bound
  result.array = use.array
  result.timestamp = ins.comp.version

func toMag*(max: MaxLayout, mainLayout: string): MagLayoutLookup =
  for name, component in max.defs:
    var mag = MagLayout()
    mag.tech = "scmos" or max.tech # FIXME
    mag.timestamp = component.version

    for lname, layer in component.layers:
      let l = toMagLayer lname
      mag.rects[l] = layer.rects
      for lbl in layer.labels:
        mag.labels.add toMag(lbl, l)

    for ins in component.instances:
      for u in ins.uses:
        mag.uses.add toMag(u, ins)

    result[toMag(name or mainLayout)] = mag
