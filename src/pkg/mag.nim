import std/[tables, strformat, strutils]
import ./[types, common]


type
  RectArray* = enum
    x1, y1, x2, y2

  Rect* = array[RectArray, int]

  RLabel* = object
    layer*: string
    position*: Rect
    fontSize*: int
    text*: string

  MagicLayoutFile* = object
    tech*: string
    timestamp*: int
    rects*: SeqTable[string, Rect] # TODO does order of stored layers matter ??
    rlabels*: seq[RLabel]


func toArr[N: static int, A, B](s: seq[A], fn: proc(a: A): B,
    offset: Natural): array[N, B] {.effectsOf: fn.} =
  assert offset + result.len <= s.len
  for i in 0 ..< result.len:
    result[i] = fn s[i+offset]


func parseMag*(content: string): MagicLayoutFile =
  var lastLayer = ""

  for line in content.splitLines:
    if not line.isEmptyOrWhitespace:
      let parts = line.splitWhitespace
      case parts[0]
      of "magic": discard
      of "tech": result.tech = parts[1]
      of "timestamp": result.timestamp = parseInt parts[1]
      of "<<": lastLayer = parts[1]
      of "rect":
        let r = Rect toArr[4, string, int](parts, parseInt, 1)
        result.rects.add lastLayer, r
      of "rlabel":
        result.rlabels.add RLabel(
          layer: parts[1],
          position: Rect toArr[4, string, int](parts, parseInt, 2),
          fontSize: parseint parts[6],
          text: parts[7])

      else: err fmt"invalid command '{parts[0]}'"

func `$`*(mag: MagicLayoutFile): string =
  result.addMulti "magic", '\n'
  result.addMulti "tech ", mag.tech, '\n'
  result.addMulti "timestamp ", $mag.timestamp, '\n'

  for k, v in mag.rects:
    result.addMulti "<< ", k, " >>", '\n'
    for r in v:
      result.addMulti "rect ", r.join(" "), '\n'

  if mag.rlabels.len != 0:
    result.addMulti "<< labels >>\n"

  for l in mag.rlabels:
    result.addMulti "rlabel ", l.layer, ' ',
      l.position.join(" "), ' ', $l.fontSize, ' ', l.text, '\n'

  result.addMulti "<< end >>\n"
