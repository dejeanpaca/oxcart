{
   kcRemapCodes, key remap codes for console input
   Copyright (C) 2008. Dejan Boras

   These are remap codes console programs using the Keyboard, and
   appConsoleInput routines. So far there is only one set of remap codes for
   all platforms.
}

   appkcRemapCodes: array[0..255] of word = (
000,
{$INCLUDE appkcUniRemapCodes.inc}
);
