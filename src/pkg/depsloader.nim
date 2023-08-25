import std/[tables, strformat, sequtils, lists, os, paths]
import ./[max, mag, common]


converter toStr*(p: Path): string = p.string

proc findFile*(fname: Path; searchPaths: seq[Path]): Path =
  for sp in searchPaths:
    let fp = sp / fname
    if fileExists fp:
      return fp

  err fmt "The file '{fname}' not found in search paths.\nSearch paths:\n {searchPaths}"

proc loadDep[L](cell: string; searchPaths: seq[Path]): L =
  (parseLayoutFn L)(readFile findFile(Path cell & fileExt(L), searchPaths))

proc loadDepsImpl[L](
  mll: var Table[string, L];
  neededCells: var DoublyLinkedList[string];
  searchPaths: seq[Path];
) =
  for cellName in items neededCells:
    for d in externalDeps mll[cellName]:
      if d notin mll:
        neededCells.append d
        mll[d] = loadDep[L](d, searchPaths)

proc loadDeps*[L](
  mll: var Table[string, L];
  neededCells: seq[string];
  searchPaths: seq[Path];
) =
  var dll = toDoublyLinkedList neededCells
  loadDepsImpl mll, dll, searchPaths