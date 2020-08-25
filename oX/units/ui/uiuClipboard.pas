{
   uiuClipboard, clipboard management
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuClipboard;

INTERFACE

   USES
      uStd, udvars,
      {oX}
      oxuRunRoutines,
      uiuBase, oxuUI, oxuPlatformClipboard;

TYPE

   { uiTClipboard }

   uiTClipboard = record
      {are we using the internal "clipboard"}
      Internal: boolean;

      {internal storage, if internal clipboard is used}
      Storage: record
        {string stored in the internal clipboard}
        Str: StdString;
      end;

      function HasContent(): oxTClipboardContentType;

      {clear the clipboard}
      procedure Clear();

      {retrieves a string from the clipboard, if the clipboard has a string}
      function GetString(): StdString;
      {stores a string to the clipboard}
      function StoreString(const what: StdString): boolean;
   end;

VAR
   uiClipboard: uiTClipboard;

IMPLEMENTATION

VAR
   dvInternalClipboard: TDVar;

{ uiTClipboard }

function uiTClipboard.HasContent(): oxTClipboardContentType;
var
   component: oxPPlatformClipboardComponent;

begin
   Result := OX_CLIPBOARD_TYPE_NONE;

   if(not Internal) then begin
      component := oxTPlatformClipboardComponent.GetComponent();

      Result := component^.ContentType();
   end else begin
      if(Storage.Str <> '') then
         exit(OX_CLIPBOARD_TYPE_STRING);
   end;
end;

procedure uiTClipboard.Clear();
var
   component: oxPPlatformClipboardComponent;

begin
   if(not Internal) then begin
      component := oxTPlatformClipboardComponent.GetComponent();

      component^.Clear();
   end else begin
      Storage.Str := '';
   end;
end;

function uiTClipboard.GetString(): StdString;
var
   component: oxPPlatformClipboardComponent;

begin
   Result := '';

   if(not Internal) then begin
      component := oxTPlatformClipboardComponent.GetComponent();

      if(component^.ContentType() = OX_CLIPBOARD_TYPE_STRING) then
         exit(component^.GetString());
   end else begin
      Result := Storage.Str;
   end;
end;

function uiTClipboard.StoreString(const what: StdString): boolean;
var
   component: oxPPlatformClipboardComponent;

begin
   Result := false;

   if(not Internal) then begin
      component := oxTPlatformClipboardComponent.GetComponent();

      Result := component^.StoreString(what);
   end else begin
      Storage.Str := what;
   end;
end;

procedure init();
var
   component: oxPPlatformClipboardComponent;

begin
   component := oxTPlatformClipboardComponent.GetComponent();

   {if we're using the default clipboard component, use the internal clipboard}
   if(component = @oxDefaultClipboardComponent) then begin
      uiClipboard.Internal := true;
   end;
end;

VAR
   initRoutine: oxTRunRoutine;

INITIALIZATION
   oxui.dvg.Add(dvInternalClipboard, 'internal_clipboard', dtcBOOL, @uiClipboard.Internal);
   ui.InitializationProcs.Add(initRoutine, 'clipboard', @init);

END.
