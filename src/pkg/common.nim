import std/[macros]

type
  RectPart* = enum
    l # left
    b # bottom
    r # right
    t # top

  Rect* = array[RectPart, int]

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


  # Ratation = enum
  #   r0, r90, r180, r270

  # TransformKind = object
  #   rotate: Ratation
  #   isFlipped: bool # flipped upside down (mirror across the x-axis after rotating)

  # Translate = object
  #   x, y: int


template err*(msg): untyped =
  raise newException(ValueError, msg)

macro addMulti*(container: untyped, values: varargs[untyped]): untyped =
  result = newStmtList()
  for v in values:
    result.add quote do:
      `container`.add `v`


func toArr*[N: static int; T](s: seq[T], offset: Natural = 0): array[N, T] =
  for i in 0 ..< N:
    result[i] = s[i+offset]

func toArrMap*[N: static int, A, B](
  s: seq[A], 
  fn: proc(a: A): B,
  offset: Natural
): array[N, B] {.effectsOf: fn.} =
  for i in 0 ..< result.len:
    result[i] = fn s[i+offset]
