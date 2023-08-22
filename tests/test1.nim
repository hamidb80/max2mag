import std/[unittest, tables, sequtils, os, paths]
import ../src/pkg/[max, mag, bridge]
import pretty

discard existsOrCreateDir "./temp"

# test "max":
#   # let m = parseMax readfile "./dist/max_tutorial/tutorial/NAND2.max"
#   let m = parseMax readfile "./dist/tut/array.max"
#   writeFile "./temp/array2.max", $m

# suite "mag":
#   let
#     path = "./dist/tut/tut4a.mag"
#     pparts = splitFile path
#     layout = parseMag readFile path

#   test "load":
#     print layout

#   test "load deps":
#     let lkup = loadDeps(layout, pparts.name, @[Path pparts.dir])
#     print lkup


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
#   for path in ["./dist/tut/tut4a.mag"]:
#     let
#       pparts = splitFile path
#       maglayout = parseMag readFile path
#       mglkup = loadDeps(maglayout, pparts.name, @[pparts.dir])
#       mxlkup = toMax mglkup

#     print mxlkup
#     for name, maxlayout in mxlkup:
#       writeFile "./temp" / (name & ".max"), $maxlayout

test "load max deps":
  let 
    path = "./temp/tut4a.max"
    pparts = splitFile path
    maxlayout = parseMax readFile path
    mxlkup = maxlayout.loadDeps(pparts.name, @[pparts.dir])

  print mxlkup
