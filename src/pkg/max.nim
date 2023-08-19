import std/[strutils, tables, sequtils, options, parseutils, sugar]
import ./common

type
  RectPart = enum
    l # left
    b # bottom
    r # right
    t # top

  Rect = array[RectPart, int]

  TransformPart = enum
    a, b, c, d, e, f

  Transform = array[TransformPart, int]

  Use = object # TODO what is partial ??
    id: int
    ident: Option[MaxIdent]
    trans: Transform

  Instance = ref object
    comp: Component
    bound: Rect
    uses: seq[Use]

  Label = object
    pos: Rect
    text: string
    what1: int
    what2: int

  Layer = object
    name: string
    rects: seq[Rect]
    labels: seq[Label]

  MaxIdent = object
    name: string
    params: Table[string, string]

  Component = ref object
    ident: MaxIdent
    layers: Table[string, Layer]
    instances: seq[Instance]
    # versions ??

  MaxLayoutFile* = object
    version: int
    tech: string
    resolution: float
    defs: Table[int, Component]

  MaxTokenKind = enum
    mtkComment
    mtkInt
    mtkFloat
    mtkIdent
    mtkString
    mtkOpenBracket
    mtkCloseBracket
    mtkSep

  MaxToken = object
    case kind: MaxTokenKind
    of mtkInt:
      intVal: int
    of mtkFloat:
      floatVal: float
    of mtkString, mtkIdent, mtkComment:
      strVal: string
    else:
      nil


func parseString(content: string, offset: int, buff: var string): Natural =
  let i = content.find('"', offset + 1)
  buff = content[offset+1 ..< i]
  i - offset + 1

func parseComment(content: string, offset: int, buff: var string): Natural =
  let i = block:
    let t = content.find('\n', offset)
    if t == -1: content.len
    else: t

  buff = content[offset+1 ..< i]
  i - offset

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

func addLayerIfNotExists(layers: var Table[string, Layer], layer: string) =
  if layer notin layers:
    layers[layer] = Layer(name: layer)

func addRect(layers: var Table[string, Layer], layer: string, bound: Rect) =
  addLayerIfNotExists layers, layer
  layers[layer].rects.add bound

func addLabel(layers: var Table[string, Layer], layer: string, lbl: Label) =
  addLayerIfNotExists layers, layer
  layers[layer].labels.add lbl

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

    of Newlines:
      inc i
      sett MaxToken(kind: mtkSep)

    of '{':
      inc i
      sett MaxToken(kind: mtkOpenBracket)

    of '}':
      inc i
      sett MaxToken(kind: mtkCloseBracket)

    of '#':
      if last == '\n':
        inc i, parseComment(content, i, buffs)
        sett MaxToken(kind: mtkComment, strval: buffs)
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

func toArr[N: static int; T](s: seq[T], offset: Natural = 0): array[N, T] =
  for i in 0 ..< N:
    result[i] = s[i+offset]

func toTransform(s: seq[int]): Transform =
  assert s.len == 6
  Transform toArr[6, int](s)

func toInts(s: seq[MaxToken]): seq[int] =
  s.map(t => t.intval)

func toRect(s: seq[int]): Rect = 
  toArr[4, int](s)


func parseMaxIdent(s: string): MaxIdent =
  let parts = s.split '!'
  result.name = parts[0][1..^1]
  for i in countup(1, parts.high, 2):
    result.params[parts[i][1..^1]] = parts[i+1]

func parseMax(content: string): MaxLayoutFile =
  var
    layer = ""
    defi = 0
    defIdent: MaxIdent

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
          (defi, defIdent) =
            case tokens.len
            of 1: (0, MaxIdent())
            of 4:
              let c = parseMaxIdent tokens[1].strval
              (c.params["_version"].parseInt, c)
            else:
              err "what??"

          result.defs[defi] = Component(ident: defIdent)

        of "layer":
          layer = tokens[1].strval

        of "lab":
          layer = tokens[1].strval
          let
            ints = tokens[2..7].toInts
            lbl = Label(
              text: tokens[8].strVal,
              pos: toRect(ints),
              what1: ints[4],
              what2: ints[5])

          result.defs[defi].layers.addLabel layer, lbl

        of "gcell":
          let id = tokens[1].intval
          # instanceName = tokens[2].strVal

          result.defs[defi].instances.add Instance(
            comp: result.defs[id])

        of "bbox":
          let bound = toRect tokens[1..4].toInts
          result.defs[defi].instances[^1].bound = bound

        of "SECTION", "uses", "vMAIN", "vDRC", "vBBOX": discard

        else: # in uses
          var u: Use
          (u.id, u.ident, u.trans) =
            case h[0]
            of '_': 
              (parseInt h[1..^1], 
                none MaxIdent, 
                toTransform(tokens[1..^1].toInts))

            of '/':
              let i = h.find('_')
              (parseInt h[i+1..^1], 
                some parseMaxIdent h[1..<i], 
                toTransform(tokens[1..^1].toInts))

            else: err "invalid"
          
          result.defs[defi].instances[^1].uses.add u

      of mtkInt: # in layer
        let bound = toRect (tokens.toInts)
        result.defs[defi].layers.addRect layer, bound

      of mtkCloseBracket, mtkComment: discard
      else: err "invalid node kind: " & $head.kind & ' ' & $head

import pretty
let m = parseMax readfile "./dist/max_tutorial/tutorial/NAND2.max"
print m
