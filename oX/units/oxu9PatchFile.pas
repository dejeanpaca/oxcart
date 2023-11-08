{
   oxu9PatchFile, 9patch texture file support
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxu9PatchFile;

INTERFACE

USES
   sysutils, uStd, uFile,
   {oX}
   uOX, oxuRunRoutines, oxuFile, oxu9Patch;

TYPE
   oxP9PatchFileData = ^oxT9PatchFileData;
   oxT9PatchFileData = record

   end;

  { oxT9PatchFileRW }

  oxT9PatchFileRW = object(oxTFileRW)
     function Read(var f: TFile; const fn: string): oxT9Patch;
     function Read(const fn: string): oxT9Patch;
  end;

VAR
   oxf9Patch: oxT9PatchFileRW;

IMPLEMENTATION

{ oxT9PatchFileRW }


function oxT9PatchFileRW.Read(var f: TFile; const fn: string): oxT9Patch;
var
   data: oxTFileRWData;

begin
   ZeroOut(data, SizeOf(data));

   inherited Read(f, fn, nil, @data);

   Result := oxT9Patch(data.Result)
end;

function oxT9PatchFileRW.Read(const fn: string): oxT9Patch;
var
   data: oxTFileRWData;

begin
   ZeroOut(data, SizeOf(data));

   inherited Read(fn, nil, @data);

   Result := oxT9Patch(data.Result)
end;

INITIALIZATION
   oxf9Patch.Create();

END.
