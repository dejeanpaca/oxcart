# Third party units

Third party units go here. They're usually prebuilt using the 3rdparty tool into the units/3rdparty directory.

## Sources

Sources are listed here in the following form

- Source of the project (github or other link)
  - Listed as git/source link and target directory (expected to be in the directory with this exact name)

- dglOpenGL <https://github.com/SaschaWillems/dglOpenGL>
  - <https://github.com/SaschaWillems/dglOpenGL.git> `dglOpenGL/`
- Vulkan <https://github.com/BeRo1985/pasvulkan>
  - <https://github.com/BeRo1985/pasvulkan.git> `vulkan/`
- bgrabitmap <https://github.com/bgrabitmap/bgrabitmap>
  - <https://github.com/bgrabitmap/bgrabitmap.git> `bgrabitmap/`
- openal has been acquired from the Free Pascal sources
  - We needed to be able to compile for `x64` and prebuilt does not come with lazarus install
- DirectX <https://github.com/CMCHTPC/DelphiDX12>
  - We require the `Units` directory from the repository only which you can put into the `dx/` directory
  - <https://github.com/CMCHTPC/DelphiDX12.git> `dx/`

## Modifications

The sources may have some minimal modifications to silence warnings and hints, otherwise they're as close to original sources as possible.
