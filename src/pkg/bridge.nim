import std/[tables, strutils]
import ./[max, mag, common]


func toMax*(mag: MagLayout): MaxLayout =
  discard

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
    fontSize: 1,
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
    mag.tech = max.tech
    mag.timestamp = component.version

    for lname, layer in component.layers:
      mag.rects[lname] = layer.rects
      for lbl in layer.labels:
        mag.rlabels.add toMag(lbl, lname)

    for ins in component.instances:
      for u in ins.uses:
        mag.uses.add toMag(u, ins)

    result[toMag(name or mainCell)] = mag
