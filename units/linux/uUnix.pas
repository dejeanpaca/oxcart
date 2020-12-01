{
   uUnix
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uUnix;

INTERFACE

   USES
      unix;

function unxFpread(fd: cint; buf: pchar; nbytes: TSize): TSsize; external name 'FPC_SYSC_READ';
function unxFpWrite(fd : cInt; buf: pChar; nbytes: TSize): TSsize;  external name 'FPC_SYSC_WRITE';

IMPLEMENTATION

END.
