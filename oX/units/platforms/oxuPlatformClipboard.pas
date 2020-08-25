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

      {clear the clipboard}
      procedure Clear(); virtual;
      {does the clipboard have any contents, and what type it is}
      function ContentType(): oxTClipboardContentType; virtual;
      {get a string from the clipboard, if any}
      function GetString(): StdString; virtual;
      {store a string to the clipboard}
      function StoreString(const what: StdString): boolean; virtual;

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

procedure oxTPlatformClipboardComponent.Clear();
begin

end;

function oxTPlatformClipboardComponent.ContentType(): oxTClipboardContentType;
begin
   Result := OX_CLIPBOARD_TYPE_NONE;
end;

function oxTPlatformClipboardComponent.GetString(): StdString;
begin
   Result := '';
end;

function oxTPlatformClipboardComponent.StoreString(const what: StdString): boolean;
begin
   Result := false;
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
