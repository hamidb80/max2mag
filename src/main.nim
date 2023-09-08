import std/[tables, sequtils, lists, strutils, strformat, paths, os]
import ./pkg/[mag, max, bridge, depsloader, common, types]


proc convertImpl[L1, L2](
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
    convertImpl[max.Layout, mag.Layout](files, searchPaths, destPath, layerMapperPath, tech)
  of mag2max:
    convertImpl[mag.Layout, max.Layout](files, searchPaths, destPath, layerMapperPath, tech)


func cmdParams2Table(s: seq[string]): OrderedSeqTable[string, string] =
  var lastKey = ""

  for w in s:
    if w.startswith '-':
      lastKey = w
    else:
      result.add lastKey, w

when isMainModule:
  const help = dedent """
  USAGE:
    ./app 
        -I <MAX_or_MAG_FILE_1> <MAX_or_MAG_FILE_2> ...
        -O <DEST_DIR>
        -S <DEPENDENCY_SEARCH_DIR_1> <DEPENDENCY_SEARCH_DIR_2> ...
        -T <TECH>
        -L <LAYER_MAPPER_FILE_PATH>
  """

  let params = cmdParams2Table commandLineParams()
  if params.len == 0: quit help
  else:
    var
      files, searchPaths: seq[Path]
      destDir, layerMapperPath: Path
      tech: string

    for cmd, args in params:
      case cmd
      of "-I", "--input": # add input file
        files.add toPaths args
      of "-S", "--search": # search path
        searchPaths.add toPaths args
      of "-O", "--out": # output dir
        destDir = Path args[0]
      of "-L", "-l": # layer mapper
        layerMapperPath = Path args[0]
      of "-T", "--tech": # dest tech
        tech = args[0]
      else:
        err fmt"invalid flag {cmd}"

    assert tech != "", "tech is not specified"
    assert files.len != 0, "no input files provided"
    assert destDir.string.len != 0, "output dir is missing"
    assert layerMapperPath.string.len != 0, "where is your layer mapper ??"

    let
      ext = files[0].string.splitFile.ext
      mode =
        case ext
        of ".max", ".MAX": max2mag
        of ".mag", ".MAG": mag2max
        else: err fmt"invalid input file format, expected .max or .mag but got: '{ext}'"

    convert mode, files, searchPaths, destDir, layerMapperPath, tech
