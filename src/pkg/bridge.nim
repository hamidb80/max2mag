import std/[tables, strformat, strutils]
import ./[max, mag, common]


type LayerMap* = Table[string, string]

func parseLayerMapper*(content: string): LayerMap =
  for l in splitLines content:
    if not isEmptyOrWhitespace l:
      let p = splitWhitespace l
      assert p.len == 3, fmt"expected pattern <layer1> => <layer2> bot got: {l}"
      result[p[0]] = p[2]

func mapLayerName(lmap: LayerMap, l: string): string =
  if l in lmap:
    lmap[l]
  else:
    raise newException(ValueError, fmt"the layer '{l}' has no counter part")


func toMax(u: mag.Use): max.Use =
  max.Use(
    ident: u.name,
    transform: u.transform,
    array: u.array)

func toMax(lbl: mag.Label): max.Label =
  max.Label(
    position: lbl.position,
    orient: c,
    kind: lLocal,
    text: lbl.text)

func toMax(layout: mag.Layout, lmap: LayerMap): max.Layout =
  var comp = max.Component()
  comp.version = layout.timestamp
  comp.ident = ""

  for layer, rects in layout.rects:
    for r in rects:
      comp.layers.addRect mapLayerName(lmap, layer), r

  for lbl in layout.labels:
    comp.layers.addLabel mapLayerName(lmap, lbl.layer), toMax lbl

  for u in layout.uses:
    if u.cell notin comp.instances:
      comp.instances[u.cell] = max.Instance(
        comp: u.cell,
        bound: u.box)

    comp.instances[u.cell].uses.add toMax u
  result.defs[""] = comp

func toMax*(
  mll: mag.LayoutLookup,
  lmap: LayerMap,
  tech: string,
): max.LayoutLookup =
  for cell, layout in mll:
    var mx = toMax(layout, lmap)
    mx.defs[""].version = layout.timestamp
    mx.tech = tech
    mx.resolution = 1
    mx.version = 3
    result[cell] = mx


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

func toMag(
  layout: max.Layout,
  entryCell: string,
  lmap: LayerMap,
  mll: var mag.LayoutLookup,
  tech: string
) =
  for name, component in layout.defs:
    var mag = mag.Layout()
    mag.tech = tech
    mag.timestamp = component.version

    for lname, layer in component.layers:
      let l = mapLayerName(lmap, lname)
      mag.rects[l] = layer.rects
      for lbl in layer.labels:
        mag.labels.add toMag(lbl, l)

    for _, ins in component.instances:
      for u in ins.uses:
        mag.uses.add toMag(u, ins, component.version)

    mll[toMag(name or entryCell)] = mag

func toMag*(
  mll: max.LayoutLookup,
  lmap: LayerMap,
  tech: string
): mag.LayoutLookup =
  for name, layout in mll:
    toMag layout, name, lmap, result, "scmos"


template convLayoutFn*(_: typedesc[max.Layout]): untyped = toMax
template convLayoutFn*(_: typedesc[mag.Layout]): untyped = toMag
