import std/[tables, strformat, strutils, lists, options, paths, os]
import ./[common]


type
  Use* = object
    cell*: string
    name*: string
    timestamp*: int
    transform*: CompactTransform
    box*: Rect
    array*: Option[Array]

  Label* = object
    layer*: string
    position*: Rect
    kind*: int # TODO
    text*: string

  MagLayout* = object
    tech*: string
    timestamp*: int
    rects*: OrderedTable[layer >> string, seq[Rect]]
    labels*: seq[Label]
    uses*: seq[Use]

  MagLayoutLookup* = Table[cellName >> string, MagLayout]


iterator deps*(l: MagLayout): string =
  for u in l.uses:
    yield u.cell

# func layers*(mag: MagLayout): seq[string] =
#   var allLayers = initHashSet[string]()

#   for layer in mag.rects.keys:
#     allLayers.incl layer
#   for lbl in mag.labels:
#     allLayers.incl lbl.layer

#   a llLayers.toseq

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
        if lastLayer notin result.rects:
          result.rects[lastLayer] = @[]
        result.rects[lastLayer].add r
      of "rlabel":
        result.labels.add Label(
          layer: parts[1],
          position: Rect toArrMap[4, string, int](parts, parseInt, 2),
          kind: parseint parts[6],
          text: parts[7])

      else: err fmt"invalid command '{parts[0]}'"

func `$`*(mag: MagLayout): string =
  result.add "magic\n"
  result.add fmt "tech {mag.tech}\n"
  result.add fmt "timestamp {mag.timestamp}\n"

  for k, v in mag.rects:
    if v.len != 0:
      result.add fmt "<< {k} >>\n"
      for r in v:
        result.add fmt "rect {joinSpaces r}\n"

  if mag.labels.len != 0:
    result.add "<< labels >>\n"

  for l in mag.labels:
    result.add fmt "rlabel {l.layer} {joinSpaces l.position} {l.kind} \"{l.text}\"\n"
  for u in mag.uses:
    result.add fmt "use {u.cell} {u.name}\n"

    if isSome u.array:
      result.add fmt "array {joinSpaces u.array.get}\n"

    result.add fmt "timestamp {u.timestamp}\n"
    result.add fmt "transform {joinSpaces u.transform}\n"
    result.add fmt "box {joinSpaces u.box}\n"

  result.add "<< end >>\n"

func `$`(p: Path): string {.borrow.}

proc cellPath(
  cellName: string,
  searchPaths: seq[Path]
): Path =
  for sp in searchPaths:
    let fp = sp / (cellName & ".mag").Path
    if fileExists fp.string:
      return fp

  err fmt "The cell '{cellName}' not found in search paths.\nSearch paths: {searchPaths}"

proc loadDeps(
  mll: var MagLayoutLookup,
  cells: var DoublyLinkedList[string],
  searchPaths: seq[Path],
) =
  for cellName in cells:
    for d in deps mll[cellName]:
      if d notin mll:
        cells.append d
        mll[d] = parseMag readFile string cellPath(d, searchPaths)

proc loadDeps*(
  layout: MagLayout,
  cellName: string,
  searchPaths: seq[Path]
): MagLayoutLookup =
  var cells = initDoublyLinkedList[cell >> string]()
  cells.append cellName
  result[cellName] = layout
  loadDeps result, cells, searchPaths
