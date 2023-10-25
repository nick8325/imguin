import std/[strutils]
import glfw

import imguin/[glad/gl,glfw_opengl]
import imguin/lang/imgui_ja_gryph_ranges

include ../utils/setupFonts
include imguin/simple

import imnodeDemo

#------
# main
#------
proc main() =
  glfw.initialize()
  defer: glfw.terminate()

  const glsl_version = "#version 130" # GL 3.2 + GLSL 130

  var cfg = DefaultOpenglWindowConfig
  cfg.size = (w: 1024, h: 800)
  cfg.title = "Simple example"
  cfg.resizable = true
  cfg.version = glv33
  cfg.forwardCompat = true
  cfg.profile = opCoreProfile

  var window = newWindow(cfg)
  defer: window.destroy()
  if isNil window:
    echo("Failed to create window! Terminating!\n")
    glfw.terminate()
    quit -1

  glfw.makeContextCurrent(window)
  glfw.swapInterval(1) # enable vsync

  if not gladLoadGL(getProcAddress):
    quit "Error initialising OpenGL"
  # Check opengl version
  echo "OpenGL Version: $#" % [$cast[cstring](glGetString(GL_VERSION))]

  # setup ImGui
  igCreateContext(nil)
  defer: igDestroyContext(nil)

  # setup ImNodes
  imnodes_CreateContext()
  defer:imnodes_DestroyContext(nil)

  var pio = igGetIO()

  doAssert ImGui_ImplGlfw_InitForOpenGL(cast[ptr GlfwWindow](window.getHandle), true)
  defer: ImGui_ImplGlfw_Shutdown()
  doAssert ImGui_ImplOpenGL3_Init(glsl_version)
  defer: ImGui_ImplOpenGL3_Shutdown()

  var
    showDemoWindow = true
    showAnotherWindow = false
    fval = 0.5f
    counter = 0
    sBuf = newString(200)
    clearColor = ccolor(elm:(x:0.45f, y:0.55f, z:0.60f, w:1.0f))

  # Add multibytes font
  var (fExistMultbytesFonts ,sActiveFontName, sActiveFontTitle) = setupFonts()

  # ImNode demo init
  NodeEditorInitialize()
  defer: NodeEditorShutdown()

  while not glfw.shouldClose(window):
    glfw.pollEvents()

    # start imgui frame
    ImGui_ImplOpenGL3_NewFrame()
    ImGui_ImplGlfw_NewFrame()
    igNewFrame()

    if showDemoWindow:
      igShowDemoWindow(addr showDemoWindow)

    # ImNodes demo
    NodeEditorShow()

    # show a simple window that we created ourselves.
    block:
      igBegin("Nim: Dear ImGui test with Futhark", nil, 0)
      defer: igEnd()
      let (a,b,c) = glfw.version()
      let s = "GLFW v$#.$#.$#" % [$a, $b, $c]
      igText(s.cstring)
      igInputTextWithHint("InputText" ,"Input text here" ,sBuf)
      igCheckbox("Demo window", addr showDemoWindow)
      igCheckbox("Another window", addr showAnotherWindow)
      igSliderFloat("Float", addr fval, 0.0f, 1.0f, "%.3f", 0)
      igColorEdit3("Background color", clearColor.array3, ImGuiColorEditFlags_None.ImGuiColorEditFlags)

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

    # render
    igRender()
    glfw.makeContextCurrent(window)
    glViewport(0, 0, (pio.DisplaySize.x).GLsizei, (pio.DisplaySize.y).GLsizei)
    glClearColor(clearColor.elm.x, clearColor.elm.y, clearColor.elm.z, clearColor.elm.w)
    glClear(GL_COLOR_BUFFER_BIT)
    ImGui_ImplOpenGL3_RenderDrawData(igGetDrawData())
    glfw.swapBuffers(window)

main()
