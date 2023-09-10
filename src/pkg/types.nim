import std/tables

type
  # SeqTable*[A, B] = Table[A, seq[B]]
  OrderedSeqTable*[A, B] = Table[A, seq[B]]

  ConvMode* = enum
    max2mag = "max => mag"
    mag2max = "mag => max"


func add*[A, B](st: var OrderedSeqTable[A, B], key: A, val: B) =
  if key in st:
    st[key].add val
  else:
    st[key] = @[val]
