{
   oxuwinPlatformClipboard, windows platform clipboard functionality
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuwinPlatformClipboard;

INTERFACE

   USES
      uStd,
      oxuWindowsPlatform, oxuPlatform, oxuPlatforms,
      oxuPlatformClipboard;

TYPE
   oxwinTPlatformClipboardComponent = object(oxTPlatformClipboardComponent)
   end;


VAR
   oxwinPlatformClipboardComponent: oxwinTPlatformClipboardComponent;

IMPLEMENTATION

function componentReturn(): TObject;
begin
   Result := TObject(@oxwinPlatformClipboardComponent);
end;

procedure init();
var
   p: oxTPlatform;

begin
   p := oxPlatforms.Find(oxTWindowsPlatform);

   p.Components.RegisterComponent('clipboard', @componentReturn);
end;

INITIALIZATION
   oxwinPlatformClipboardComponent.Create();
   oxPlatforms.OnComponent.Add('win.clipboard', @init);

END.
