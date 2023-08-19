import std/[tables, strutils, strformat]
import ./pkg/mag
import pretty

echo parseMag readFile "./dist/mag-samples/buff101.mag"