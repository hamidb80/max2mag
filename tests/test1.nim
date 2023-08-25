import std/[unittest, os, paths, sequtils]
import ../src/pkg/[max, mag, common]
import ../src/max2mag
# import pretty

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


test "max -> mag":
  let files = toPaths @[
    "./dist/inv-buff/micro-magic/Buf.max",
    "./dist/tut/array.max",
    "./dist/group.max"]

  max2mag files, @[], Path "./temp/"

test "mag -> max":
  let files = toPaths toseq walkFiles "./dist/tut/*.mag"
  mag2max files, @[Path "./dist/tut/"], Path "./temp/"

# test "load max deps":
#   let
#     path = "./temp/tut4a.max"
#     pparts = splitFile path
#     maxlayout = parseMax readFile path
#     mxlkup = maxlayout.loadDeps(pparts.name, @[pparts.dir])

#   print mxlkup
