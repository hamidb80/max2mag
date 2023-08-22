import std/[unittest, tables, sequtils, os]
import ../src/pkg/[max, mag, bridge]


discard existsOrCreateDir "./temp"

test "max":
  # let m = parseMax readfile "./dist/max_tutorial/tutorial/NAND2.max"
  let m = parseMax readfile "./dist/tut/array.max"
  writeFile "./temp/array2.max", $m

# test "mag":
#   let m = parseMag readFile "./dist/tut/tut4x.mag"
#   print m

# test "max -> mag":
#   for p in [
#     "./dist/tut/array.max",
#     "./dist/inv-buff/micro-magic/Buf.max"
#   ]:
#     let
#       sp = splitFile p
#       max = parseMax readfile p
#       magTable = toMag(max, sp.name)

#     copyFile p, "./temp" / sp.name & sp.ext
#     for cell, layout in magTable:
#       writeFile "./temp" / cell & ".mag", $layout

# test "mag -> max":
#   discard
