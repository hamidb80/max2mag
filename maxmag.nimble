# Package

version       = "0.0.1"
author        = "hamidb80" # hr.bolouri@gmail.com
description   = "layout converter for Openfabless Magic (.mag) and Micro Magic (.max)"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
# bin           = @["maxmag"]


# Dependencies

requires "nim >= 2.0.0"

task gen, "generates app":
    mkdir "./bin/"
    exec "nim -d:release --opt:speed --mm:arc -o:./bin/maxmag c src/main.nim"
