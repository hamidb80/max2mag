# Package

version       = "0.0.1"
author        = "hamidb80"
description   = "layout converter for Openfabless Magic (.mag) and Micro Magic (.max)"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["max2mag"]


# Dependencies

requires "nim >= 2.0.0"

task gen, "generates app":
    exec "nim -d:release -o:./maxmag c src/main.nim"
