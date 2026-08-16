<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [ImGuinz2](#imguinz2)
  - [Zig fetch](#zig-fetch)
  - [Try Wasm demo in your browser](#try-wasm-demo-in-your-browser)
- [Frontends and Backends](#frontends-and-backends)
  - [Prerequisites](#prerequisites)
  - [Available libraries list at this moment](#available-libraries-list-at-this-moment)
  - [Build and run](#build-and-run)
  - [Examples screen shots](#examples-screen-shots)
    - [zig_imknobs](#zig_imknobs)
    - [zig_imtoggle](#zig_imtoggle)
    - [zig_imspinner](#zig_imspinner)
    - [Raylib example](#raylib-example)
    - [zig_imfiledialog](#zig_imfiledialog)
    - [zig_imgui_markdown](#zig_imgui_markdown)
    - [zig_iconfontviewer](#zig_iconfontviewer)
    - [zig_imcolortextedit](#zig_imcolortextedit)
    - [zig_imguizmo](#zig_imguizmo)
    - [zig_imnodes](#zig_imnodes)
    - [zig_implot / zig_implot3d](#zig_implot--zig_implot3d)
    - [Image load / save (OpenGL, SDL3, SDL3GPU)](#image-load--save-opengl-sdl3-sdl3gpu)
    - [zig_glfw_opengl3](#zig_glfw_opengl3)
    - [zig_imgui_zoomable_image](#zig_imgui_zoomable_image)
    - [zig_webgl_wasm](#zig_webgl_wasm)
    - [zig_wgpu_wasm](#zig_wgpu_wasm)
  - [Hiding console window](#hiding-console-window)
  - [SDL libraries](#sdl-libraries)
  - [My tools version](#my-tools-version)
  - [Similar project ImGui / CImGui](#similar-project-imgui--cimgui)
  - [SDL game tutorial Platfromer](#sdl-game-tutorial-platfromer)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

### ImGuinz2

This project aims to simply and easily build [Dear ImGui](https://github.com/ocornut/imgui) examples with **C** and **Zig** using [Dear_Bindings](https://github.com/dearimgui/dear_bindings) as first step  
and one can use many other libaries and examples with less external dependencies (except Raylib library).

[DearBindings](https://github.com/dearimgui/dear_bindings): v1.92.9b-docking  
[Dear ImGui](https://github.com/ocornut/imgui): 1.92.9b dock (2026/08)

#### Zig fetch

---

Use zig-0.16.0

1. Zig fetch `imguinz2`

   ```sh
   mkdir myapp
   cd myapp
   zig init
   
   zig fetch --save git+https://github.com/dinau/imguinz2
   ```

1. Add dependencies to `build.zig`  
Please insert the following lines above `b.installArtifact(exe);`.

   ```zig
   const imguinz2 = b.dependency("imguinz2", .{});
   const dependencies = .{
       "appimgui",      // Simple app framework
       "imspinner",     // ImSpinner
       "imknobs",       // ImKnobs
       "imtoggle",      // ImToggle
    // "another_lib",
   };
   inline for (dependencies) |dep_name| {
       const dep = imguinz2.builder.dependency(dep_name, .{
           .target = target, 
           .optimize = optimize, 
       });
       exe.root_module.addImport(dep_name, dep.module(dep_name));
   }
   //exe.subsystem = .Windows; // Hide console window
   ```

   You can set `dependencies` (additional libraries), see [imguinz2/build.zig.zon](https://github.com/dinau/imguinz2/blob/main/build.zig.zon)

   ```zig
   "appimgui"     <- Simple app framework for GLFW and OpenGL backend
   "imspinner"    <- ImSpinner
   "imguizmo"     <- ImGuizmo
   "imknobs"      <- ImKnobs 
   "imnodes"      <- ImNodes
   "implot"       <- ImPlots
   "implot3d"     <- ImPlot3D
   "imtoggle"     <- ImToggle
   "rlimgui"      <- rlImgui
   ... snip  ...
   ```

1. Edit src/main.zig

   ```zig
   const app = @import("appimgui");
   const ig = app.ig;
   const spinner = @import("imspinner"); // ImSpinner
   const knobs = @import("imknobs"); // ImKnobs
   const tgl = @import("imtoggle"); // ImToggle
   
   // gui_main()
   pub fn gui_main(window: *app.Window) void {
       var col: f32 = 1.0;
       var fspd: bool = false;
       var speed: f32 = 2.0;
       var spn_col: spinner.ImColor = .{ .Value = .{ .x = col, .y = 1.0, .z = 1.0, .w = 1.0 } };
       while (!window.shouldClose()) { // main loop
           window.pollEvents();
           window.frame(); // Start ImGui frame
   
           ig.ImGui_ShowDemoWindow(null); // Show ImGui demo window
   
           ig.ImGui_SetNextWindowSize(.{ .x = 0.0, .y = 0.0 }, 0); // Fit window size depending on the size of the widgets
           _ = ig.ImGui_Begin("Demo", null, 0); // Show demo window
           spinner.SpinnerAtomEx("atom", 16, 2, spn_col, speed, 3);
           ig.ImGui_SameLine();
           _ = tgl.Toggle("Speed", &fspd, .{ .x = 0.0, .y = 0.0 });
           if (fspd) speed = 6.0 else speed = 2.0;
           if (knobs.IgKnobFloat("Color", &col, 0.0, 1.0, 0.05, "%.2f", knobs.IgKnobVariant_Stepped, 0, 0, 10, -1, -1)) {
               spn_col.Value.x = col;
           }
           ig.ImGui_End();
   
           window.render(); // render
       } // end while loop
   }
   
   pub fn main() !void {
       var window = try app.Window.createImGui(1024, 900, "ImGui window in Zig", .{});
       defer window.destroyImGui();
   
       _ = app.setTheme(.dark); // Theme: dark, classic, light, microsoft
   
       gui_main(&window); // GUI main proc
   }
   ```

1. Build and run
  
   ```sh
   pwd
   myapp

   zig build run     # or zig build --release=fast

   ```
   
   ![myapp.png](https://github.com/dinau/imguinz/raw/main/img/myapp.gif)

#### Try Wasm demo in your browser

---

Click link for live demo: [Click here](https://dinau.github.io/imguin/wasm/demo/glfw_opengl3_wasm_base.html)  
![alt](https://github.com/dinau/imguin/raw/main/src/img/wasm_demo_small.gif)

See [zig_webgl_wasm](#zig_webgl_wasm) / [zig_wgpu_wasm](#zig_wgpu_wasm) examples


### Frontends and Backends  

---

| Frontends |            Backends            |
|-----------|:------------------------------:|
| GLFW3     | OpenGL3 / WASM(WebGL / WebGPU) |
| SDL3      |        OpenGL3, SDL3GPU        |
| Win32     |        DirectX 11(D3D11)       |
  
[^except_raylib]: Except Raylib examples
[^wip]: WIP

#### Prerequisites

---

- Zig Compiler 
    - [x] zig-0.16.0  
       Windows: [zig-x86_64-windows-0.16.0.zip](https://ziglang.org/download/0.16.0/zig-x86_64-windows-0.16.0.zip)  
       Linux:   [  zig-x86_64-linux-0.16.0.tar.xz](https://ziglang.org/download/0.16.0/zig-x86_64-linux-0.16.0.tar.xz)
    - [x] 0.17.0-dev.1767  [^except_raylib] (2026/08/14)

- Windows11  
   - Install MSys2/MinGW basic commands (make, rm, cp ...)

      ```sh
      pacman -S make 
      ```

- Linux OS: Debian13 Trixie / Ubuntu families

   ```sh
   sudo apt install make gcc lib{opengl-dev,gl1-mesa-dev,glfw3,glfw3-dev}
   ```
   
   - SDL3  
      [Install SDL3 library](https://github.com/dinau/sdl3_nim#for-linux-os)

#### Available libraries list at this moment

---

|     | Library                                                                  | C Wrapper                                                               | Date    |
|:---:|:-------------------------------------------------------------------------|-------------------------------------------------------------------------|:-------:|
| YES | [Dear ImGui](https://github.com/ocornut/imgui)                           | [Dear_Bindings](https://github.com/dearimgui/dear_bindings)             | 2024/06 |
| YES | [ImGui-Knobs](https://github.com/altschuler/imgui-knobs)                 | [CImGui-Knobs](libs/cimgui-knobs)                                       | 2025/07 |
| YES | [ImGuiFileDialog](https://github.com/aiekick/ImGuiFileDialog)            | [CImGuiFileDialog](https://github.com/dinau/CImGuiFileDialog)           | 2025/07 |
| YES | [ImGui_Toggle](https://github.com/cmdwtf/imgui_toggle)                   | [CimGui_Toggle](https://github.com/dinau/cimgui_toggle)                 | 2025/07 |
| YES | [ImSpinner](https://github.com/dalerank/imspinner)                       | [CImSpinner](https://github.com/dinau/cimspinner)                       | 2025/07 |
| YES | [ImGuiColorTextEdit](https://github.com/santaclose/ImGuiColorTextEdit)   | [cimCTE](https://github.com/cimgui/cimCTE)                              | 2025/08 |
| YES | [ImGuizmo](https://github.com/CedricGuillemet/ImGuizmo)                  | [CImGuizmo](https://github.com/cimgui/cimguizmo)                        | 2025/08 |
| YES | [ImNodes](https://github.com/Nelarius/imnodes)                           | [CImNodes](https://github.com/cimgui/cimnodes)                          | 2025/08 |
| YES | [ImPlot](https://github.com/epezent/implot)                              | [CImPlot](https://github.com/cimgui/cimplot)                            | 2025/08 |
| YES | [ImPlot3d](https://github.com/brenocq/implot3d)                          | [CImPlot3d](https://github.com/cimgui/cimplot3d)                        | 2025/08 |
| YES | [imgui_zoomable_image](https://github.com/danielm5/imgui_zoomable_image) | [cimgui_zoomable_image](https://github.com/dinau/cimgui_zoomable_image) | 2026/04 |
| WIP | [ImGui_Markdown](https://github.com/enkisoftware/imgui_markdown)         | [CImGui_MarkDown](https://github.com/dinau/cimgui_markdown)             | -       |
| YES | [STB](https://github.com/nothings/stb)                                   | -                                                                       |         |
| YES | [Font-Awesome](https://github.com/FortAwesome/Font-Awesome)              | -                                                                       |         |

Additional examples 
- [x] [Raylib](https://github.com/raysan5/raylib), [raylib-zig](https://github.com/raylib-zig/raylib-zig), [rlImGui](https://github.com/raylib-extras/rlImGui) (2025/11)

#### Build and run

---

```sh
git clone https://github.com/dinau/imguinz2

cd imguinz2/examples/zig_glfw_opengl3       # for example
make run       # or zig build run --release=fast 
```

#### Examples screen shots 

##### zig_imknobs

---

 [zig_imknobs](examples/zig_imknobs/src/main.zig) 

![alt](img/zig_imknobs.png)

##### zig_imtoggle

---

[zig_imtoggle](examples/zig_imtoggle/src/main.zig) 

![alt](img/zig_imtoggle.png)

##### zig_imspinner

---

[zig_imspinner](examples/zig_imspinner/src/main.zig) 

![alt](img/zig_imspinner.gif)

##### Raylib example 

---

Use zig-0.16.0 

First fetch raylib,

```sh
zig fetch --save git+https://github.com/raysan5/raylib
```

[raylib_basic](examples/zig_raylib_basic/src/main.zig)  


![alt](https://github.com/dinau/imguinz/raw/main/img/raylib_basic.gif)

[raylib_cjk](examples/zig_raylib_cjk/src/main.zig): Showing multi byte(CJK) fonts

![alt](https://github.com/dinau/imguinz/raw/main/img/raylib_cjk.gif)

[Raylib + ImGui + rlImGui](examples/zig_rlimgui_basic/src/main.zig)  

![alt](https://github.com/dinau/imguin_examples/raw/main/img/rlimgui.gif)

##### zig_imfiledialog

---

[zig_imfiledialog](examples/zig_imfiledialog/src/main.zig) 

![alt](img/zig_imfiledialog.png)

##### zig_imgui_markdown

---

- [x] Work in progress

[zig_imgui_markdown](examples/zig_imgui_markdown/src/main.zig) 

![alt](https://github.com/dinau/cimgui_markdown/raw/main/demo/img/cimgui_markdown.png)

##### zig_iconfontviewer

---

[zig_iconfontviewer](examples/zig_iconfontviewer/src/main.zig) 

- [x] Incremantal search 
- [x] Magnifing glass

![alt](img/zig_iconfontviewer.png)

##### zig_imcolortextedit

---

[zig_imcolortextedit](examples/zig_imcolortextedit/src/main.zig) 

![alt](img/zig_imcolortextedit.png)

##### zig_imguizmo

---

[zig_imguizmo](examples/zig_imguizmo/src/main.zig) 

![alt](img/zig_imguizmo.png)

##### zig_imnodes

---

[zig_imnodes](examples/zig_imnodes/src/main.zig) 

![alt](img/zig_imnodes.png)

##### zig_implot / zig_implot3d

---

[zig_implot](examples/zig_implot/src/main.zig) /  [zig_implot3d](examples/zig_implot3d/src/main.zig) 

[zig_imPlotDemo](examples/zig_imPlotDemo/src/demoAll.zig) written in Zig.

![alt](img/zig_implot3d.gif)  
![alt](img/zig_implot.png)

##### Image load / save (OpenGL, SDL3, SDL3GPU)

---

| Language |                                                                                                                    GLFW | Magnifing glass | Image load /save | Note                                                                                                      |
|:--------:|------------------------------------------------------------------------------------------------------------------------:|:---------------:|:----------------:|-----------------------------------------------------------------------------------------------------------|
|     C    |                                                             [glfw_opengl3_image_load](examples/glfw_opengl3_image_load) |        -        |         Y        |                                                                                                           |
|     C    |                                                             [glfw_opengl3_image_save](examples/glfw_opengl3_image_save) |        -        |         Y        |                                                                                                           |
|    Zig   |                                        [zig_glfw_opengl3_image_load](examples/zig_glfw_opengl3_image_load/src/main.zig) |        Y        |         Y        |                                                                                                           |
|    Zig   | [zig_sdl3_sdlgup3](examples/zig_sdl3_sdlgpu3/src/main.zig) / [zig_sdl3_opengl3](examples/zig_sdl3_opengl3/src/main.zig) |        -        |       load       | Download [SDL3.dll](https://github.com/libsdl-org/SDL/releases) on Windows and copy to zig-out/bin folder |

- [x] Image file captured will be saved in current folder.  
- [x] Image format can be selected from `JPEG / PNG / BMP / TGA`.

![alt](img/glfw_opengl3_image_load.png)

##### zig_glfw_opengl3

---

- [x] Basic example

| Language |                                                                               GLFW |                                                       SDL3 |
|:--------:|-----------------------------------------------------------------------------------:|-----------------------------------------------------------:|
|     C    | [glfw_opengl3](examples/glfw_opengl3), [glfw_opengl3_jp](examples/glfw_opengl3_jp) |                      [sdl3_opengl3](examples/sdl3_opengl3) |
|    Zig   |                         [zig_glfw_opengl3](examples/zig_glfw_opengl3/src/main.zig) | [zig_sdl3_opengl3](examples/zig_sdl3_opengl3/src/main.zig) |


![alt](img/glfw_opengl3.png) ![alt](img/glfw_opengl3_jp.png)

##### zig_imgui_zoomable_image

---

Try Wasm live demo in your browser  
Click link for live demo: [Click here](https://dinau.github.io/cimgui_zoomable_image/wasm/)  

![alt](https://github.com/dinau/cimgui_zoomable_image/raw/main/img/snapshot.png)

[^emsdk_list]: `$ emsdk list`

##### zig_webgl_wasm

---

- [Install emscripten](https://emscripten.org/docs/getting_started/downloads.html#installation-instructions-using-the-emsdk-recommended)
-  Spicefy emsdk **6.0.6**[^emsdk_list]

   ```sh
   emsdk install  6.0.6 
   emsdk activate 6.0.6
   ```

- Go to `examples/zig_webgl_wasm` folder
1. Run `emsdk_env.bat`(Windows) or `emsdk_env.sh`(Linux) in your console
   > [!IMPORTANT]

   ```sh
   emsdk_env.bat     # Run this once in every new console
   ```

1.  Build **WebGL/Wsam** example

    ```sh
    make run
    ```
    
    See ./Makefile

1. Open your brwoser at [http://localhost:8000](http://localhost:8000) and click **web** folder
1. You can build native application too

    ```sh
    make app
    ```

##### zig_wgpu_wasm

---

Same as WebGL example

```sh
emsdk_env.bat  
```

```
make run
```

This example can't build native applicaton.

#### Hiding console window

---

- Zig examples  
Open `build.zig` in each example folder and **enable** the option line as follows,

  ```zig
  ... snip ...
  exe.subsystem = .Windows;  // Hide console window
  ... snip ...
  ```

  and execute `make`.


- C examples  
Open `Makefile` in each example folder and **change** the option line as follows,

  ```Makefile
  ... snip ...
  HIDE_CONSOLE_WINDOW = true
  ... snip ...
  ```

  and execute `make`.

#### SDL libraries

---

https://github.com/libsdl-org/SDL  
https://github.com/libsdl-org/SDL/releases

#### My tools version

---

- make: GNU Make 4.4.1
- Python 3.14.3

#### Similar project ImGui / CImGui

---

| Language             |          | Project                                                                                                                                         |
| -------------------: | :---:    | :----------------------------------------------------------------:                                                                              |
| **Lua**              | Script   | [LuaJITImGui](https://github.com/dinau/luajitImGui)                                                                                             |
| **NeLua**            | Compiler | [NeLuaImGui](https://github.com/dinau/neluaImGui) / [NeLuaImGui2](https://github.com/dinau/neluaImGui2)                                         |
| **Nim**              | Compiler | [ImGuin](https://github.com/dinau/imguin), [Nimgl_test](https://github.com/dinau/nimgl_test), [Nim_implot](https://github.com/dinau/nim_implot) |
| **Python**           | Script   | [DearPyGui for 32bit WindowsOS Binary](https://github.com/dinau/DearPyGui32/tree/win32)                                                         |
| **Ruby**             | Script   | [igRuby_Examples](https://github.com/dinau/igruby_examples)                                                                                     |
| **Zig**              | Compiler | [ImGuinz](https://github.com/dinau/imguinz)     with CImGui                                                                                                |
| **Zig**, C           | Compiler | [ImGuinz2](https://github.com/dinau/imguinz2) with Dear Binindings                                                                             |


#### SDL game tutorial Platfromer

---

![ald](https://github.com/dinau/nelua-platformer/raw/main/img/platformer-nelua-sdl2.gif)


| Language             |          | SDL         | Project                                                                                                                                               |
| -------------------: | :---:    | :---:       | :----------------------------------------------------------------:                                                                                    |
| **LuaJIT**           | Script   | SDL2        | [LuaJIT-Platformer](https://github.com/dinau/luajit-platformer)
| **Nelua**            | Compiler | SDL2        | [NeLua-Platformer](https://github.com/dinau/nelua-platformer)
| **Nim**              | Compiler | SDL3 / SDL2 | [Nim-Platformer-sdl2](https://github.com/def-/nim-platformer)/ [Nim-Platformer-sdl3](https://github.com/dinau/sdl3_nim/tree/main/examples/platformer) |
| **Ruby**             | Script   | SDL3        | [Ruby-Platformer](https://github.com/dinau/ruby-platformer)                                                                                           |
  **Zig**              | Compiler | SDL3 / SDL2 | [Zig-Platformer](https://github.com/dinau/zig-platformer)                                                                                             |
