# uFile

Document Information
- Started on:    14.12.2007.
- Last Update:   12.03.2011.

## Introduction

   uFile is an abstraction layer for basic file operations.

It was created out of the need to have greater functionality than what is provided by standard files or file streams.

## Technicals

### General

Aside from normal file operations, it allows for logical files stored within other files and files stored in memory. Additional file handlers can be made to handle files of different types.

Additional functionality includes buffering, which can help with I/O performance since a lot of system calls are avoided.

### File Types

uFile by default provides support for following file types: normal files, memory files and subfiles.

- Normal files are standard files, with buffering provided.
- Subfiles are files on top of other files, which use a subregion of a file. Subfiles can be used with any other kind of file, since no direct access to the file is made.
- Memory files are stored in memory and usually have a fixed maximum size. However, they are really fast.

### Buffering

uFile provides buffering, which is useful for platforms which do not posess native buffering of files(e.g. MS-DOS without smartdrv). Buffering is recommended even in cases where the OS provides buffering as each system call made has it's own overhead. Try writing 1 GiB of bytes one byte at a time on any OS, and you'll see what I mean. In cases where small reads or writes are made, buffering can make a whole lot of diference (in the "1 GiB byte by byte" example it can mean over 100x difference).

Buffering cannot be set or performed for files stored in memory, as there is no point in doing this.
