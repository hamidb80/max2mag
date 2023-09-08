import std/[tables, sequtils, paths, lists]
import ./pkg/[mag, max, bridge, depsloader, common]



proc conv*[L1, L2](
  files, searchPaths: seq[Path],
  destPath, layerMapperPath: Path,
  tech: string,
) =
  var lookup: Table[string, L1]
  let lmap = parseLayerMapper readFile layerMapperPath

  for path in files:
    let pparts = splitFile path
    lookup[pparts.name] = (parseLayoutFn L1)(readFile path)

  lookup.loadDeps toseq keys lookup, searchPaths

  for cell, layout in (convLayoutFn L2)(lookup, lmap, tech):
    writeFile destPath / (cell & (fileExt L2)), $layout


proc convert*(
  mode: ConvMode,
  files, searchPaths: seq[Path],
  destPath, layerMapperPath: Path,
  tech: string
) =
  case mode
  of max2mag:
    conv[max.Layout, mag.Layout](files, searchPaths, destPath, layerMapperPath, tech)
  of mag2max:
    conv[mag.Layout, max.Layout](files, searchPaths, destPath, layerMapperPath, tech)
