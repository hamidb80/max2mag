import std/[unittest, tables, os, sequtils]
import pretty
import ../src/pkg/[max, mag, bridge]

proc refreshDir(path: string) = 
  if dirExists path:
    removeDir path
  createDir path

refreshDir "./temp"

# test "max":
#   # let m = parseMax readfile "./dist/max_tutorial/tutorial/NAND2.max"
#   let m = parseMax readfile "./dist/tut/array.max"
#   print m

# test "mag":
#   let m = parseMag readFile "./dist/tut/tut4x.mag"
#   print m

test "max -> mag":
  let 
    max = parseMax readfile "./dist/tut/array.max"
    magTable = toMag(max, "array")
  
  # print max
  # print magTable.keys.toseq
  for cell, layout in magTable:
    writeFile "./temp" / (cell & ".mag"), $layout
    # echo $layout
    