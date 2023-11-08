# oX engine

`oX` engine, also called the `oxcart` engine. Started in 2007 and went nowhere slowly. Based on the Free Pascal language/compiler.

The engine went through several names in its history, and originally it was called `orcinus-x`, evolved into `orcinusX`, and remained shorthand as `oX` and the original repo was called `oxcart`. As in the `OXCART` project which produced the A-12 and SR-71 spy planes.

This is still a major `WORK IN PROGRESS` and may go nowhere, as it is purely a hobby project. I may give up on this altogether. One can never know. A lot of the code may not make sense, or may be outdated (like much of the android stuff).

## Setup

You will need Free Pascal 3.0.4 and Lazarus 1.8.4 or newer. `lazbuild` should be in your PATH.

- To setup the workspace, run the deploy script in `setup/deploy` with instantfpc. You can run the script directly under unix (includes a shebang for instanfpc).
- You can pass symbols to the deploy tool via the `-d SYMBOL` parameters if you want to deploy for a different kind of environment. Such as `-d X11` to build for X11 (needed by e.g. Vulkan 3rd party libraries).
- To rebuild the third party libraries, if you need a different environment, you can run the `thirdparty` tool in setup. It also accepts symbols like `deploy`.

## Units

The units folder contains the extended run-time library.

## 3rdparty

Contains the source for third party libraries used by the project.

## License

   Licensed under a modified LGPL license. Similar to how `Free Pascal` is licensed. See the `COPYING.modifiedLGPL.txt` file for more information.
