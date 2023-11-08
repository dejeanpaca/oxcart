# yPak

## Introduction

yPak is a simple file packaging format, and a set of utilities to deal with them. It's goal is to put many files into one package (archive), which can then be read by a program.
   
It stores files linearly, and has a lookup table for all the files. The lookup table contains filenames (fixed strings), offsets in the ypk file and the size of the files.

## File Format

### Header

`[YPAK ID][Endian = word][Version = word][Files - longint]`\
\
`YPAK ID  - 'YPAK'`\
`Endian   - $0000 for little-endian and $FFFF for big-endian`\
`Version  - $0100 for current version of YPAK`\
`Files    - File count`

### File Table

The file table consists of an array of file entries. The file count is specified in the header. Each entry has an offset(absolute file position) file size and file name. Since a longint is used for offset and size, maximum file size of a YPAK file is ~2 GiB.

An entry in the table looks like this:\
`[ Offs - longint ][ Size - longint ][ Filename - string[63] ]`

The filenames are shortstrings and are limited to 63 characters (64 bytes total). This is a total of 72 bytes per entry.

### Files

Files are simply copied, and appended one after another. There is no specific order for files.