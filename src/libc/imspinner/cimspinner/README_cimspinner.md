## How to use imspinner in C 

1. Add imspinner.h, cimspinner\*.h, cimspinner_config.h, cimspinner\*.cpp  to your project
1. Sample C code

   ```c
   #include "cimspinner.h"
   
   ImColor genColor(int i)  {
        ImColor col;
        ImColor_HSV(&col, (float)(i) * 0.25, 0.8, 0.8, 1.0);
        return col;
   }

   int main(int, char**) {
     ...
     while (!done) {
        ...
        {
            igBegin("ImSipinner in C", NULL, 0);
            static const ImColor blue = {.Value = {.x = 0.f, .y = 0.f, .z = 1.f, .w = 1.f}};
            /* These spinners are defined in cimspinner_conifg.h by defalult. */
            SpinnerRainbowMix(     "Rmix",    16, 2, blue, 4);                  igSameLine(0.0, -1.0); // SPINNER_RAINBOWMIX
            SpinnerAng8(           "Ang",     16, 2);                           igSameLine(0.0, -1.0); // ...
            SpinnerPulsar(         "Pulsar",  16, 2);                           igSameLine(0.0, -1.0);
            SpinnerClock(          "Clock",   16, 2);                           igSameLine(0.0, -1.0);
            SpinnerAtom(           "atom",    16, 2);                           igSameLine(0.0, -1.0);
            SpinnerCamera(         "Camera",  16, 8, genColor); /* Add "-D SPINNER_CAMERA" to compilation option. */
            igEnd();
        }
        ...
     }
   }
   ```

3. See [example project](https://github.com/dinau/cimspinner_demo)
