import std/[tables, strutils]
import ./[max, mag, common]


func toMax*(mag: MagLayout): MaxLayout =
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

func toMag(label: Label, layer: string): RLabel =
  RLabel(
    layer: layer,
    position: label.pos,
    kind: label.kind.int,
    text: label.text)

func toMag(use: max.Use, ins: Instance): mag.Use =
  result.cell = ins.comp.ident.toMag
  result.name = use.id
  result.transform = use.trans
  result.box = ins.bound
  result.array = use.array
  result.timestamp = ins.comp.version

func toMag*(max: MaxLayout, mainCell: string): MagLayoutTable =
  for name, component in max.defs:
    var mag = MagLayout()
    mag.tech = "scmos" or max.tech
    mag.timestamp = component.version

    for lname, layer in component.layers:
      let l = toMagLayer lname
      mag.rects[l] = layer.rects
      for lbl in layer.labels:
        mag.rlabels.add toMag(lbl, l)

    for ins in component.instances:
      for u in ins.uses:
        mag.uses.add toMag(u, ins)

    result[toMag(name or mainCell)] = mag
