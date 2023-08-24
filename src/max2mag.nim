import std/[tables, sequtils, paths, lists]
import ./pkg/[mag, max, bridge, depsloader, common]



proc conv*[L1, L2](files, searchPaths: seq[Path], destPath: Path) =
  var lookup: Table[string, L1]

  for path in files:
    let pparts = splitFile path
    lookup[pparts.name] = (parseLayoutFn L1)(readFile path)

  lookup.loadDeps toseq keys lookup, searchPaths

  for cell, layout in (convLayoutFn L2)(lookup):
    writeFile destPath / (cell & (fileExt L2)).Path, $layout


proc max2mag*(files, searchPaths: seq[Path], destPath: Path) =
  conv[max.Layout, mag.Layout](files, searchPaths, destPath)

proc mag2max*(files, searchPaths: seq[Path], destPath: Path) =
  conv[mag.Layout, max.Layout](files, searchPaths, destPath)
