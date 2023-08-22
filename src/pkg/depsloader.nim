import std/[tables, os, strformat, lists]
import ./[max, mag, common]

proc findFile*(fname: string; searchPaths: seq[string]): string =
  for sp in searchPaths:
    let fp = sp / fname
    if fileExists fp:
      return fp

  err fmt "The file '{fname}' not found in search paths.\nSearch paths:\n {searchPaths}"

proc loadDeps[L](
  mll: var Table[string, L];
  cells: var DoublyLinkedList[string];
  searchPaths: seq[string];
) =
  for cellName in items(cells):
    for d in externalDeps mll[cellName]:
      if d notin mll:
        cells.append d
        mll[d] = parseLayout(L, readFile findFile(d & fileExt(L), searchPaths))

proc loadDeps*[L](
  layout: L;
  cellName: string;
  searchPaths: seq[string]
): Table[string, L] =
  var cells = initDoublyLinkedList[cell >> string]()
  cells.append(cellName)
  result[cellName] = layout
  loadDeps(result, cells, searchPaths)
