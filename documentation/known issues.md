# Known Issues

## Wayland pointer warping

- Under `wayland`, pointer warping (centering) does not work for the X11 platform. This is a bug with the wayland X11 emulation layer. It will be resolved when wayland fixes the bug, or a wayland platform backend is made for oX.
- In OXED, you can set oxed.pointer_center_enable dvar to false to allow camera manipulation without centering.
