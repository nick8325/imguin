import std/[strutils]
import sdl2

import imguin/[glad/gl,nimsdl2_opengl]
import imguin/lang/imgui_ja_gryph_ranges

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

#------
# main
#------
proc main() =
  discard sdl2.init(INIT_EVERYTHING)
  discard sdl2.glSetAttribute(SDL_GL_CONTEXT_FLAGS, 0)
  discard sdl2.glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE)
  discard sdl2.glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3)
  discard sdl2.glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3)

  discard sdl2.setHint("SDL_RENDER_DRIVER", "opengl")
  discard sdl2.glSetAttribute(SDL_GL_DEPTH_SIZE, 24)
  discard sdl2.glSetAttribute(SDL_GL_STENCIL_SIZE, 8)
  discard sdl2.glSetAttribute(SDL_GL_DOUBLEBUFFER, 1)

  # Basic IME support. App needs to call 'SDL_SetHint(SDL_HINT_IME_SHOW_UI, "1");'
  # before SDL_CreateWindow()!.
  discard sdl2.setHint("SDL_IME_SHOW_UI", "1") # SDL2: must be v2.0.18 or later

  var current: DisplayMode
  discard sdl2.getCurrentDisplayMode(0, current)

  var flags:cuint
  if TransparentViewport:
    flags = SDL_WINDOW_HIDDEN or SDL_WINDOW_OPENGL or SDL_WINDOW_RESIZABLE
  else:
    flags = SDL_WINDOW_SHOWN or SDL_WINDOW_OPENGL or SDL_WINDOW_RESIZABLE

  var window = sdl2.createWindow( "Hello", 30, 30, 1024, 800, flags)
  if isNil window:
    echo "Fail to create window: ", sdl2.getError()
    quit -1
  defer:sdl2.destroyWindow(window)

  var gl_context = glCreateContext(window)
  defer:sdl2.glDeleteContext(gl_context)

  discard glSetSwapInterval(1)

  if not gladLoadGL(glGetProcAddress):
    #echo "opengl version: " & glGetString(GL_VERSION)
    quit "Error initialising OpenGL"

  # setup imgui
  igCreateContext(nil)
  defer: igDestroyContext(nil)

  var pio = igGetIO()
  if fDocking:
    pio.ConfigFlags = pio.ConfigFlags or ImGui_ConfigFlags_DockingEnable.cint
    if fViewport:
      pio.ConfigFlags = pio.ConfigFlags or ImGui_ConfigFlags_ViewportsEnable.cint
      pio.ConfigViewports_NoAutomerge = true

  var glsl_version: cstring = "#version 150" # OpenGL 3.2
  doAssert ImGui_ImplSdl2_InitForOpenGL(cast[ptr SdlWindow](window) , addr glsl_version)
  defer: ImGui_ImplSDL2_Shutdown()

  doAssert ImGui_ImplOpenGL3_Init(glsl_version)
  defer: ImGui_ImplOpenGL3_Shutdown()

  #igStyleColorsDark(nil)
  igStyleColorsClassic(nil)

  var
    showDemoWindow = true
    showFirstWindow = true
    showAnotherWindow = false
    fval = 0.5f
    counter = 0
    xQuit: bool
    sBuf = newString(200)
  var clearColor:ccolor
  if TransparentViewport:
    clearColor = ccolor(elm:(x:0f, y:0f, z:0f, w:0.0f)) # Transparent
  else:
    clearColor = ccolor(elm:(x:0.25f, y:0.65f, z:0.85f, w:1.0f))

  # Add multibyte font
  #discard setupFonts()

  #-----------
  # Main loop
  #-----------
  while not xQuit:
    var event: Event
    while sdl2.pollevent(event):
      ImGui_ImplSDL2_ProcessEvent(cast[ptr SdlEvent](addr event))
      if event.kind == QuitEvent:
        xQuit = true
      if event.kind == WINDOWEVENT and event.window.event ==
        WINDOWEVENT_CLOSE: #and
        #event.window.windowID == sdl2.getWindowID(window):
        xQuit = true

    # start imgui frame
    ImGui_ImplOpenGL3_NewFrame()
    ImGui_ImplSdl2_NewFrame()
    igNewFrame()

    if showDemoWindow:
      igShowDemoWindow(addr showDemoWindow)

    #-----------------
    # showFirstWindow
    #-----------------
    if showFirstWindow:
      igBegin("Nim: Dear ImGui test with Futhark", showFirstWindow.addr, 0)
      defer: igEnd()
      var ver: SDL_VERSION
      sdl2.getVersion(ver)
      var s = "SDL2 v$#.$#.$#" % [$ver.major.int,$ver.minor.int,$ver.patch.int]
      igText(s.cstring)
      s = "OpenGL v" & ($cast[cstring](glGetString(GL_VERSION))).split[0]
      igText(s.cstring)

      igInputTextWithHint("InputText" ,"Input text here" ,sBuf)
      igCheckbox("Demo window", addr showDemoWindow)
      igCheckbox("Another window", addr showAnotherWindow)
      igSliderFloat("Float", addr fval, 0.0f, 1.5f, "%.3f", 0)
      igColorEdit3("clear color", clearColor.array3, ImGuiColorEditFlags_None.ImGuiColorEditFlags)

      if igButton("Button", ImVec2(x: 0.0f, y: 0.0f)):
        inc counter
      igSameLine(0.0f, -1.0f)
      igText("counter = %d", counter)
      igText("Application average %.3f ms/frame (%.1f FPS)",
             1000.0f / pio.Framerate.float, pio.Framerate)
      
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

    #-------------------
    # showAnotherWindow
    #-------------------
    if showAnotherWindow:
      igBegin("imgui Another Window", addr showAnotherWindow, 0)
      igText("Hello from imgui")
      if igButton("Close me", ImVec2(x: 0.0f, y: 0.0f)):
        showAnotherWindow = false
      igEnd()

    #--------
    # render
    #--------
    igRender()
    discard sdl2.glMakeCurrent(window, gl_context)
    glViewport(0, 0, (pio.DisplaySize.x).GLsizei, (pio.DisplaySize.y).GLsizei)
    glClearColor(clearColor.elm.x, clearColor.elm.y, clearColor.elm.z, clearColor.elm.w)
    glClear(GL_COLOR_BUFFER_BIT)
    ImGui_ImplOpenGL3_RenderDrawData(igGetDrawData())

    if 0 != (pio.ConfigFlags and ImGui_ConfigFlags_ViewportsEnable.cint):
      var backup_current_window = sdl2.glGetCurrentWindow()
      var backup_current_context = sdl2.glGetCurrentContext()
      igUpdatePlatformWindows()
      igRenderPlatformWindowsDefault(nil, nil)
      discard sdl2.glmakeCurrent(backup_current_window,backup_current_context)

    sdl2.glSwapWindow(window)
    if not showFirstWindow and not showDemoWindow and not showAnotherWindow:
      xQuit = true

  sdl2.quit()

#------
# main
#------
main()
