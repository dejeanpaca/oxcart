{
   oxuwinPlatformClipboard, windows platform clipboard functionality
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuwinPlatformClipboard;

INTERFACE

   USES
      uStd,
      {ox}
      oxuPlatform, oxuPlatforms, oxuWindow,
      oxuPlatformClipboard,
      oxuWindowsPlatform, oxuWindowsOS,

      {windows}
      windows;

TYPE

   { oxwinTPlatformClipboardComponent }

   oxwinTPlatformClipboardComponent = object(oxTPlatformClipboardComponent)
      procedure Clear(); virtual;

      function ContentType(): oxTClipboardContentType; virtual;
      function GetString(): StdString; virtual;
      function StoreString(const what: StdString): boolean; virtual;
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

{ oxwinTPlatformClipboardComponent }

procedure oxwinTPlatformClipboardComponent.Clear();
begin
   windows.EmptyClipboard();
end;

function oxwinTPlatformClipboardComponent.ContentType(): oxTClipboardContentType;
begin
   if(not windows.OpenClipboard(winosTWindow(oxWindow.Current).wd.h)) then
      exit(OX_CLIPBOARD_TYPE_NONE);

   Result := OX_CLIPBOARD_TYPE_NONE;

   if(windows.IsClipboardFormatAvailable(CF_UNICODETEXT)) then
      Result := OX_CLIPBOARD_TYPE_STRING
   else if(windows.IsClipboardFormatAvailable(CF_TEXT)) then
      Result := OX_CLIPBOARD_TYPE_STRING;

   windows.CloseClipboard();
end;

function oxwinTPlatformClipboardComponent.GetString(): StdString;
var
   hglb: windows.HGLOBAL;
   lptstr: windows.LPTSTR;
   unistr: PWideChar;

begin
   if(not windows.OpenClipboard(winosTWindow(oxWindow.Current).wd.h)) then
      exit('');

   Result := '';

   if(windows.IsClipboardFormatAvailable(CF_UNICODETEXT)) then begin
      hglb := windows.GetClipboardData(CF_UNICODETEXT);
      unistr := windows.GlobalLock(hglb);

      if(unistr <> nil) then begin
         Result := UTF8Encode(WideCharToString(unistr));
         windows.GlobalUnlock(hglb);
      end;
   end else if(windows.IsClipboardFormatAvailable(CF_TEXT)) then begin
      hglb := windows.GetClipboardData(CF_TEXT);
      lptstr := windows.GlobalLock(hglb);

      if(lptstr <> nil) then begin
         Result := lptstr;
         windows.GlobalUnlock(hglb);
      end else
         Result := '';
   end;

   windows.CloseClipboard();
end;

function oxwinTPlatformClipboardComponent.StoreString(const what: StdString): boolean;
var
   len,
   size: loopint;
   uni: UnicodeString;
   pdata: PWCHAR;
   hglb: windows.HGLOBAL;

begin
   if(not windows.OpenClipboard(winosTWindow(oxWindow.Current).wd.h)) then
      exit(false);

   Result := false;

   windows.EmptyClipboard();

   if(what <> '') then begin
      uni := UTF8Decode(what);

      len := Length(uni);
      size := (len + 1) * SizeOf(WCHAR);

      hglb := GlobalAlloc(0, size);

      if(hglb <> 0) then begin
         pdata := windows.GlobalLock(hglb);

         if(pdata <> nil) then begin
            move(uni[1], pdata^, size);
            pdata[len] := #0;

            GlobalUnlock(hglb);
            SetClipboardData(CF_UNICODETEXT, hglb);
            Result := true;
         end;
      end;
   end;

   windows.CloseClipboard();
end;

INITIALIZATION
   oxwinPlatformClipboardComponent.Create();
   oxPlatforms.OnComponent.Add('win.clipboard', @init);

END.
