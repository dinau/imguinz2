#include <d3d11.h>

#include "dcimgui.h"
#include "dcimgui_impl_dx11.h"
#include "dcimgui_impl_win32.h"

#include "IconsFontAwesome6.h"
#include "loadicon.h"
#include "setupFonts.h"

// Data
static ID3D11Device *g_pd3dDevice = NULL;
static ID3D11DeviceContext *g_pd3dDeviceContext = NULL;
static IDXGISwapChain *g_pSwapChain = NULL;
static bool g_SwapChainOccluded = false;
static UINT g_ResizeWidth = 0, g_ResizeHeight = 0;
static ID3D11RenderTargetView *g_mainRenderTargetView = NULL;

// Forward declarations of helper functions
bool CreateDeviceD3D(HWND hWnd);
void CleanupDeviceD3D();
void CreateRenderTarget();
void CleanupRenderTarget();
LRESULT WINAPI WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

// Main code
int main(int argc, char **argv) {
  (void)argc;
  (void)argv;

  // Make process DPI aware and obtain main monitor scale
  cImGui_ImplWin32_EnableDpiAwareness();
  POINT pt = {0, 0};
  float main_scale = cImGui_ImplWin32_GetDpiScaleForMonitor(
      MonitorFromPoint(pt, MONITOR_DEFAULTTOPRIMARY));

  // Create application window
  WNDCLASSEXW wc = {sizeof(wc),
                    CS_CLASSDC,
                    WndProc,
                    0L,
                    0L,
                    GetModuleHandle(NULL),
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    L"ImGui Example",
                    NULL};
  RegisterClassExW(&wc);
  HWND hwnd =
      CreateWindowW(wc.lpszClassName, L"Dear ImGui DirectX11 Example",
                    WS_OVERLAPPEDWINDOW, 100, 100, (int)(1280 * main_scale),
                    (int)(800 * main_scale), NULL, NULL, wc.hInstance, NULL);

  // Initialize Direct3D
  if (!CreateDeviceD3D(hwnd)) {
    CleanupDeviceD3D();
    UnregisterClassW(wc.lpszClassName, wc.hInstance);
    return 1;
  }

  // Show the window
  ShowWindow(hwnd, SW_SHOWDEFAULT);
  UpdateWindow(hwnd);

  // Setup Dear ImGui context
  ImGui_CreateContext(NULL);
  ImGuiIO *io = ImGui_GetIO();
  io->ConfigFlags |=
      ImGuiConfigFlags_NavEnableKeyboard; // Enable Keyboard Controls
  io->ConfigFlags |=
      ImGuiConfigFlags_NavEnableGamepad;             // Enable Gamepad Controls
  io->ConfigFlags |= ImGuiConfigFlags_DockingEnable; // Enable Docking
  io->ConfigFlags |= ImGuiConfigFlags_ViewportsEnable; // Enable Multi-Viewport

  // Setup Dear ImGui style
  ImGui_StyleColorsDark(NULL);

  // Setup scaling
  ImGuiStyle *style = ImGui_GetStyle();
  ImGuiStyle_ScaleAllSizes(style, main_scale);
  style->FontScaleDpi = main_scale;
  io->ConfigDpiScaleFonts = true;
  io->ConfigDpiScaleViewports = true;

  if (io->ConfigFlags & ImGuiConfigFlags_ViewportsEnable) {
    style->WindowRounding = 0.0f;
    style->Colors[ImGuiCol_WindowBg].w = 1.0f;
  }

  // Setup Platform/Renderer backends
  cImGui_ImplWin32_Init((void *)hwnd);
  cImGui_ImplDX11_Init(g_pd3dDevice, g_pd3dDeviceContext);

  // Our state
  bool show_demo_window = true;
  bool show_another_window = false;
  ImVec4 clear_color = {0.45f, 0.55f, 0.60f, 1.00f};

  setupFonts(NULL); // NULL: Setup default CJK fonts and Icon fonts

  int showWindowDelay = 2; // TODO: Avoid flickering of window at startup

  // Main loop
  bool done = false;
  while (!done) {
    // Poll and handle messages (inputs, window resize, etc.)
    MSG msg;
    while (PeekMessage(&msg, NULL, 0U, 0U, PM_REMOVE)) {
      TranslateMessage(&msg);
      DispatchMessage(&msg);
      if (msg.message == WM_QUIT) {
        done = true;
    }
    }
    if (done) {
      break;
    }

    // Handle window being minimized or screen locked
    if (g_SwapChainOccluded &&
        g_pSwapChain->lpVtbl->Present(g_pSwapChain, 0, DXGI_PRESENT_TEST) ==
            DXGI_STATUS_OCCLUDED) {
      Sleep(10);
      continue;
    }
    g_SwapChainOccluded = false;

    // Handle window resize
    if (g_ResizeWidth != 0 && g_ResizeHeight != 0) {
      CleanupRenderTarget();
      g_pSwapChain->lpVtbl->ResizeBuffers(g_pSwapChain, 0, g_ResizeWidth,
                                          g_ResizeHeight, DXGI_FORMAT_UNKNOWN,
                                          0);
      g_ResizeWidth = g_ResizeHeight = 0;
      CreateRenderTarget();
    }

    // Start the Dear ImGui frame
    cImGui_ImplDX11_NewFrame();
    cImGui_ImplWin32_NewFrame();
    ImGui_NewFrame();

    // 1. Show the big demo window
    if (show_demo_window) {
      ImGui_ShowDemoWindow(&show_demo_window);
    }

    // 2. Show a simple window that we create ourselves
    {
      static float f = 0.0f;
      static int counter = 0;

      ImGui_Begin("Hello, world! " ICON_FA_CAT, NULL, 0);

      ImGui_Text("This is some useful text.");
      ImGui_Checkbox("Demo Window", &show_demo_window);
      ImGui_Checkbox("Another Window", &show_another_window);

      ImGui_SliderFloatEx("float", &f, 0.0f, 1.0f, "%.3f", 0);
      ImGui_ColorEdit3("Background color", (float *)&clear_color, 0);

      if (ImGui_Button("Button")) {
        counter++;
      }
      ImGui_SameLine();
      ImGui_Text("counter = %d", counter);

      ImGui_Text("Application average %.3f ms/frame (%.1f FPS)",
             1000.0f / io->Framerate, io->Framerate);
      ImGui_End();
    }

    // 3. Show another simple window
    if (show_another_window) {
      ImGui_Begin("Another Window", &show_another_window, 0);
      ImGui_Text("Hello from another window!");
      if (ImGui_Button("Close Me")) {
        show_another_window = false;
      }
      ImGui_End();
    }

    // Rendering
    ImGui_Render();
    const float clear_color_with_alpha[4] = {
        clear_color.x * clear_color.w, clear_color.y * clear_color.w,
        clear_color.z * clear_color.w, clear_color.w};
    g_pd3dDeviceContext->lpVtbl->OMSetRenderTargets(
        g_pd3dDeviceContext, 1, &g_mainRenderTargetView, NULL);
    g_pd3dDeviceContext->lpVtbl->ClearRenderTargetView(
        g_pd3dDeviceContext, g_mainRenderTargetView, clear_color_with_alpha);
    cImGui_ImplDX11_RenderDrawData(ImGui_GetDrawData());

    // Update and Render additional Platform Windows
    if (io->ConfigFlags & ImGuiConfigFlags_ViewportsEnable) {
      ImGui_UpdatePlatformWindows();
      ImGui_RenderPlatformWindowsDefault();
    }

    HRESULT hr = g_pSwapChain->lpVtbl->Present(g_pSwapChain, 1, 0);
    g_SwapChainOccluded = (hr == DXGI_STATUS_OCCLUDED);

    if (showWindowDelay >= 0)
      showWindowDelay--;
    if (showWindowDelay == 0) {
      ShowWindow(hwnd, SW_SHOWDEFAULT);
      UpdateWindow(hwnd);
  }
  }

  // Cleanup
  cImGui_ImplDX11_Shutdown();
  cImGui_ImplWin32_Shutdown();
  ImGui_DestroyContext(NULL);

  CleanupDeviceD3D();
  DestroyWindow(hwnd);
  UnregisterClassW(wc.lpszClassName, wc.hInstance);

  return 0;
}

// Helper functions
bool CreateDeviceD3D(HWND hWnd) {
  // Setup swap chain
  DXGI_SWAP_CHAIN_DESC sd;
  memset(&sd, 0, sizeof(sd));
  sd.BufferCount = 2;
  sd.BufferDesc.Width = 0;
  sd.BufferDesc.Height = 0;
  sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
  sd.BufferDesc.RefreshRate.Numerator = 60;
  sd.BufferDesc.RefreshRate.Denominator = 1;
  sd.Flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;
  sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
  sd.OutputWindow = hWnd;
  sd.SampleDesc.Count = 1;
  sd.SampleDesc.Quality = 0;
  sd.Windowed = TRUE;
  sd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;

  UINT createDeviceFlags = 0;
  // createDeviceFlags |= D3D11_CREATE_DEVICE_DEBUG;

  D3D_FEATURE_LEVEL featureLevel;
  const D3D_FEATURE_LEVEL featureLevelArray[2] = {
      D3D_FEATURE_LEVEL_11_0,
      D3D_FEATURE_LEVEL_10_0,
  };

  HRESULT res = D3D11CreateDeviceAndSwapChain(
      NULL, D3D_DRIVER_TYPE_HARDWARE, NULL, createDeviceFlags,
      featureLevelArray, 2, D3D11_SDK_VERSION, &sd, &g_pSwapChain,
      &g_pd3dDevice, &featureLevel, &g_pd3dDeviceContext);

  // Try high-performance WARP software driver if hardware is not available
  if (res == DXGI_ERROR_UNSUPPORTED) {
    res = D3D11CreateDeviceAndSwapChain(
        NULL, D3D_DRIVER_TYPE_WARP, NULL, createDeviceFlags, featureLevelArray,
        2, D3D11_SDK_VERSION, &sd, &g_pSwapChain, &g_pd3dDevice, &featureLevel,
        &g_pd3dDeviceContext);
  }

  if (res != S_OK) {
    return false;
  }

  // Disable DXGI's default Alt+Enter fullscreen behavior
  IDXGIFactory *pSwapChainFactory;
  if (SUCCEEDED(g_pSwapChain->lpVtbl->GetParent(g_pSwapChain, &IID_IDXGIFactory,
                                                (void **)&pSwapChainFactory))) {
    pSwapChainFactory->lpVtbl->MakeWindowAssociation(pSwapChainFactory, hWnd,
                                                     DXGI_MWA_NO_ALT_ENTER);
    pSwapChainFactory->lpVtbl->Release(pSwapChainFactory);
  }

  CreateRenderTarget();
  return true;
}

void CleanupDeviceD3D() {
  CleanupRenderTarget();
  if (g_pSwapChain) {
    g_pSwapChain->lpVtbl->Release(g_pSwapChain);
    g_pSwapChain = NULL;
  }
  if (g_pd3dDeviceContext) {
    g_pd3dDeviceContext->lpVtbl->Release(g_pd3dDeviceContext);
    g_pd3dDeviceContext = NULL;
  }
  if (g_pd3dDevice) {
    g_pd3dDevice->lpVtbl->Release(g_pd3dDevice);
    g_pd3dDevice = NULL;
  }
}

void CreateRenderTarget() {
  ID3D11Texture2D *pBackBuffer;
  g_pSwapChain->lpVtbl->GetBuffer(g_pSwapChain, 0, &IID_ID3D11Texture2D,
                                  (void **)&pBackBuffer);
  g_pd3dDevice->lpVtbl->CreateRenderTargetView(g_pd3dDevice,
                                               (ID3D11Resource *)pBackBuffer,
                                               NULL, &g_mainRenderTargetView);
  pBackBuffer->lpVtbl->Release(pBackBuffer);
}

void CleanupRenderTarget() {
  if (g_mainRenderTargetView) {
    g_mainRenderTargetView->lpVtbl->Release(g_mainRenderTargetView);
    g_mainRenderTargetView = NULL;
  }
}

// Forward declare message handler from imgui_impl_win32.cpp
extern LRESULT cImGui_ImplWin32_WndProcHandler(HWND hWnd, UINT msg,
                                              WPARAM wParam, LPARAM lParam);

// Win32 message handler
LRESULT WINAPI WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
  if (cImGui_ImplWin32_WndProcHandler(hWnd, msg, wParam, lParam)) {
    return true;
  }

  switch (msg) {
  case WM_SIZE:
    if (wParam == SIZE_MINIMIZED) {
      return 0;
    }
    g_ResizeWidth = (UINT)LOWORD(lParam);
    g_ResizeHeight = (UINT)HIWORD(lParam);
    return 0;
  case WM_SYSCOMMAND:
    if ((wParam & 0xfff0) == SC_KEYMENU) { // Disable ALT application menu
      return 0;
    }
    break;
  case WM_DESTROY:
    PostQuitMessage(0);
    return 0;
  }
  return DefWindowProcW(hWnd, msg, wParam, lParam);
}
