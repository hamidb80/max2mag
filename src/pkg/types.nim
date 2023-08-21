import std/tables

type
  # SeqTable*[A, B] = Table[A, seq[B]]
  OrderedSeqTable*[A, B] = Table[A, seq[B]]


func add*[A, B](st: var OrderedSeqTable[A, B], key: A, val: B) =
  if key in st:
    st[key].add val
  else:
    st[key] = @[val]
