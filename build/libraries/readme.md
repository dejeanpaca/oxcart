# Libraries

This document describes all about 3rd party libraries used by oX, where they were obtained and how to build them, as well as versions used.

## Versions

(Update if libraries change)

- Freetype: 2.8.0
- zlib: 1.2.5
- OpenAL Soft: 1.18.1

## Locations

- precompiled vorbis libraries obtained from [rarewares](http://www.rarewares.org/ogg-libraries.php#vorbislibs-aotuv)

## Freetype

Version used: 2.8.0

Instructions to build with VS at the time

Built with Visual Studio 2017

SSE instructions enabled
Enabled Whole Program Optimization
Multi-threaded (/MT)
Favor fast code
Platform toolset: Visual Studio 2017 - Windows XP (v141_xp)
For x64: Visual Studio 2017 (v141)
Windows SDK Version: 8.1

Change project to console and dll (instead of static lib)
Change ftoption.h for DLL building like this
[stackoverflow example](https://stackoverflow.com/questions/6207176/compiling-freetype-to-dll-as-opposed-to-static-library)
