# Written by audin 2023/02
# For Windows10.
# For Linux Debian 11 Bullseye,
#   $ sudo apt install xorg-dev libopengl-dev ibgl1-mesa-glx libgl1-mesa-dev
#   $ nim cpp -r -d:danger -d:strip --nimcache:.nimcahce src/nimgl_test.nim

import nimgl/[opengl, glfw]
import imguin
#
echo "[ This is dummy program to make src/cimguiDefs.nim ]"
