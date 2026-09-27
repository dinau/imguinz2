//
// This code is based on the ImGuizumo section of
//   https://github.com/CedricGuillemet/ImGuizmo/blob/master/example/main.cpp,
//   with some modifications.
//

// https://github.com/CedricGuillemet/ImGuizmo
// v1.92.5 WIP
//
// The MIT License(MIT)
//
// Copyright(c) 2016-2026 Cedric Guillemet and contributors
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

const std = @import("std");
const app = @import("appimgui");
const ig = app.ig;
const ifa = app.ifa;
const gl = app.glfw;

const imguizmo = @import("imguizmo");

const MainWinWidth: i32 = 1200;
const MainWinHeight: i32 = 800;

var useWindow: bool = true;
var gizmoCount: i32 = 1;
var camDistance: f32 = 8.0;
var camYAngle: f32 = 165.0 / 180.0 * 3.14159;
var camXAngle: f32 = 32.0 / 180.0 * 3.14159;
var mCurrentGizmoOperation: c_int = imguizmo.TRANSLATE;
var mCurrentGizmoMode: c_int = imguizmo.WORLD;
var useSnap: bool = false;
var snap: [3]f32 = .{ 1.0, 1.0, 1.0 };
var bounds: [6]f32 = .{ -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 };
var boundsSnap: [3]f32 = .{ 0.1, 0.1, 0.1 };
var boundSizingSnap: bool = false;

var objectMatrix: [4][16]f32 = .{
    .{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 },
    .{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 0, 0, 1 },
    .{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 0, 2, 1 },
    .{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 2, 1 },
};

const identityMatrix: [16]f32 = .{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 };

var gizmoWindowFlagsState: c_int = 0;

fn Clampf(v: f32, mn: f32, mx: f32) f32 {
    return if (v < mn) mn else if (v > mx) mx else v;
}

fn Frustum(left: f32, right: f32, bottom: f32, top: f32, znear: f32, zfar: f32, m16: *[16]f32, rightHanded: bool) void {
    const temp = 2.0 * znear;
    const temp2 = right - left;
    const temp3 = top - bottom;
    const temp4 = zfar - znear;
    const sign: f32 = if (rightHanded) -1.0 else 1.0;
    m16[0] = temp / temp2;
    m16[1] = 0.0;
    m16[2] = 0.0;
    m16[3] = 0.0;
    m16[4] = 0.0;
    m16[5] = temp / temp3;
    m16[6] = 0.0;
    m16[7] = 0.0;
    m16[8] = (right + left) / temp2;
    m16[9] = (top + bottom) / temp3;
    m16[10] = sign * (zfar + znear) / temp4;
    m16[11] = sign;
    m16[12] = 0.0;
    m16[13] = 0.0;
    m16[14] = -(temp * zfar) / temp4;
    m16[15] = 0.0;
}

fn Perspective(fovyInDegrees: f32, aspectRatio: f32, znear: f32, zfar: f32, m16: *[16]f32, rightHanded: bool, infiniteFarPlane: bool) void {
    const ymax = znear * std.math.tan(fovyInDegrees * 3.141592 / 180.0);
    const xmax = ymax * aspectRatio;
    if (infiniteFarPlane) {
        const sign: f32 = if (rightHanded) -1.0 else 1.0;
        const temp = 2.0 * znear;
        const temp2 = 2.0 * xmax;
        const temp3 = 2.0 * ymax;
        m16[0] = temp / temp2;
        m16[1] = 0.0;
        m16[2] = 0.0;
        m16[3] = 0.0;
        m16[4] = 0.0;
        m16[5] = temp / temp3;
        m16[6] = 0.0;
        m16[7] = 0.0;
        m16[8] = 0.0;
        m16[9] = 0.0;
        m16[10] = sign;
        m16[11] = sign;
        m16[12] = 0.0;
        m16[13] = 0.0;
        // Keep the Z translation term negative for both handedness modes.
        // Using +2n in LH flips clipping orientation and appears like inverted winding.
        m16[14] = -temp;
        m16[15] = 0.0;
    } else {
        Frustum(-xmax, xmax, -ymax, ymax, znear, zfar, m16, rightHanded);
    }
}

fn Cross(a: *const [3]f32, b: *const [3]f32, r: *[3]f32) void {
    r[0] = a[1] * b[2] - a[2] * b[1];
    r[1] = a[2] * b[0] - a[0] * b[2];
    r[2] = a[0] * b[1] - a[1] * b[0];
}

fn Dot(a: *const [3]f32, b: *const [3]f32) f32 {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

fn Normalize(a: *const [3]f32, r: *[3]f32) void {
    const il = 1.0 / (std.math.sqrt(Dot(a, a)) + std.math.floatEps(f32));
    r[0] = a[0] * il;
    r[1] = a[1] * il;
    r[2] = a[2] * il;
}

fn LookAt(eye: *const [3]f32, at: *const [3]f32, up: *const [3]f32, m16: *[16]f32, rightHanded: bool) void {
    var X: [3]f32 = undefined;
    var Y: [3]f32 = undefined;
    var Z: [3]f32 = undefined;
    var tmp: [3]f32 = undefined;

    if (rightHanded) {
        tmp[0] = eye[0] - at[0];
        tmp[1] = eye[1] - at[1];
        tmp[2] = eye[2] - at[2];
    } else {
        tmp[0] = at[0] - eye[0];
        tmp[1] = at[1] - eye[1];
        tmp[2] = at[2] - eye[2];
    }
    Normalize(&tmp, &Z);
    Normalize(up, &Y);

    Cross(&Y, &Z, &tmp);
    Normalize(&tmp, &X);

    Cross(&Z, &X, &tmp);
    Normalize(&tmp, &Y);

    m16[0] = X[0];
    m16[1] = Y[0];
    m16[2] = Z[0];
    m16[3] = 0.0;
    m16[4] = X[1];
    m16[5] = Y[1];
    m16[6] = Z[1];
    m16[7] = 0.0;
    m16[8] = X[2];
    m16[9] = Y[2];
    m16[10] = Z[2];
    m16[11] = 0.0;
    m16[12] = -Dot(&X, eye);
    m16[13] = -Dot(&Y, eye);
    m16[14] = -Dot(&Z, eye);
    m16[15] = 1.0;
}

fn OrthoGraphic(l: f32, r: f32, b: f32, t: f32, zn: f32, zf: f32, m16: *[16]f32) void {
    m16[0] = 2 / (r - l);
    m16[1] = 0.0;
    m16[2] = 0.0;
    m16[3] = 0.0;
    m16[4] = 0.0;
    m16[5] = 2 / (t - b);
    m16[6] = 0.0;
    m16[7] = 0.0;
    m16[8] = 0.0;
    m16[9] = 0.0;
    m16[10] = 1.0 / (zf - zn);
    m16[11] = 0.0;
    m16[12] = (l + r) / (l - r);
    m16[13] = (t + b) / (b - t);
    m16[14] = zn / (zn - zf);
    m16[15] = 1.0;
}

fn rotationY(angle: f32, m16: *[16]f32) void {
    const c = std.math.cos(angle);
    const s = std.math.sin(angle);

    m16[0] = c;
    m16[1] = 0.0;
    m16[2] = -s;
    m16[3] = 0.0;
    m16[4] = 0.0;
    m16[5] = 1.0;
    m16[6] = 0.0;
    m16[7] = 0.0;
    m16[8] = s;
    m16[9] = 0.0;
    m16[10] = c;
    m16[11] = 0.0;
    m16[12] = 0.0;
    m16[13] = 0.0;
    m16[14] = 0.0;
    m16[15] = 1.0;
}

fn TransformStart(cameraView: *[16]f32, cameraProjection: *[16]f32, matrix: *[16]f32, rightHanded: bool) void {
    if (ig.ImGui_IsKeyPressed(ig.ImGuiKey_T)) mCurrentGizmoOperation = imguizmo.TRANSLATE;
    if (ig.ImGui_IsKeyPressed(ig.ImGuiKey_E)) mCurrentGizmoOperation = imguizmo.ROTATE;
    if (ig.ImGui_IsKeyPressed(ig.ImGuiKey_R)) mCurrentGizmoOperation = imguizmo.SCALE; // r Key

    var translateActive = (mCurrentGizmoOperation & imguizmo.TRANSLATE) != 0;
    var rotateActive = (mCurrentGizmoOperation & imguizmo.ROTATE) != 0;
    var scaleActive = (mCurrentGizmoOperation & imguizmo.SCALE) != 0;
    var boundsActive = (mCurrentGizmoOperation & imguizmo.BOUNDS) != 0;

    if (ig.ImGui_Checkbox("Translate", &translateActive))
        mCurrentGizmoOperation ^= imguizmo.TRANSLATE;
    ig.ImGui_SameLine();
    if (ig.ImGui_Checkbox("Rotate", &rotateActive))
        mCurrentGizmoOperation ^= imguizmo.ROTATE;
    ig.ImGui_SameLine();
    if (ig.ImGui_Checkbox("Scale", &scaleActive))
        mCurrentGizmoOperation ^= imguizmo.SCALE;
    ig.ImGui_SameLine();
    if (ig.ImGui_Checkbox("Bounds", &boundsActive))
        mCurrentGizmoOperation ^= imguizmo.BOUNDS;

    var matrixTranslation: [3]f32 = undefined;
    var matrixRotation: [3]f32 = undefined;
    var matrixScale: [3]f32 = undefined;
    imguizmo.ImGuizmo_DecomposeMatrixToComponents(&matrix[0], &matrixTranslation[0], &matrixRotation[0], &matrixScale[0]);
    _ = ig.ImGui_InputFloat3("Tr", &matrixTranslation);
    _ = ig.ImGui_InputFloat3("Rt", &matrixRotation);
    _ = ig.ImGui_InputFloat3("Sc", &matrixScale);
    imguizmo.ImGuizmo_RecomposeMatrixFromComponents(&matrixTranslation[0], &matrixRotation[0], &matrixScale[0], &matrix[0]);

    if ((mCurrentGizmoOperation & (imguizmo.TRANSLATE | imguizmo.ROTATE | imguizmo.SCALE)) != 0) {
        if (ig.ImGui_RadioButton("Local", mCurrentGizmoMode == imguizmo.LOCAL))
            mCurrentGizmoMode = imguizmo.LOCAL;
        ig.ImGui_SameLine();
        if (ig.ImGui_RadioButton("World", mCurrentGizmoMode == imguizmo.WORLD))
            mCurrentGizmoMode = imguizmo.WORLD;
    }

    if (ig.ImGui_IsKeyPressed(ig.ImGuiKey_S)) useSnap = !useSnap;
    _ = ig.ImGui_Checkbox("Use Snap", &useSnap);
    ig.ImGui_SameLine();
    if ((mCurrentGizmoOperation & imguizmo.TRANSLATE) != 0)
        _ = ig.ImGui_InputFloat3("Snap", &snap);
    if ((mCurrentGizmoOperation & imguizmo.ROTATE) != 0)
        _ = ig.ImGui_InputFloat("Angle Snap", &snap[0]);
    if ((mCurrentGizmoOperation & imguizmo.SCALE) != 0)
        _ = ig.ImGui_InputFloat("Scale Snap", &snap[0]);
    if ((mCurrentGizmoOperation & imguizmo.BOUNDS) != 0) {
        _ = ig.ImGui_InputFloat3("Bounds Min", @ptrCast(&bounds[0]));
        _ = ig.ImGui_InputFloat3("Bounds Max", @ptrCast(&bounds[3]));
        _ = ig.ImGui_Checkbox("Snap Bounds", &boundSizingSnap);
        if (boundSizingSnap)
            _ = ig.ImGui_InputFloat3("Bounds Snap", &boundsSnap);
    }

    const io = ig.ImGui_GetIO();
    var viewManipulateRight = io.*.DisplaySize.x;
    var viewManipulateTop: f32 = 0;
    ig.ImGui_SetNextWindowSize(.{ .x = 800, .y = 400 }, ig.ImGuiCond_FirstUseEver);
    ig.ImGui_SetNextWindowPos(.{ .x = 400, .y = 20 }, ig.ImGuiCond_FirstUseEver);
    ig.ImGui_PushStyleColorImVec4(ig.ImGuiCol_WindowBg, .{ .x = 0.35, .y = 0.3, .z = 0.3, .w = 1.0 });
    if (useWindow) {
        _ = ig.ImGui_Begin("Gizmo", null, gizmoWindowFlagsState);
        imguizmo.ImGuizmo_SetDrawlist(null);
    }
    const windowWidth = ig.ImGui_GetWindowWidth();
    const windowHeight = ig.ImGui_GetWindowHeight();

    const windowPos = ig.ImGui_GetWindowPos();

    if (!useWindow) {
        imguizmo.ImGuizmo_SetRect(0, 0, io.*.DisplaySize.x, io.*.DisplaySize.y);
    } else {
        imguizmo.ImGuizmo_SetRect(windowPos.x, windowPos.y, windowWidth, windowHeight);
    }
    viewManipulateRight = windowPos.x + windowWidth;
    viewManipulateTop = windowPos.y;

    const contentMin = ig.ImGui_GetWindowContentRegionMin();
    const contentMax = ig.ImGui_GetWindowContentRegionMax();
    const innerMin = ig.ImVec2{ .x = windowPos.x + contentMin.x, .y = windowPos.y + contentMin.y };
    const innerMax = ig.ImVec2{ .x = windowPos.x + contentMax.x, .y = windowPos.y + contentMax.y };
    gizmoWindowFlagsState = if (ig.ImGui_IsWindowHovered(0) and ig.ImGui_IsMouseHoveringRect(innerMin, innerMax))
        ig.ImGuiWindowFlags_NoMove
    else
        0;

    // Drag in empty viewport area to orbit the camera
    const ioVP = ig.ImGui_GetIO();
    const mouse_down_array = ioVP.*.MouseDown;
    const is_clicked = mouse_down_array[0];
    if (ig.ImGui_IsWindowHovered(0) and !imguizmo.ImGuizmo_IsOver_Nil() and !imguizmo.ImGuizmo_IsUsingViewManipulate() and is_clicked) {
        const handednessSign: f32 = if (rightHanded) 1.0 else -1.0;
        camYAngle += ioVP.*.MouseDelta.x * 0.01 * handednessSign;
        camXAngle += ioVP.*.MouseDelta.y * 0.01;
        camXAngle = Clampf(camXAngle, -3.14159 * 0.49, 3.14159 * 0.49);
        const eye = [3]f32{ std.math.cos(camYAngle) * std.math.cos(camXAngle) * camDistance, std.math.sin(camXAngle) * camDistance, std.math.sin(camYAngle) * std.math.cos(camXAngle) * camDistance };
        const at = [3]f32{ 0, 0, 0 };
        const up = [3]f32{ 0, 1, 0 };
        LookAt(&eye, &at, &up, cameraView, rightHanded);
    }

    imguizmo.ImGuizmo_DrawGrid(&cameraView[0], &cameraProjection[0], &identityMatrix[0], 100.0);
    imguizmo.ImGuizmo_DrawCubes(&cameraView[0], &cameraProjection[0], &objectMatrix[0][0], gizmoCount);

    _ = imguizmo.ImGuizmo_ViewManipulate_Float(&cameraView[0], camDistance, .{ .x = viewManipulateRight - 128, .y = viewManipulateTop }, .{ .x = 128, .y = 128 }, 0x10101010);
}

fn TransformEnd() void {
    if (useWindow) {
        ig.ImGui_End();
    }
    ig.ImGui_PopStyleColor();
}

fn EditTransform(cameraView: *[16]f32, cameraProjection: *[16]f32, matrix: *[16]f32) void {
    const io = ig.ImGui_GetIO();
    const windowWidth = ig.ImGui_GetWindowWidth();
    const windowHeight = ig.ImGui_GetWindowHeight();
    if (!useWindow) {
        imguizmo.ImGuizmo_SetRect(0, 0, io.*.DisplaySize.x, io.*.DisplaySize.y);
    } else {
        const windowPos = ig.ImGui_GetWindowPos();
        imguizmo.ImGuizmo_SetRect(windowPos.x, windowPos.y, windowWidth, windowHeight);
    }
    const hasBounds = (mCurrentGizmoOperation & imguizmo.BOUNDS) != 0;
    _ = imguizmo.ImGuizmo_Manipulate(
        &cameraView[0],
        &cameraProjection[0],
        @intCast(mCurrentGizmoOperation),
        @intCast(mCurrentGizmoMode),
        &matrix[0],
        null,
        if (useSnap) &snap[0] else null,
        if (hasBounds) &bounds[0] else null,
        if (hasBounds and boundSizingSnap) &boundsSnap[0] else null,
    );
}

//-----------
// gui_main()
//-----------
pub fn gui_main(window: *app.Window) !void {
    _ = app.stf.setupFonts(null);

    var lastUsing: i32 = 0;

    var cameraView: [16]f32 = .{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 };
    var cameraProjection: [16]f32 = undefined;

    // build a procedural texture. Copy/pasted and adapted from https://rosettacode.org/wiki/Plasma_effect#Graphics_version
    var procTexture: c_uint = undefined;
    gl.glGenTextures(1, @ptrCast(&procTexture));
    gl.glBindTexture(gl.GL_TEXTURE_2D, procTexture);

    const allocator = std.heap.page_allocator;
    const tempBitmap = try allocator.alloc(u32, 256 * 256);
    defer allocator.free(tempBitmap);

    var index: usize = 0;
    var y: i32 = 0;
    while (y < 256) : (y += 1) {
        var x: i32 = 0;
        while (x < 256) : (x += 1) {
            const xf: f32 = @floatFromInt(x);
            const yf: f32 = @floatFromInt(y);
            const dx = xf + 0.5;
            const dy = yf + 0.5;
            const dv = std.math.sin(xf * 0.02) + std.math.sin(0.03 * (xf + yf)) + std.math.sin(std.math.sqrt(0.4 * (dx * dx + dy * dy) + 1.0));

            const r: u32 = @intFromFloat(255 * @abs(std.math.sin(dv * 3.141592)));
            const g: u32 = @intFromFloat(255 * @abs(std.math.sin(dv * 3.141592 + 2.0 * 3.141592 / 3.0)));
            const b: u32 = @intFromFloat(255 * @abs(std.math.sin(dv * 3.141592 + 4.0 * 3.141592 / 3.0)));

            tempBitmap[index] = @as(u32, 0xFF000000) + (r << 16) + (g << 8) + b;
            index += 1;
        }
    }
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, 256, 256, 0, @intCast(gl.GL_RGBA), gl.GL_UNSIGNED_BYTE, tempBitmap.ptr);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR);

    // Camera projection
    var isPerspective: bool = true;
    var fov: f32 = 27.0;
    var viewWidth: f32 = 10.0; // for orthographic
    var infiniteFarPlane: bool = false;
    var handedness: i32 = 0; // 0 = right-handed, 1 = left-handed

    var firstFrame: bool = true;
    var prevHandedness: i32 = handedness;

    //---------------
    // main loop GUI
    //---------------
    while (!window.shouldClose()) {
        window.pollEvents();
        window.frame();
        {
            const io = ig.ImGui_GetIO();
            var rightHanded = (handedness == 0);
            if (isPerspective) {
                Perspective(fov, io.*.DisplaySize.x / io.*.DisplaySize.y, 0.1, 100.0, &cameraProjection, rightHanded, infiniteFarPlane);
            } else {
                const viewHeight = viewWidth * io.*.DisplaySize.y / io.*.DisplaySize.x;
                const zn: f32 = if (rightHanded) 1000.0 else -1000.0;
                const zf: f32 = if (rightHanded) -1000.0 else 1000.0;
                OrthoGraphic(-viewWidth, viewWidth, -viewHeight, viewHeight, zn, zf, &cameraProjection);
            }
            imguizmo.ImGuizmo_SetOrthographic(!isPerspective);
            imguizmo.ImGuizmo_BeginFrame();

            // create a window and insert the inspector
            ig.ImGui_SetNextWindowPos(.{ .x = 10, .y = 10 }, ig.ImGuiCond_FirstUseEver);
            ig.ImGui_SetNextWindowSize(.{ .x = 320, .y = 500 }, ig.ImGuiCond_FirstUseEver);
            _ = ig.ImGui_Begin("Editor", null, 0);
            if (ig.ImGui_RadioButton("Full view", !useWindow)) useWindow = false;
            ig.ImGui_SameLine();
            if (ig.ImGui_RadioButton("Window", useWindow)) useWindow = true;

            ig.ImGui_Text("Camera");
            var viewDirty = false;
            if (ig.ImGui_RadioButton("Perspective", isPerspective)) isPerspective = true;
            ig.ImGui_SameLine();
            if (ig.ImGui_RadioButton("Orthographic", !isPerspective)) isPerspective = false;
            if (isPerspective) {
                _ = ig.ImGui_SliderFloat("Fov", &fov, 20.0, 110.0);
            } else {
                _ = ig.ImGui_SliderFloat("Ortho width", &viewWidth, 1.0, 20.0);
            }
            viewDirty = ig.ImGui_SliderFloat("Distance", &camDistance, 1.0, 10.0) or viewDirty;
            if (ig.ImGui_IsItemHovered(0) and io.*.MouseWheel != 0.0) {
                camDistance = Clampf(camDistance - io.*.MouseWheel * 0.5, 1.0, 10.0);
                viewDirty = true;
            }
            viewDirty = ig.ImGui_Combo("Handedness", &handedness, "Right-handed\x00Left-handed\x00") or viewDirty;
            // Recompute rightHanded immediately after combo so the LookAt below uses the new value
            rightHanded = (handedness == 0);
            if (isPerspective) {
                viewDirty = ig.ImGui_Checkbox("Infinite far plane", &infiniteFarPlane) or viewDirty;
            }
            _ = ig.ImGui_SliderInt("Gizmo count", &gizmoCount, 1, 4);

            if (viewDirty or firstFrame) {
                const eye = [3]f32{ std.math.cos(camYAngle) * std.math.cos(camXAngle) * camDistance, std.math.sin(camXAngle) * camDistance, std.math.sin(camYAngle) * std.math.cos(camXAngle) * camDistance };
                const at = [3]f32{ 0, 0, 0 };
                const up = [3]f32{ 0, 1, 0 };
                LookAt(&eye, &at, &up, &cameraView, rightHanded);
                firstFrame = false;
                prevHandedness = handedness;
            }
            // Also refresh next frame so projection catches up when handedness changed
            if (prevHandedness != handedness) firstFrame = true;
            prevHandedness = handedness;

            ig.ImGui_Text("X: %f Y: %f", @as(f64, io.*.MousePos.x), @as(f64, io.*.MousePos.y));
            if (imguizmo.ImGuizmo_IsUsing()) {
                ig.ImGui_Text("Using gizmo");
            } else {
                ig.ImGui_Text(if (imguizmo.ImGuizmo_IsOver_Nil()) "Over gizmo" else "");
                ig.ImGui_SameLine();
                ig.ImGui_Text(if (imguizmo.ImGuizmo_IsOver_OPERATION(imguizmo.TRANSLATE)) "Over translate gizmo" else "");
                ig.ImGui_SameLine();
                ig.ImGui_Text(if (imguizmo.ImGuizmo_IsOver_OPERATION(imguizmo.ROTATE)) "Over rotate gizmo" else "");
                ig.ImGui_SameLine();
                ig.ImGui_Text(if (imguizmo.ImGuizmo_IsOver_OPERATION(imguizmo.SCALE)) "Over scale gizmo" else "");
            }
            ig.ImGui_Separator();

            TransformStart(&cameraView, &cameraProjection, &objectMatrix[@intCast(lastUsing)], rightHanded);
            var matId: i32 = 0;
            while (matId < gizmoCount) : (matId += 1) {
                imguizmo.ImGuizmo_PushID_Int(matId);

                EditTransform(&cameraView, &cameraProjection, &objectMatrix[@intCast(matId)]);
                if (imguizmo.ImGuizmo_IsUsing()) {
                    lastUsing = matId;
                }
                imguizmo.ImGuizmo_PopID();
            }
            TransformEnd();
            ig.ImGui_End();
        }

        //------------------
        // Show info window
        //------------------
        window.showInfoWindow(); // See:  ../../src/libzig/appimgui/appImGui.zig

        // render
        window.render();
    } // end while loop
}

//--------
// main()
//--------
pub fn main() !void {
    var window = try app.Window.createImGui(
        1300,
        600,
        "ImGuizmo demo in Zig",
        .{},
    );
    defer window.destroyImGui();

    _ = window.setTheme(.classic); // Theme: dark, classic, light, microsoft
    //
    try gui_main(&window);
}
