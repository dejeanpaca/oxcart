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
      oxuFile, oxuMaterial;

TYPE

   { oxTMaterialData }

   oxTMaterialFileOptions = record
      Material: oxTMaterial;
   end;

   { oxTMaterialFile }

   oxTMaterialFile = class(oxTFileRW)
      class procedure Init(out options: oxTMaterialFileOptions); static;

      function Load(const name: string): oxTMaterial;
      function Load(var f: TFile; const fn: string = '.mat'): oxTMaterial;
   end;

VAR
   oxfMaterial: oxTMaterialFile;

IMPLEMENTATION

{ oxTMaterialFile }

class procedure oxTMaterialFile.Init(out options: oxTMaterialFileOptions);
begin
   ZeroOut(options, SizeOf(options));
end;

function oxTMaterialFile.Load(const name: string): oxTMaterial;
var
   options: oxTMaterialFileOptions;

begin
   Init(options);

   inherited Load(name, @options);

   Result := options.Material;
end;

function oxTMaterialFile.Load(var f: TFile; const fn: string): oxTMaterial;
var
   options: oxTMaterialFileOptions;

begin
   Init(options);

   inherited Load(f, fn, @options);

   Result := options.Material;
end;

procedure init();
begin
   oxfMaterial := oxTMaterialFile.Create();
end;

procedure deinit();
begin
   FreeObject(oxfMaterial);
end;

INITIALIZATION

   ox.Init.Add('material_file', @init, @deinit);

END.
