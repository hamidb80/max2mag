import std/[tables, strformat, strutils, options]
import ./[types, common]


type
  Use* = object
    cell*: string
    name*: string
    timestamp*: int
    transform*: CompactTransform
    box*: Rect
    array*: Option[Array]

  RLabel* = object
    layer*: string
    position*: Rect
    kind*: int # TODO
    text*: string

  # TODO does order of stored layers matter ??
  MagLayout* = object
    tech*: string
    timestamp*: int
    rects*: OrderedSeqTable[layer >> string, Rect]
    rlabels*: seq[RLabel]
    uses*: seq[Use]

  MagLayoutTable* = Table[cellName >> string, MagLayout]


func parseMag*(content: string): MagLayout =
  var lastLayer = ""

  for line in content.splitLines:
    if not line.isEmptyOrWhitespace:
      let parts = line.splitWhitespace
      case parts[0]
      of "magic": discard
      of "tech": result.tech = parts[1]
      of "<<": lastLayer = parts[1]
      of "timestamp":
        let t = parseInt parts[1]
        if result.uses.len == 0:
          result.timestamp = t
        else:
          result.uses[^1].timestamp = t
      of "array":
        result.uses[^1].array = some toArrMap[6, string, int](parts, parseInt, 1)
      of "box":
        result.uses[^1].box = toArrMap[4, string, int](parts, parseInt, 1)
      of "transform":
        result.uses[^1].transform = toArrMap[6, string, int](parts, parseInt, 1)
      of "use":
        result.uses.add Use(cell: parts[1], name: parts[2])
      of "rect":
        let r = Rect toArrMap[4, string, int](parts, parseInt, 1)
        result.rects.add lastLayer, r
      of "rlabel":
        result.rlabels.add RLabel(
          layer: parts[1],
          position: Rect toArrMap[4, string, int](parts, parseInt, 2),
          kind: parseint parts[6],
          text: parts[7])

      else: err fmt"invalid command '{parts[0]}'"

func `$`*(mag: MagLayout): string =
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
      l.position.join(" "), ' ', $l.kind, ' ', l.text, '\n'

  for u in mag.uses:
    result.addMulti "use ", u.cell, ' ', u.name, '\n'

    if isSome u.array:
      result.addMulti "array ", u.array.get.join(" "), '\n'

    result.addMulti "timestamp ", $u.timestamp, '\n'
    result.addMulti "transform ", $u.transform.join(" "), '\n'
    result.addMulti "box ", u.box.join(" "), '\n'

  result.addMulti "<< end >>\n"
