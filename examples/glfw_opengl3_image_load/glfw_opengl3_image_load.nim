import std/[strutils]
import nimgl/[opengl,glfw]

import imguin/[glfw_opengl]
import imguin/lang/imgui_ja_gryph_ranges
import stb_image/read as stbi
import ../utils/loadImage

include ../utils/setupFonts
include imguin/simple


const MainWinWidth = 1024
const MainWinHeight = 800

#--------------
# Configration
#--------------

#  .--------------------------------------------..---------.-----------------------.------------
#  |         Combination of flags               ||         |     Viewport          |
#  |--------------------------------------------||---------|-----------------------|------------
#  | fViewport | fDocking | TransparentViewport || Docking | Transparent | Outside | Description
#  |:---------:|:--------:|:-------------------:||:-------:|:-----------:|:-------:| -----------
#  |  false    | false    |     false           ||    -    |     -       |   -     |
#  |  false    | true     |     false           ||    v    |     -       |   -     | (Default): Only docking
#  |  true     | -        |     false           ||    v    |     -       |   v     | Doncking and outside of viewport
#  |    -      | -        |     true            ||    v    |     v       |   -     | Transparent Viewport and docking
#  `-----------'----------'---------------------'`---------'-------------'---------'-------------
var
 fDocking = true
 fViewport = false
 TransparentViewport = false
 #
block:
  if TransparentViewport:
    fViewport = true
  if fViewport:
    fDocking = true

#--------------------
# Forward definition
#--------------------
proc winMain(hWin: glfw.GLFWWindow)

#------
# main
#------
proc main() =
  doAssert glfwInit()
  defer: glfwTerminate()

  if TransparentViewport:
    glfwWindowHint(GLFWVisible, GLFW_FALSE)

  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE)
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_TRUE)
  #
  var glfwWin = glfwCreateWindow(MainWinWidth, MainWinHeight)
  if glfwWin.isNil:
    quit(-1)
  glfwWin.makeContextCurrent()
  defer: glfwWin.destroyWindow()

  glfwSwapInterval(1) # Enable vsync

  #---------------------
  # Load title bar icon
  #---------------------
  const IconName = "icon.png"
  if IconName.fileExists:
    var
      w, h: int
      channels: int
      pixels: seq[byte]
    pixels = stbi.load(IconName, w, h, channels, stbi.RGBA)
    var img = GLFWImage(width: w.int32, height: h.int32
                     , pixels: cast[ptr cuchar](pixels[0].addr))
    glfw.setWindowIcon(glfwWin, 1, img.addr)
  else:
    glfw.setWindowIcon(glfwWin, 0, nil)
  #
  doAssert glInit() # OpenGL init

  # setup ImGui
  let context = igCreateContext(nil)
  defer: context.igDestroyContext()
  if fDocking:
    var pio = igGetIO()
    pio.ConfigFlags = pio.ConfigFlags or ImGui_ConfigFlags_DockingEnable.cint
    if fViewport:
      pio.ConfigFlags = pio.ConfigFlags or ImGui_ConfigFlags_ViewportsEnable.cint
      pio.ConfigViewports_NoAutomerge = true

  # GLFW + OpenGL
  const glsl_version = "#version 130" # GL 3.0 + GLSL 130
  doAssert ImGui_ImplGlfw_InitForOpenGL(cast[ptr glfw_opengl.GlfwWindow]( glfwwin), true)
  defer: ImGui_ImplGlfw_Shutdown()
  doAssert ImGui_ImplOpenGL3_Init(glsl_version)
  defer: ImGui_ImplOpenGL3_Shutdown()
  glfwWin.winMain()

#---------
# winMain
#---------
proc winMain(hWin: glfw.GLFWWindow) =
  var
    showDemoWindow = true
    showAnotherWindow = false
    showFirstWindow = true
    fval = 0.5f
    counter = 0
    sBuf = newString(200)
  var clearColor:ccolor
  if TransparentViewport:
    clearColor = ccolor(elm:(x:0f, y:0f, z:0f, w:0.0f)) # Transparent
  else:
    clearColor = ccolor(elm:(x:0.25f, y:0.65f, z:0.85f, w:1.0f))

  igStyleColorsClassic(nil)

  # Add multibytes font
  var (fExistMultibytesFonts ,sActiveFontName, sActiveFontTitle) = setupFonts()

  #-------------
  # Load image
  #-------------
  var
    textureId: GLuint
    textureWidth = 0
    textureHeight = 0
  const ImageName = "fuji-400.jpg"
  if ImageName.fileExists:
    if not loadTextureFromFile(ImageName, textureId, textureWidth,textureHeight):
      textureId = 0.GLuint
      echo "Error!: Image load error:  ", ImageName
  else:
    echo "Error!: Image file not found  error:  ", ImageName

  var pio = igGetIO()

  # main loop
  while not hWin.windowShouldClose:
    glfwPollEvents()

    # start imgui frame
    ImGui_ImplOpenGL3_NewFrame()
    ImGui_ImplGlfw_NewFrame()
    igNewFrame()

    if showDemoWindow:
      igShowDemoWindow(addr showDemoWindow)

    # show a simple window that we created ourselves.
    if showFirstWindow:
      igBegin("Nim: Dear ImGui test with Futhark", addr showFirstWindow, 0)
      defer: igEnd()
      var s = "GLFW v" & $glfwGetVersionString()
      igText(s.cstring)
      s = "OpenGL v" & ($cast[cstring](glGetString(GL_VERSION))).split[0]
      igText(s.cstring)
      igInputTextWithHint("InputText" ,"Input text here" ,sBuf)
      igCheckbox("Demo window", addr showDemoWindow)
      igCheckbox("Another window", addr showAnotherWindow)
      igSliderFloat("Float", addr fval, 0.0f, 1.0f, "%.3f", 0)
      igColorEdit3("Background color", clearColor.array3, 0.ImGuiColorEditFlags)

      if igButton("Button", ImVec2(x: 0.0f, y: 0.0f)):
        inc counter
      igSameLine(0.0f, -1.0f)
      igText("counter = %d", counter)
      igText("Application average %.3f ms/frame (%.1f FPS)".cstring, (1000.0f / igGetIO().Framerate).cfloat, (igGetIO().Framerate).cfloat)
      igSeparatorText(ICON_FA_WRENCH & " Icon font test ")
      igText(ICON_FA_TRASH_CAN & " Trash")
      igText(ICON_FA_MAGNIFYING_GLASS_PLUS &
        " " & ICON_FA_POWER_OFF &
        " " & ICON_FA_MICROPHONE &
        " " & ICON_FA_MICROCHIP &
        " " & ICON_FA_VOLUME_HIGH &
        " " & ICON_FA_SCISSORS &
        " " & ICON_FA_SCREWDRIVER_WRENCH &
        " " & ICON_FA_BLOG)

    # show further samll window
    if showAnotherWindow:
      igBegin("imgui Another Window", addr showAnotherWindow, 0)
      igText("Hello from imgui")
      if igButton("Close me", ImVec2(x: 0.0f, y: 0.0f)):
        showAnotherWindow = false
      igEnd()

    # Show image load window
    if igBegin("Image load test", nil, 0):
      defer: igEnd()
      # Load image
      let
        size = ImVec2(x: textureWidth.cfloat, y: textureHeight.cfloat)
        uv0 = Imvec2(x: 0, y: 0)
        uv1 = Imvec2(x: 1, y: 1)
        tint_col = ImVec4(x: 1, y: 1, z: 1, w: 1)
        border_col = ImVec4(x: 0, y: 0, z: 0, w: 0)
      igSetNextWindowSize(size,ImGui_CondAlways.ImGuiCond)
      igImage(cast[pointer](textureId), size, uv0, uv1, tint_col, border_col);

    # render
    igRender()
    glClearColor(clearColor.elm.x, clearColor.elm.y, clearColor.elm.z, clearColor.elm.w)
    glClear(GL_COLOR_BUFFER_BIT)
    ImGui_ImplOpenGL3_RenderDrawData(igGetDrawData())

    if 0 != (pio.ConfigFlags and ImGui_ConfigFlags_ViewportsEnable.cint):
      var backup_current_window = glfwGetCurrentContext()
      igUpdatePlatformWindows()
      igRenderPlatformWindowsDefault(nil, nil)
      backup_current_window.makeContextCurrent()

    hWin.swapBuffers()
    if not showFirstWindow and not showDemoWindow and not showAnotherWindow:
      hwin.setWindowShouldClose(true) # End program

#------
# main
#------
main()
