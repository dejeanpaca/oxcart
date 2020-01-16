{
   oxuMaterialFile, material file support
   Copyright (C) 2010. Dejan Boras

   Started On:    14.08.2010.
}

{$INCLUDE oxdefines.inc}
UNIT oxuMaterialFile;

INTERFACE

   USES
      uStd, uFile,
      {oX}
      uOX, oxuRunRoutines,
      oxuFile, oxuMaterial;

TYPE

   { oxTMaterialData }

   oxTMaterialFileOptions = record
      Material: oxTMaterial;
   end;

   { oxTMaterialFile }

   oxTMaterialFile = object(oxTFileRW)
      class procedure Init(out options: oxTMaterialFileOptions); static;

      function Read(const name: string): oxTMaterial;
      function Read(var f: TFile; const fn: string = '.mat'): oxTMaterial;
   end;

VAR
   oxfMaterial: oxTMaterialFile;

IMPLEMENTATION

{ oxTMaterialFile }

class procedure oxTMaterialFile.Init(out options: oxTMaterialFileOptions);
begin
   ZeroOut(options, SizeOf(options));
end;

function oxTMaterialFile.Read(const name: string): oxTMaterial;
var
   options: oxTMaterialFileOptions;

begin
   Init(options);

   inherited Read(name, @options);

   Result := options.Material;
end;

function oxTMaterialFile.Read(var f: TFile; const fn: string): oxTMaterial;
var
   options: oxTMaterialFileOptions;

begin
   Init(options);

   inherited Read(f, fn, @options);

   Result := options.Material;
end;

INITIALIZATION
   oxfMaterial.Create();

END.
