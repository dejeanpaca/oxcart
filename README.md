# oX engine

`oX` engine, also called the `oxcart` engine. Started in 2007 and went nowhere slowly. Based on the Free Pascal language/compiler.

This is still a major `WORK IN PROGRESS` and may go nowhere, as it is purely a hobby project. I may give up on this altogether. One can never know. A lot of the code may not make sense, or may be outdated (like much of the android stuff).

![oX engine screenshot](documentation/screenshot.png "oX screenshot")

## Setup

Look into `setup.md` to learn how to setup and build the engine.

## Free Pascal & Lazarus

- We require FPC 3.2.2 and Lazarus 2.2.0. Older versions may work but are not supported.
- The engine will try to find and use the FPC/Lazarus you have installed, if it is in the default location (e.g. C:\lazarus). The editor (OXED)) should use the same FPC for building projects as the version it was built with.
- You can further configure what fpc/lazarus you use via the build configuration (look in the `build/documentation` directory).

## Units

The units folder contains the extended run-time library.

## 3rdparty

Contains the source for third party libraries used by the project.

## License

   Licensed under a modified LGPL license. Similar to how `Free Pascal` is licensed. See the `COPYING.modifiedLGPL.txt` file for more information.
