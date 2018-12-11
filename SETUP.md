# oX engine

## Setup

You will need Free Pascal 3.0.4 and Lazarus 1.8.4 or newer. `lazbuild` should be in your PATH.

- To setup the workspace, run the `setup` script (cmd or sh) in `setup/`. Or build `setup.lpi` with lazarus.
- You can pass symbols to the setup scripts/tool via the `-d SYMBOL` parameters if you want to deploy for a different kind of environment. Such as `-d X11` to build for X11 (needed by e.g. Vulkan 3rd party libraries, as ox assumes X11 by default).
- To rebuild the third party libraries, if you need a different environment, you can run the `thirdparty` tool in setup. It also accepts symbols like `setup`.
- You'll also need to declare a `OX_ASSET_PATH` environment variable that tells where the assets are by default. It should point to the `oX` folder within the working copy of this repo. That's where the engine will try to load default assets from.
- The `ox editor` is used to manage and build ox projects, and is in `oX/oxed/`.
