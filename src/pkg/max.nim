import std/[strutils, tables, strformat, parseutils]
import ./common

type
  Instance = object
  Box = object
  Label = object

  Parts = object
    rects: seq[Box]
    lables: seq[Label]

  Component = object
    layers: Table[string, Parts]
    instances: seq[Instance]
    # versions ??

  MaxLayoutFile* = object
    version: int
    tech: string
    resolution: float
    defs: Table[string, Component]

  MaxTokenKind = enum
    ntkComment
    ntkInt
    ntkFloat
    ntkIdent
    ntkString
    ntkOpenBracket
    ntkCloseBracket
    ntkSep

  MaxToken = object
    case kind: MaxTokenKind
    of ntkInt:
      intVal: int
    of ntkFloat:
      floatVal: float
    of ntkString, ntkIdent, ntkComment:
      strVal: string
    else:
      nil


func parseString(content: string, offset: int, buff: var string): Natural =
  

func parseComment(content: string, offset: int, buff: var string): Natural =
  let i = content.find('\n', offset)
  buff = content[offset+1 ..< i]
  i - offset + 1

func parseNumber(content: string, offset: int,
  buffi: var int, bufff: var float): Natural =

  var hasfloat = false
  for i in offset .. content.high:
    case content[i]
    of Digits: discard
    of '.':
      if hasFloat: err "number with 2 ."
      else: hasfloat = true
    else: break

  if hasfloat:
    parseFloat(content, bufff, offset)
  else:
    parseInt(content, buffi, offset)

func parseMaxIdent(content: string, offset: int, buff: var string): Natural =
  for i in offset .. content.high:
    case content[i]
    of '!', '#', '-', '.', IdentChars: discard
    else:
      buff = content[offset ..< i]
      return i - offset

iterator lexify(s: string): MaxToken =
  var
    i = 0
    last = '\n'
    token: MaxToken

  template sett(t): untyped {.dirty.} =
    found = true
    token = t

  while i < s.len:
    var
      found = false
      buffs = ""
      buffi = 0
      bufff = 0.0
    let curr = s[i]
    debugEcho i

    case curr
    of ' ':
      inc i
      last = curr

    of Newlines:
      inc i
      last = curr
      sett MaxToken(kind: ntkSep)

    of '{':
      inc i
      last = curr
      sett MaxToken(kind: ntkOpenBracket)

    of '}':
      inc i
      last = curr
      sett MaxToken(kind: ntkCloseBracket)

    of '#':
      if last == '\n':
        inc i, parseComment(s, i, buffs)
        sett MaxToken(kind: ntkComment, strval: buffs)
      else:
        inc i, parseMaxIdent(s, i, buffs)
        sett MaxToken(kind: ntkIdent, strval: buffs)

    of IdentStartChars, '/':
      inc i, parseMaxIdent(s, i, buffs)
      sett MaxToken(kind: ntkIdent, strval: buffs)

    of '"':
      inc i, parseString(s, i, buffs)
      sett MaxToken(kind: ntkString, strval: buffs)

    of Digits:
      inc i, parseNumber(s, i, buffi, bufff)
      if buffi == 0:
        sett MaxToken(kind: ntkFloat, floatVal: bufff)
      else:
        sett MaxToken(kind: ntkInt, intval: buffi)

    of '-':
      let next = s[i+1]
      case next
      of Digits: discard
      of IdentStartChars: discard
      else: err "invalid next char"
      inc i

    else:
      err "not a valid char: " & curr

    if found:
      yield token


func parseMax(content: string): MaxLayoutFile =
  for tk in lexify content:
    debugEcho tk


echo parseMax readfile "./dist/max_tutorial/tutorial/NAND2.max"
