{
   oxuShaderFile, oX shader file management
   Copyright (C) 2010. Dejan Boras

   Started On:    16.04.2010.
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

   oxTShaderFileRW = class(oxTFileRW)
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

procedure init();
begin
   oxfShader := oxTShaderFileRW.Create();
end;

procedure deinit();
begin
   FreeObject(oxfShader);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   ox.Init.Add(initRoutines, 'shader_file', @init, @deinit);

END.
