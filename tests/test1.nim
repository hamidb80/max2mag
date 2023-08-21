import std/[unittest, tables, os, sequtils]
import pretty
import ../src/pkg/[max, mag, bridge]


discard existsOrCreateDir "./temp"

# test "max":
#   # let m = parseMax readfile "./dist/max_tutorial/tutorial/NAND2.max"
#   let m = parseMax readfile "./dist/tut/array.max"
#   print m

# test "mag":
#   let m = parseMag readFile "./dist/tut/tut4x.mag"
#   print m

test "max -> mag":
  for p in [
    "./dist/tut/array.max",
    "./dist/inv-buff/micro-magic/Buf.max"
  ]:
    let 
      pff = splitFile p
      max = parseMax readfile p
      magTable = toMag(max, pff.name)

    copyFile p, "./temp" / pff.name & pff.ext
    for cell, layout in magTable:
      writeFile "./temp" / cell & ".mag", $layout
      