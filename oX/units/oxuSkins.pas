{
   oxuSkins, skin management
   Copyright (C) 2011. Dejan Boras

   Started On:    14.11.2009.
}

{$INCLUDE oxdefines.inc}
UNIT oxuSkins;

INTERFACE

   USES
      uStd,
      {oX}
      oxuResourcePool, oxuMaterial;

TYPE
   oxPSkin = ^oxTSkin;

   { oxTSkin }

   oxTSkin = record
      Name: string; {skin name}

      {materials}
      Materials: oxTMaterials;

      class procedure Init(out skin: oxTSkin); static;

      function AddMaterial(): oxTMaterial;
      {set a material to the specified slot}
      procedure SetIntoSlot(slot: loopint; mat: oxTMaterial);

      procedure Dispose();
   end;

   oxPSkinGroup = ^oxTSkinList;

   { oxTSkinList }

   oxTSkinList = specialize TSimpleList<oxTSkin>;

   { oxTSkinListHelper }

   oxTSkinListHelper = record helper for oxTskinList
      function Find(const name: string): oxPSkin;
   end;

VAR
   oxcZeroSkin: oxTSkin;

IMPLEMENTATION

{ oxTSkinListHelper }

function oxTSkinListHelper.Find(const name: string): oxPSkin;
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      if(List[i].Name = name) then
         exit(@List[i]);
   end;

   Result := nil;
end;

{ oxTSkin }

class procedure oxTSkin.Init(out skin: oxTSkin);
begin
   ZeroOut(skin, SizeOf(skin));
end;

function oxTSkin.AddMaterial(): oxTMaterial;
var
   mat: oxTMaterial;

begin
   mat := oxMaterial.Instance();

   Materials.Add(mat);
   Result := mat;
end;

procedure oxTSkin.SetIntoSlot(slot: loopint; mat: oxTMaterial);
begin
   if(Materials.n < slot + 1) then
      Materials.Allocate(slot + 1);

   Materials[slot] := mat;
end;

procedure oxTSkin.Dispose();
var
   i: loopint;

begin
   for i := 0 to Materials.n - 1 do begin
      oxResource.Destroy(Materials.List[i]);
   end;

   Materials.Dispose();
end;

END.
