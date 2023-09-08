import std/[os, strutils, paths]


type ConvMode* = enum
  max2mag
  mag2max


converter toStrs*(p: Path): string = p.string

func toPaths*(ps: seq[string]): seq[Path] =
  cast[seq[Path]](ps)

type
  Align* = enum
    c  # GEO_CENTER
    n  # GEO_NORTH
    ne # GEO_NORTHEAST
    e  # GEO_EAST
    se # GEO_SOUTHEAST
    s  # GEO_SOUTH
    sw # GEO_SOUTHWEST
    w  # GEO_WEST
    nw # GEO_NORTHWEST

  RectPart* = enum
    l # left
    b # bottom
    r # right
    t # top

  Rect* = array[RectPart, int]

  CompactTransformPart* = enum
    a, b, c, d, e, f

  CompactTransform* = array[CompactTransformPart, int]

  ArrayParts* = enum
    xlow, xhigh, xsep
    ylow, yhigh, ysep

  Array* = array[ArrayParts, int]


template `>>`*(lable, typee): untyped =
  ## type annonator
  typee

template err*(msg): untyped =
  raise newException(ValueError, msg)

template writeFile*(p: Path, c: string): untyped =
  writeFile string p, c

template `/`*(p: Path, s: string): untyped =
  p / Path s

template `or`*(a, b: string): string =
  if a == "": b
  else: a

template iff*(cond, ok, bad): untyped =
  if cond: ok
  else: bad


func joinSpaces*[T](r: openArray[T]): string =
  r.join " "

func strip*(s: string; ch: char): string =
  s.strip(chars = {ch})


func toArr*[N: static int; T](s: seq[T]; offset: Natural = 0): array[N, T] =
  for i in 0 ..< N:
    result[i] = s[i+offset]

func toArrMap*[N: static int; A, B](
  s: seq[A];
  fn: proc(a: A): B;
  offset: Natural
): array[N, B] {.effectsOf: fn.} =
  for i in 0 ..< result.len:
    result[i] = fn s[i+offset]

