{
   oxuPlatformClipboard, platform clipboard component
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuPlatformClipboard;

INTERFACE

   USES
      uStd,
      oxuPlatform;

TYPE
   oxTClipboardContentType = (
      OX_CLIPBOARD_TYPE_NONE,
      OX_CLIPBOARD_TYPE_STRING,
      OX_CLIPBOARD_TYPE_OTHER
   );

   oxPPlatformClipboardComponent = ^oxTPlatformClipboardComponent;

   { oxTPlatformClipboardComponent }

   oxTPlatformClipboardComponent = object
      constructor Create();

      {does the clipboard have any contents}
      function HasContents(): boolean; virtual;
      {does the clipboard have any contents}
      function ContentType(): oxTClipboardContentType; virtual;

      class function GetComponent(): oxPPlatformClipboardComponent; static;
   end;

VAR
   oxDefaultClipboardComponent: oxTPlatformClipboardComponent;
   oxPlatformClipboard: oxPPlatformClipboardComponent;

IMPLEMENTATION

{ oxTPlatformClipboardComponent }

constructor oxTPlatformClipboardComponent.Create();
begin

end;

function oxTPlatformClipboardComponent.HasContents(): boolean;
begin
   Result := false;
end;

function oxTPlatformClipboardComponent.ContentType(): oxTClipboardContentType;
begin
   Result := OX_CLIPBOARD_TYPE_NONE;
end;

class function oxTPlatformClipboardComponent.GetComponent(): oxPPlatformClipboardComponent;
begin
   if(oxPlatformClipboard <> nil) then begin
      Result := oxPPlatformClipboardComponent(oxPlatform.GetComponent('clipboard'));

      if(Result = nil) then
         Result := @oxDefaultClipboardComponent;

      Result := oxPlatformClipboard;
   end else
      Result := oxPlatformClipboard;
end;

INITIALIZATION
   oxDefaultClipboardComponent.Create();

END.
