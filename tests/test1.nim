import std/[unittest, os, paths, sequtils]
import ../src/pkg/[types, common]
import ../src/main

discard existsOrCreateDir "./temp"

test "max -> mag":
  let files = toPaths @[
    "./dist/inv-buff/micro-magic/Buf.max",
    "./dist/tut/array.max",
    "./dist/group.max"]

  convert max2mag, files, @[], Path "./temp/", Path "./layers.max2mag.cfg", "mmi25"

test "mag -> max":
  let files = toPaths toseq walkFiles "./dist/tut/*.mag"

  convert mag2max, files, @[Path "./dist/tut/"], Path "./temp/",
      Path "./layers.mag2max.cfg", "scmos"
