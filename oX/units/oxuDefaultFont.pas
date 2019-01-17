{
   oxuDefaultFont, default font for ox
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT oxuDefaultFont;

INTERFACE

   USES
      uStd, uLog, uFile, uFiles,
      {oX}
      uOX, oxuTFD, oxuFont, oxuResourcePool;

TYPE
   oxTDefaultFontGlobal = record
      Load: boolean;
      Font: oxTFont;
   end;

VAR
   oxDefaultFont: oxTDefaultFontGlobal;

IMPLEMENTATION

CONST
   {$INCLUDE resources/default_font.inc}
VAR
   tfd: oxTTFD;

procedure load();
var
   errcode: longint;
   f: TFile;

begin
   if(oxDefaultFont.Load) then begin
      fFile.Init(f);
      f.Open(@default_font, length(default_font));

      if(f.error = 0) then begin
         errcode := oxFont.Load(oxDefaultFont.Font, tfd, tfd.TextureName, f);

         if(errcode = 0) then begin
            oxDefaultFont.Font.Texture.Path := 'default';
            oxDefaultFont.Font.Texture.Name := 'default';
            oxDefaultFont.Font.Texture.MarkPermanent();
         end else
            log.e('oX > Failed to load default font');

         {set as default font in any case}
         if(oxf.Default = nil) then
            oxf.SetDefault(oxDefaultFont.Font);
      end else
         log.e('oX > Failed to load default font image file');

      f.Close();
      f.Dispose();
   end;
end;

{destroy the default font}
procedure dispose();
begin
   oxResource.Free(oxDefaultFont.Font.Texture);
   FreeObject(oxDefaultFont.Font);
end;

INITIALIZATION
   oxDefaultFont.Load := true;
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

END.

