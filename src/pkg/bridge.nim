import std/[tables, strutils]
import ./[max, mag, common]

func toMaxLayer(l: string): string =
  case l
  of "pdiff", "pdiffusion": "pdif"
  of "ndiff", "ndiffusion": "ndif"
  of "pcontact": "ct"
  of "polycontact": "poly"
  of "ndcontact": "v34"
  of "pdcontact": "v23"
  of "m2contact": "v12"
  of "ntransistor", "ptransistor": "v45"
  of "metal1": "m1"
  of "metal2": "m2"
  of "polysilicon": "m3"
  of "nsubstratencontact": "m4"
  of "psubstratepcontact": "m5"
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

func toMax(layout: mag.Layout): max.Layout =
  var comp = max.Component()
  comp.version = layout.timestamp
  comp.ident = ""

  for layer, rects in layout.rects:
    for r in rects:
      comp.layers.addRect toMaxLayer layer, r

  for lbl in layout.labels:
    comp.layers.addLabel toMaxLayer lbl.layer, toMax lbl

  for u in layout.uses:
    if u.cell notin comp.instances:
      comp.instances[u.cell] = max.Instance(
        comp: u.cell,
        bound: u.box)

    comp.instances[u.cell].uses.add toMax u
  result.defs[""] = comp

func toMax*(mll: mag.LayoutLookup): max.LayoutLookup =
  for cell, layout in mll:
    var mx = toMax layout
    mx.defs[""].version = layout.timestamp
    mx.tech = "mmi25" or layout.tech
    mx.resolution = 0.1
    mx.version = 3
    result[cell] = mx

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

func toMag(use: max.Use, ins: Instance, timestamp: int): mag.Use =
  result.cell = ins.comp.toMag
  result.name = use.ident # TODO choose a unique name
  result.transform = use.transform
  result.box = ins.bound
  result.array = use.array
  result.timestamp = timestamp

func toMag*(layout: max.Layout, mainCell: string): mag.LayoutLookup =
  for name, component in layout.defs:
    var mag = mag.Layout()
    mag.tech = "scmos" or layout.tech # FIXME
    mag.timestamp = component.version

    for lname, layer in component.layers:
      let l = toMagLayer lname
      mag.rects[l] = layer.rects
      for lbl in layer.labels:
        mag.labels.add toMag(lbl, l)

    for _, ins in component.instances:
      for u in ins.uses:
        mag.uses.add toMag(u, ins, component.version)

    result[toMag(name or mainCell)] = mag

# TODO
# func toMag*(layout: max.LayoutLookup): mag.LayoutLookup =
