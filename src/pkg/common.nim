import std/[macros]


template err*(msg): untyped =
  raise newException(ValueError, msg)

macro addMulti*(container: untyped, values: varargs[untyped]): untyped =
  result = newStmtList()
  for v in values:
    result.add quote do:
      `container`.add `v`
