# Package

version       = "1.89.9.7"
author        = "dinau"
description   = "Imguin: ImGui / ImPlot / ImNodes wrapper using Futhark"
license       = "MIT"
srcDir        = "src"
skipDirs      = @["examples","src/img","src/imguin/private/updater"]


# Dependencies

requires "nim >= 1.6.10"
requires "nimgl >= 1.3.2"
#requires "futhark >= 0.12.0"
requires "sdl2_nim"
requires "tinydialogs"
requires "stb_image"

let TARGET = "imguin"
let Opts =""

task test,"test test":
    let cmd = "nim c -d:strip -o:$# $# $#.nim" % [TARGET.toEXE,Opts,"src/" & TARGET]
    echo cmd
    exec(cmd)
