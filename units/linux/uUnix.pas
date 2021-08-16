{
   uUnix
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uUnix;

INTERFACE

   USES
      unix, baseunix;

CONST
   { read/write permission for everyone }
   MODE_FPOPEN = S_IWUSR OR S_IRUSR OR
                S_IWGRP OR S_IRGRP OR
                S_IWOTH OR S_IROTH;

TYPE
   {a read/write fd pipe descriptor}
   unxTPipe = array[0..1] of cint;

function unxFpOpen(path: RawByteString; flags: cInt; Mode: TMode): cInt;
function unxFpread(fd: cint; buf: pchar; nbytes: TSize): TSsize; external name 'FPC_SYSC_READ';
function unxFpWrite(fd: cInt; buf: pChar; nbytes: TSize): TSsize;  external name 'FPC_SYSC_WRITE';

{helper method to more easily initialize a pipe (via FpPipe)}
function unxFpPipe(out pipe: unxTPipe): cint;

IMPLEMENTATION

function unxFpOpen(path: RawByteString; flags: cInt; Mode: TMode): cInt;
var
   SystemPath: RawByteString;

Begin
   SystemPath:=ToSingleByteFileSystemEncodedFileName(path);
   Result := FpOpen(pchar(SystemPath), flags, Mode);
end;

function unxFpPipe(out pipe: unxTPipe): cint;
begin
   pipe[0] := 0;
   pipe[1] := 0;

   Result := FpPipe(pipe);
end;

END.
