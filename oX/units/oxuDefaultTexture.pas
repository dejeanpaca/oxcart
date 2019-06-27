{
   oxuDefaultTexture, default textue

   This file is part of oX engine. See copyright information in COPYRIGHT.md
   Copyright (C) 2017. Dejan Boras

   Started On:    10.09.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuDefaultTexture;

INTERFACE

   USES
      uLog,
      {$IFNDEF OX_LIBRARY}
      sysutils, uStd, uFile, uFiles, uTiming,
      {$ENDIF}
      {oX}
      uOX, oxuRunRoutines, oxuGlobalInstances,
      oxuTexture, oxuTextureGenerate, oxuResourcePool;

TYPE
   oxPDefaultTextureGlobal = ^oxTDefaultTextureGlobal;
   oxTDefaultTextureGlobal = record
      Load: boolean;
      Texture: oxTTexture;
   end;

VAR
   oxDefaultTexture: oxTDefaultTextureGlobal;

IMPLEMENTATION

{$IFNDEF OX_LIBRARY}
CONST
   {$INCLUDE resources/default_texture.inc}
{$ENDIF}

{$IFDEF OX_LIBRARY}
procedure loadLibrary();
var
   instance: oxPDefaultTextureGlobal;

begin
   instance := oxExternalGlobalInstances.FindInstancePtr('oxTDefaultTextureGlobal');

   if(instance <> nil) then
      oxDefaultTexture.Texture := instance^.Texture
   else
      log.w('Missing oxTDefaultTextureGlobal external instance');
end;
{$ENDIF}

{$IFNDEF OX_LIBRARY}
procedure load();
var
   errorCode: loopint = 0;
   f: TFile;
   elapsedTime: TDateTime;

begin
   if(oxDefaultTexture.Load) then begin
      elapsedTime := Time();

      fFile.Init(f);
      f.Open(@default_texture, length(default_texture));

      if(f.Error = 0) then begin
         errorCode := oxTextureGenerate.Generate('*.tga', f, oxDefaultTexture.Texture);

         {do not dispose this ever}
         oxDefaultTexture.Texture.MarkPermanent();
         oxDefaultTexture.Texture.Path := ':default_texture';
      end;

      if(f.Error <> 0) or (errorCode <> 0) then
         log.e('oX > Failed to load default texture');

      f.Close();
      f.Dispose();

      log.v('Loaded default texture (elapsed: ' + elapsedTime.ElapsedfToString() + 's)')
   end;
end;

{destroy the default texture}
procedure dispose();
begin
   oxResource.Free(oxDefaultTexture.Texture);
end;
{$ENDIF}

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   oxDefaultTexture.Load := true;

   oxGlobalInstances.Add('oxTDefaultTextureGlobal', @oxDefaultTexture);

   {$IFNDEF OX_LIBRARY}
   ox.BaseInit.Add(initRoutines, 'default_texture', @load, @dispose);
   {$ELSE}
   ox.BaseInit.Add(initRoutines, 'default_texture', @loadLibrary);
   {$ENDIF}

END.
