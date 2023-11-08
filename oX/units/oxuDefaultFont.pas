{
   oxuDefaultFont, default font for ox
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuDefaultFont;

INTERFACE

   USES
      uLog,
      {$IFNDEF OX_LIBRARY}
      sysutils, uStd, uError, uFile, uFiles, uTiming,
      {$ENDIF}
      {oX}
      uOX, oxuRunRoutines, oxuGlobalInstances,
      oxuTFD, oxuFont, oxuResourcePool;

TYPE
   oxPDefaultFontGlobal = ^oxTDefaultFontGlobal;
   oxTDefaultFontGlobal = record
      Load: boolean;
      Font: oxTFont;
   end;

VAR
   oxDefaultFont: oxTDefaultFontGlobal;

IMPLEMENTATION

{$IFNDEF OX_LIBRARY}
CONST
   {$INCLUDE resources/default_font.inc}
VAR
   tfd: oxTTFD;
{$ENDIF}

{$IFDEF OX_LIBRARY}
procedure loadLibrary();
var
   instance: oxPDefaultFontGlobal;

begin
   instance := oxExternalGlobalInstances^.FindInstancePtr('oxTDefaultFontGlobal');

   if(instance <> nil) then begin
      oxDefaultFont.Font := instance^.Font;

      {set as default font in any case}
      if(oxf.Default = nil) then
         oxf.SetDefault(oxDefaultFont.Font);
   end;
end;
{$ENDIF}

{$IFNDEF OX_LIBRARY}
procedure load();
var
   errorCode: longint;
   f: TFile;
   elapsedTIme: TDateTime;

begin
   if(oxDefaultFont.Load) then begin
      elapsedTime := Time();

      fFile.Init(f);
      f.Open(@default_font, length(default_font));

      if(f.Error = 0) then begin
         errorCode := oxFont.Load(oxDefaultFont.Font, tfd, tfd.TextureName, f);

         if(errorCode = 0) then begin
            oxDefaultFont.Font.Texture.Path := 'default';
            oxDefaultFont.Font.Texture.Name := 'default';
            oxDefaultFont.Font.Texture.MarkPermanent();
         end;

         {set as default font in any case}
         if(oxf.Default = nil) then
            oxf.SetDefault(oxDefaultFont.Font);
      end else
         errorCode:= eIO;

      f.Close();
      f.Dispose();

      if(errorCode = 0) then
         log.v('Loaded default font (elapsed: ' + elapsedTime.ElapsedfToString() + 's)')
      else
         log.e('oX > Failed to load default font ' + GetErrorCodeString(errorCode));
   end;
end;

{destroy the default font}
procedure dispose();
begin
   if(oxDefaultFont.Font <> nil) then
      oxResource.Free(oxDefaultFont.Font.Texture);

   FreeObject(oxDefaultFont.Font);
end;
{$ENDIF}

INITIALIZATION
   oxDefaultFont.Load := true;

   oxGlobalInstances.Add('oxTDefaultFontGlobal', @oxDefaultFont);

   {$IFNDEF OX_LIBRARY}
   ox.BaseInit.Add('default_font', @load, @dispose);

   oxTFD.Init(tfd);

   tfd.Width := 8;
   tfd.Height := 8;

   tfd.Base := 0;
   tfd.Chars := 256;
   tfd.CPLine := 16;
   tfd.Lines := 16;
   {we only need the extension to load with the proper loader}
   tfd.TextureName := 'default_font.tga';
   {$ELSE}
   ox.BaseInit.Add('default_font', @loadLibrary);
   {$ENDIF}

END.
