# Configuration Path

It is possible to specify configuration path, by setting a `build.config_path = PATH_TO_CONFIGURATION` line in a location.config file, in a fbuild directory in your home. This is recreated at first fpbuild start, so can just edit the line in the newly created file.

# Configuration file

Use a `build.config` file in the `build/` directory to specify configuration for the ox build system. 

- You can specify `fpc` and `lazarus` keys to indicate fpc or lazarus builds/installations. 
- Every configuration line following will be part of the `fpc` or `lazarus` configuration, until the next `fpc` or `lazarus`.

## FPC

- Example:

        fpc = 3.2.2-win32
        path = C:\FPC\3.2.2\bin\i386-win32
        platform = i386-win32

- `fpc` Name for this build platform (not related to the compiler)
- `path` Path to the fpc command (does not include the executable name)
- `platform` platform in FPC cpu-os notation, must be an FPC supported platform
- `executable` Name of the executable, if it differs from the default (such as `fpc` or `fpc.exe`)
- `config` Path to the config file you want to use with this FPC
    - OXED usually creates its own config files completely

## Lazarus

- Example:

        lazarus = 2.0.12
        path = C:\lazarus
        use_fpc = 3.2.2-win32
        config = C:\lazarus\config

- `lazarus` Name for this lazarus installation
- `path` Path to the Lazarus installation (does not include the exectuable name)
- `executable` Name of the lazarus executable, if it differs from the default (such as `lazarus` or `lazarus.exe`)
- `config` Path to the config directory for this Lazarus installation
- `use_fpc` Use the fpc install by the given name, which is configured via the section above