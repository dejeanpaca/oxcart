{
   uUnix
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uUnix;

INTERFACE

   USES
      unix, baseunix;

TYPE
   {a read/write fd pipe descriptor}
   unxTPipe = array[0..1] of cint;

function unxFpread(fd: cint; buf: pchar; nbytes: TSize): TSsize; external name 'FPC_SYSC_READ';
function unxFpWrite(fd : cInt; buf: pChar; nbytes: TSize): TSsize;  external name 'FPC_SYSC_WRITE';

{helper method to more easily initialize a pipe (via FpPipe)}
function unxFpPipe(out pipe: unxTPipe): cint;

IMPLEMENTATION

function unxFpPipe(out pipe: unxTPipe): cint;
begin
   pipe[0] := 0;
   pipe[1] := 0;

   Result := FpPipe(pipe);
end;

END.
