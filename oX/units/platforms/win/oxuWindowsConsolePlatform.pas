{
   oxuWindowsConsolePlatform, Windows OS console specific functionality
   Copyright (c) 2018. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuWindowsConsolePlatform;

INTERFACE

   USES
      uStd, uiuWindowTypes, uiuTypes,
      {oX}
      {%H-}oxuPlatforms, oxuConsolePlatform,
      oxuWindowsOS;

TYPE
   { oxTWindowsConsolePlatform }

   oxTWindowsConsolePlatform = class(oxTConsolePlatform)
      constructor Create(); override;

      function MessageBox(wParent: uiTWindow; const Title, Say: StdString;
         Style: uiTMessageBoxStyle; Buttons: longword): longword; override;
   end;

IMPLEMENTATION

{ oxTWindowsConsolePlatform }

constructor oxTWindowsConsolePlatform.Create();
begin
   inherited;
end;

function oxTWindowsConsolePlatform.MessageBox(wParent: uiTWindow; const Title,
   Say: StdString; Style: uiTMessageBoxStyle; Buttons: longword): longword;
begin
   Result := winos.MessageBox(wParent, Title, Say, Style, Buttons);
end;

INITIALIZATION
   { platform }
   oxPlatforms.Register(oxTWindowsConsolePlatform);

END.
