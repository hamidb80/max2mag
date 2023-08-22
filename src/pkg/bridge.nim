import std/[tables, strutils]
import ./[max, mag, common]

func toMaxLayer(l: string): string =
  case l
  of "pdiff", "pdiffusion": "pdif"
  of "ndiff", "ndiffusion": "ndif"
  of "pcontact": "ct"
  of "polycontact": "poly"
  of "ndcontact": "v34"
  of "m2contact": "v12"
  of "metal1": "m1"
  of "metal2": "m2"
  of "polysilicon": "m3"
  of "nsubstratencontact": "m4"
  else: l

func toMax(u: mag.Use): max.Use =
  max.Use(
    ident: u.name,
    transform: u.transform,
    array: u.array)

func toMax(lbl: mag.Label): max.Label =
  max.Label(
    position: lbl.position,
    orient: Align lbl.kind.int,
    text: lbl.text)

func toMax(cell: string, layout: MagLayout): max.Component =
  result = Component()
  result.version = layout.timestamp
  result.ident = cell # TODO add version identifier

  for layer, rects in layout.rects:
    for r in rects:
      result.layers.addRect toMaxLayer layer, r

  for lbl in layout.labels:
    result.layers.addLabel toMaxLayer lbl.layer, toMax lbl

  for u in layout.uses:
    if u.cell notin result.instances:
      result.instances[u.cell] = max.Instance(
        comp: result,
        bound: u.box)

    result.instances[u.cell].uses.add toMax u


func toMax*(mll: MagLayoutLookup, mainCell: string): MaxLayout =
  result.tech = "mmi25" or mll[mainCell].tech
  result.version = 3

  for cell, layout in mll:
    if cell != mainCell:
      result.defs[cell] = toMax(cell, layout)

  result.defs[""] = toMax(mainCell, mll[mainCell])
  result.defs[""].version = mll[mainCell].timestamp

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
    position: label.position,
    kind: label.kind.int,
    text: label.text)

func toMag(use: max.Use, ins: Instance): mag.Use =
  result.cell = ins.comp.ident.toMag
  result.name = use.ident # TODO choose a unique name
  result.transform = use.transform
  result.box = ins.bound
  result.array = use.array
  result.timestamp = ins.comp.version

func toMag*(max: MaxLayout, mainCell: string): MagLayoutLookup =
  for name, component in max.defs:
    var mag = MagLayout()
    mag.tech = "scmos" or max.tech # FIXME
    mag.timestamp = component.version

    for lname, layer in component.layers:
      let l = toMagLayer lname
      mag.rects[l] = layer.rects
      for lbl in layer.labels:
        mag.labels.add toMag(lbl, l)

    for _, ins in component.instances:
      for u in ins.uses:
        mag.uses.add toMag(u, ins)

    result[toMag(name or mainCell)] = mag
