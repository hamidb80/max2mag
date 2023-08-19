import std/[strutils, tables, sequtils, parseutils, sugar]
import labeledtypes
import ./common

type
  Instance = object

  Rect = array[4, int]
  Label = object

  Parts = object
    rects: seq[Rect]
    lables: seq[Label]

  Component = object
    layers: Table[string, Parts]
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
      err "not a valid char: " & curr

    last = curr

func toArr[N: static int; T](s: seq[T]): array[N, T] =
  for i in 0 ..< N:
    result[i] = s[i]

type 
  UnderLine = object

func parseUnderline()

type
  MagicIdent = object
    name: string
    params: Table[string, string]

func parseMagicIdent(s: string, offset: Natural): MagicIdent =
  let parts = s.split '!'
  result.name = parts[0][(offset+1)..^1]
  for i in countup(1, parts.high, 2):
    result.params[parts[i][1..^1]] = parts[i+1]

func parseMax(content: string): MaxLayoutFile =
  var
    layer = ""
    defi = 0

  for line in splitLines content:
    if not line.isEmptyOrWhitespace:
      let
        tokens = lex line
        head = tokens[0]

      case head.kind
      of mtkIdent:
        case head.strval
        of "max": result.version = tokens[1].intVal
        of "tech": result.tech = tokens[1].strVal
        of "resolution": result.resolution = tokens[1].floatVal
        of "DEF":
          case tokens.len
          of 1:
            defi = 0
          of 4:
            let
              compoundName = parseMagicIdent(tokens[1].strval, 0)
              _ = tokens[2]
              id = tokens[3]

          else:
            err "what??"

        of "layer":
          layer = tokens[1].strval

        of "lab":
          layer = tokens[1].strval
          let
            pos = tokens[2..5].map(t => t.intval)
            what = tokens[6..7].map(t => t.intval)
            txt = tokens[8].strVal

        of "gcell":
          let
            id = tokens[1].intval
            instanceName = tokens[2].strVal

        of "bbox":
          let bound = tokens[1..4].map(t => t.intval)

        of "SECTION", "uses", "vMAIN", "vDRC", "vBBOX": discard
        else: # in uses
          case head.strval[0]
          of '_': discard
          of '/':
            let 
              i = head.strval.find('_')
              mi = parseMagicIdent(, 1)
            debugEcho mi
          else: err "invalid"

      of mtkInt: # in layer
        let bound = toArr[4, int](tokens.map(t => t.intVal))


      of mtkCloseBracket, mtkComment: discard
      else: err "invalid node kind: " & $head.kind & ' ' & $head


echo parseMax readfile "./dist/max_tutorial/tutorial/NAND2.max"
