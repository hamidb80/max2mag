import std/[tables, sequtils, options, strutils, parseutils, strformat, lists, sets]
import ./common


type
  Use* = object
    ident*: string
    transform*: CompactTransform
    array*: Option[Array]

  Instance* = ref object
    comp*: string
    bound*: Rect
    uses*: seq[Use]

  LabelKind* = enum
    lComment
    lHidden
    lLocal
    lGlobal
    lInput
    lOutput
    lInOut
    lMaxKind

  Label* = object
    position*: Rect
    text*: string
    orient*: Align
    kind*: LabelKind

  Layer* = object
    rects*: seq[Rect]
    labels*: seq[Label]
    # POLYGONS
    # WIREPATH

  # LayerTable = OrderedTable[layer >> string, Layer]
  LayerTable = Table[layer >> string, Layer]

  Component* = ref object
    ident*, showName*, insName*: string
    version*: int
    layers*: LayerTable
    instances*: Table[ident >> string, Instance] # main & group def can have this section

  DefineTable = Table[defIdent >> string, Component]

  Layout* = object
    version*: int
    tech*: string
    resolution*: float
    defs*: DefineTable

  LayoutLookup* = Table[defIdent >> string, Layout]

  MaxTokenKind* = enum
    mtkComment
    mtkInt
    mtkFloat
    mtkIdent
    mtkString
    mtkOpenBracket
    mtkCloseBracket

  MaxToken* = object
    case kind*: MaxTokenKind
    of mtkInt:
      intVal*: int
    of mtkFloat:
      floatVal*: float
    of mtkString, mtkIdent, mtkComment:
      strVal*: string
    else:
      nil


iterator externalDeps(l: Layout): string =
  var internalDeps = initHashSet[string]()
  for name, comp in l.defs:
    if name != "":
      for ident, ins in comp.instances:
        internalDeps.incl ident

  for ident, ins in l.defs[""].instances:
    if ident notin internalDeps:
      yield ident

func addLayerIfNotExists(layers: var LayerTable, layer: string) =
  if layer notin layers:
    layers[layer] = Layer()

func addRect*(layers: var LayerTable, layer: string, bound: Rect) =
  addLayerIfNotExists layers, layer
  layers[layer].rects.add bound

func addLabel*(layers: var LayerTable, layer: string, lbl: Label) =
  addLayerIfNotExists layers, layer
  layers[layer].labels.add lbl


func toRect(s: seq[int]): Rect =
  toArr[4, int](s)

func getInt(mt: MaxToken): int =
  mt.intval

func toInts(mts: seq[MaxToken]): seq[int] =
  mts.map getInt


func parseString(content: string, offset: int, buff: var string): Natural =
  let i = content.find('"', offset + 1)
  buff = content[offset+1 ..< i]
  i - offset + 1

func parseNumber(content: string, offset: int,
  buffi: var int, bufff: var float, isFloat: var bool): Natural =

  isFloat = false
  for i in offset .. content.high:
    case content[i]
    of Digits: discard
    of '.':
      if isFloat: err "number with 2 dots?"
      else: isFloat = true
    else: break

  if isFloat:
    parseFloat(content, bufff, offset)
  else:
    parseInt(content, buffi, offset)

func parseMaxIdent(content: string, offset: int, buff: var string): Natural =
  var tail = content.len
  for i in offset .. content.high:
    case content[i]
    of '!', '#', '-', '.', '/', IdentChars: discard
    else:
      tail = i
      break

  buff = content[offset..<tail]
  tail - offset

func lex(content: string): seq[MaxToken] =
  var
    i = 0
    last = '\n'
    temp = false

  template sett(t): untyped {.dirty.} =
    result.add t

  while i < content.len:
    let curr = content[i]
    var
      buffs = ""
      buffi = 0
      bufff = 0.0

    case curr
    of ' ', '\t':
      inc i

    of '{':
      inc i
      sett MaxToken(kind: mtkOpenBracket)

    of '}':
      inc i
      sett MaxToken(kind: mtkCloseBracket)

    of '#':
      if last == '\n':
        inc i, content.len
        sett MaxToken(kind: mtkComment, strval: content)
      else:
        inc i, parseMaxIdent(content, i, buffs)
        sett MaxToken(kind: mtkIdent, strval: buffs)

    of IdentStartChars, '/':
      inc i, parseMaxIdent(content, i, buffs)
      sett MaxToken(kind: mtkIdent, strval: buffs)

    of '"':
      inc i, parseString(content, i, buffs)
      sett MaxToken(kind: mtkString, strval: buffs)

    of Digits, '-':
      inc i, parseNumber(content, i, buffi, bufff, temp)
      if temp:
        sett MaxToken(kind: mtkFloat, floatVal: bufff)
      else:
        sett MaxToken(kind: mtkInt, intval: buffi)

    else:
      err "not a valid char: '" & curr & "'"

    last = curr

const versionIdentifier* = "!-_version!"
func splitMaxIdent(s: string): tuple[ident: string, version: Option[int]] =
  let parts = s.split versionIdentifier
  result.ident = parts[0]
  if parts.len == 2:
    result.version = some parseInt parts[1]

func parseMax*(content: string): Layout =
  var
    layer = ""
    defVer = 0
    defName: string
    gcellName: string

  for line in splitLines content:
    if not line.isEmptyOrWhitespace:
      let
        tokens = lex line
        head = tokens[0]

      case head.kind
      of mtkIdent:
        let h = head.strval
        case h
        of "max": result.version = tokens[1].intVal
        of "tech": result.tech = tokens[1].strVal
        of "resolution": result.resolution = tokens[1].floatVal
        of "DEF":
          (defName, defVer) =
            case tokens.len
            of 1: ("", 0)
            of 4:
              let c = splitMaxIdent tokens[1].strval
              (c.ident, c.version.get)
            else:
              err "what??"

          result.defs[defName] = Component(
            ident: defName,
            showName: iff(tokens.len == 4, tokens[2].strVal, ""),
            insName: iff(tokens.len == 4, tokens[3].strVal, ""),
            version: defVer)

        of "layer":
          layer = tokens[1].strval

        of "lab":
          layer = tokens[1].strval
          let
            ints = tokens[2..7].toInts
            lbl = Label(
              text: tokens[8].strVal,
              position: toRect ints,
              orient: Align ints[4],
              kind: LabelKind ints[5])

          result.defs[defName].layers.addLabel layer, lbl

        of "gcell":
          gcellName = tokens[2].strval

          result.defs[defName].instances[gcellName] = Instance(
            comp: gcellName)

        of "bbox":
          let bound = toArrMap[4, MaxToken, int](tokens, getInt, 1)
          result.defs[defName].instances[gcellName].bound = bound

        of "SECTION", "uses": discard
        of "vMAIN", "vDRC", "vBBOX":
          result.defs[""].version = tokens[1].intVal

        else: # in uses
          let arr =
            if tokens.len > 7:
              assert tokens[7].strval == "array"
              some Array toArrMap[6, MaxToken, int](tokens, getInt, 8)
            else:
              none Array
          result.defs[defName].instances[gcellName].uses.add Use(
            ident: h,
            transform: toArrMap[6, MaxToken, int](tokens, getInt, 1),
            array: arr)

      of mtkInt: # in layer
        let bound = toRect tokens.toInts
        result.defs[defName].layers.addRect layer, bound

      of mtkCloseBracket, mtkComment: discard
      else: err "invalid node kind: " & $head.kind & ' ' & $head

func `$`*(layout: Layout): string =
  result.add "# This file is created by max2mag tool\n\n"
  result.add fmt "max {layout.version}\n"
  result.add fmt "tech {layout.tech}\n"
  result.add fmt "resolution {layout.resolution}\n"

  proc addDef(buff: var string, name: string, d: Component, isMainDef: bool) =
    buff.add "\n\n"
    if isMainDef: # main section
      buff.add "DEF\n"
      buff.add "\nSECTION VERSIONS {\n"
      buff.add fmt "vMAIN {d.version} 1\n"
      buff.add fmt "vDRC {d.version} 1\n"
      buff.add fmt "vBBOX {d.version} 1\n"
      buff.add "} SECTION VERSIONS\n"
    else:
      buff.add fmt "DEF {name} \"{d.showName}\" \"{d.insName}\"\n"

    buff.add "\nSECTION RECTS {\n"
    for lname, layer in d.layers:
      buff.add fmt "layer {lname}\n"
      for r in layer.rects:
        buff.add fmt "{joinSpaces r}\n"
    buff.add "} SECTION RECTS\n"

    buff.add "\nSECTION LABELS {\n"
    for lname, layer in d.layers:
      for lbl in layer.labels:
        buff.add fmt "lab {lname} {joinSpaces lbl.position} {lbl.orient.int} {lbl.kind.int} {lbl.text}\n"
    buff.add "} SECTION LABELS\n"

    # buff.add "\nSECTION GROUPS {\n"
    # buff.add "} SECTION GROUPS\n"

    if d.instances.len != 0:
      buff.add "\nSECTION INSTANCES {\n"

      for ident, ins in d.instances:
        buff.add fmt "gcell {d.version} {ident}\n"
        buff.add fmt "bbox {joinSpaces ins.bound}\n"
        buff.add "uses {\n"
        for u in ins.uses:
          buff.add fmt "\t{u.ident} {joinSpaces u.transform}"
          if issome u.array:
            buff.add fmt " array {joinSpaces u.array.get}\n"
          else:
            buff.add "\n"
        buff.add "}\n"
      buff.add "} SECTION INSTANCES\n"

  for name, d in layout.defs:
    if name != "":
      result.addDef name, d, false

  result.addDef "", layout.defs[""], true


proc loadDeps(
  mll: var LayoutLookup,
  cells: var DoublyLinkedList[string],
  searchPaths: seq[string],
) =
  for cellName in cells:
    for d in externalDeps mll[cellName]:
      if d notin mll:
        cells.append d
        mll[d] = parseMax readFile findFile(d & ".max", searchPaths)

proc loadDeps*(
  layout: Layout,
  cellName: string,
  searchPaths: seq[string]
): LayoutLookup =
  var cells = initDoublyLinkedList[cell >> string]()
  cells.append cellName
  result[cellName] = layout
  loadDeps result, cells, searchPaths
