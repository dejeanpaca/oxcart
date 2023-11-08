{
   oxuShaderFile, oX shader file management
   Copyright (C) 2010. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuShaderFile;

INTERFACE

   USES
      sysutils, uStd, uFile,
      {oX}
      uOX, oxuRunRoutines, oxuFile, oxuShader;

TYPE
   oxPShaderFileData = ^oxTShaderFileData;
   oxTShaderFileData = record

   end;

   { oxTShaderFileRW }

   oxTShaderFileRW = object(oxTFileRW)
      function Read(var f: TFile; const fn: string): oxTShader;
      function Read(const fn: string): oxTShader;
   end;

VAR
   oxfShader: oxTShaderFileRW;

IMPLEMENTATION

{ oxTShaderFileRW }


function oxTShaderFileRW.Read(var f: TFile; const fn: string): oxTShader;
var
   data: oxTFileRWData;

begin
   ZeroOut(data, SizeOf(data));

   inherited Read(f, fn, nil, @data);

   Result := oxTShader(data.Result)
end;

function oxTShaderFileRW.Read(const fn: string): oxTShader;
var
   data: oxTFileRWData;

begin
   ZeroOut(data, SizeOf(data));

   inherited Read(fn, nil, @data);

   Result := oxTShader(data.Result)
end;

INITIALIZATION
   oxfShader.Create();

END.
