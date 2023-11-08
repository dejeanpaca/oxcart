# dImage

Copyright (C) Dejan Boras 2009

## Introduction

Image provides functionality for loading, writing and manipulating images. It can load and write any image format for which a module(plugin) unit is written and included.

All images loaded have the same structure as loader modules need to convert an image format according to dImage specifications. This allows to manage any image in a uniform way.

## Technicals

### Description

dImage provides base functionality for loading, saving and manipulating images, but itself cannot load or write any images.

Loading and saving is done with loader or writer modules, and these can be included at compile time as units.

Image manipulation ranges from transformations (converting from one pixel format to another) to gamma corrections, and so on. These operations may be moved to an additional unit in the future, so they are included only when required.

### Basics

imgTImage record is the basic data type which stores images. It contains information on image properties (width, height, pixel count, size, origin), pixel properties (format, bit depth), palette data and image data (the pixels), as well as other information.

This record should first be initialized with the imgInit() routine, to make sure that dImage can operate correctly with that record. Using a local variable without initialization can lead to crashes (this is something you should know already).

### Loading and writing

Loading is done via the imgLoad() routine, and writing via the imgWrite() routine. These routines will figure out what image format you are  trying to load or write based on the filename extension, and will use the appropriate module.

### Image Loaders

#### Functional loaders

- BMP  (WIN32 BITMAP)
- TGA  (Truevision Targa)
- JPG  (JPEG via fpc libraries)
- WAL  (Quake 2 Textures)
- PPM  (only P6 RAW)
- PCX
- SGI RGB
- PNG (PNG loader rewritten based on code by Benjamin Rosseaux)

### Limitations

Currently, dImage supports single frame images(and modules will only load the first frame of any image type that supports multiple frames).
