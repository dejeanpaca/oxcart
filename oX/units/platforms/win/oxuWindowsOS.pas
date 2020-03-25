{
   oxuWindowsOS, Windows OS specific functionality
   Copyright (c) 2013. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuWindowsOS;

INTERFACE

   USES
      StringUtils, uLog, Windows,
      {oX}
      oxuWindowTypes, uiuTypes, uiuWindowTypes;

TYPE
   winTFrame = record
      {resizable frame}
      wsStyle, 
      wsStyleEx,

      {non-resizable frame}
      wStyle, 
      wStyleEx: longword;
   end;

   winosTWindow = class(oxTWindow)
      wd: record
         {do not automatically create a device context}
         NoDC: boolean;

         h: HWND;
         dc: HDC;
         wStyle,
         wStyleEx: longword;

         {stored settings before going fullscreen}
         Fullscreen: record
            wStyle,
            wStyleEx: longword;
         end;

         LastError: LongWord;
      end;
   end;
  
CONST
   oxwinMemoryDCs = [OBJ_MEMDC, OBJ_METADC, OBJ_ENHMETADC];

   wincFRAME_STYLE_MAX = 1;

   wndcFrames: array[0..wincFRAME_STYLE_MAX] of winTFrame = (
      {uiwFRAME_STYLE_NORMAL}
      (
         wsStyle:    WS_DLGFRAME or WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_THICKFRAME;
         wsStyleEx:  WS_EX_WINDOWEDGE;
         wStyle:     WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU; 
         wStyleEx:   WS_EX_WINDOWEDGE
      ),

      {uiwFRAME_STYLE_NONE}
      (
         wsStyle:    WS_POPUP; 
         wsStyleEx:  WS_EX_APPWINDOW;
         wStyle:     WS_POPUP; 
         wStyleEx:   WS_EX_APPWINDOW
      )
   );
    
TYPE
   { winTWindowsOSGlobal }

   winTWindowsOSGlobal = record
      LastError: DWORD;
      LastErrorDescription: string;

      {logs and returns an error, if any}
      function LogError(const prefix: string = ''): DWORD;
      {get a string representation of a windows error code}
      class function FormatMessage(messsageID: DWORD; includeCode: boolean = true): string; static;
      {get the last error code, and log it if silent is set to false}
      function GetLastError(silent: boolean = true): DWORD;

      function MessageBox(wParent: uiTWindow; const Title, Say: string;
         Style: uiTMessageBoxStyle; Buttons: longword): longword;
   end;

VAR
   winos: winTWindowsOSGlobal;

IMPLEMENTATION

{ winTWindowsOSGlobal }

function winTWindowsOSGlobal.LogError(const prefix: string): DWORD;
begin
   LastError := windows.GetLastError();
   Result := LastError;

   if(Result <> 0) then begin
      LastErrorDescription := 'winOS > ' + prefix + ': ' + FormatMessage(Result);
      log.e(LastErrorDescription);
   end;
end;

class function winTWindowsOSGlobal.FormatMessage(messsageID: DWORD; includeCode: boolean = true): string;
var
   buf: array[0..65535] of char;

begin
   windows.FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, nil, messsageID, 0, @buf, Length(buf) - 1, nil);

   {remove newlines which are returned for some reason}
   if(includeCode) then
      Result := '(' + sf(messsageID) + ') ' + Copy(PChar(@buf[0]), 1, Length(PChar(@buf[0])))
   else
      Result := Copy(PChar(@buf[0]), 1, Length(PChar(@buf[0])));
end;

function winTWindowsOSGlobal.GetLastError(silent: boolean): DWORD;
begin
   LastError := windows.GetLastError();
   Result := LastError;

   if(Result <> 0) and (not silent) then
      log.e('winos > error: ' + FormatMessage(Result));
end;

function winTWindowsOSGlobal.MessageBox(wParent: uiTWindow;
   const Title, Say: string; Style: uiTMessageBoxStyle; Buttons: longword): longword;
var
   rslt: longword;
   uType: longword;
   wHNDL: HANDLE;

begin
   Result := uimbcNONE;

   uType := 0;
   {set the style}
   if(style = uimbsNOTIFICATION) then
      uType := uType or MB_ICONEXCLAMATION
   else if(style = uimbsQUESTION) then
      uType := uType or MB_ICONQUESTION
   else if(style = uimbsWARNING) then
      uType := uType or MB_ICONWARNING
   else if(style = uimbsCRITICAL) then
      uType := uType or MB_ICONERROR;
   {set the buttons}
   if(Buttons = uimbcOK) then
      uType := uType or MB_OK
   else if(Buttons = uimbcOK_CANCEL) then
      uType := uType or MB_OKCANCEL
   else if(Buttons = uimbcYES_NO) then
      uType := uType or MB_YESNO
   else if(Buttons = uimbcYES_NO_CANCEL) then
      uType := uType or MB_YESNOCANCEL
   else if(Buttons = uimbcRETRY_CANCEL) then
      uType := uType or MB_RETRYCANCEL
   else if(Buttons = uimbcRETRY_IGNORE_ABORT) then
      uType := uType or MB_ABORTRETRYIGNORE;

   if(wParent <> nil) then
      wHNDL := winosTWindow(wParent.oxwParent).wd.h
   else
      wHNDL := 0;

   rslt := windows.MessageBox(wHNDL, pChar(Say), pChar(Title), uType or MB_TASKMODAL);

   case rslt of
      IDOK:       Result := uimbcOK;
      IDCANCEL:   Result := uimbcCANCEL;
      IDYES:      Result := uimbcYES;
      IDNO:       Result := uimbcNO;
      IDRETRY:    Result := uimbcRETRY;
      IDIGNORE:   Result := uimbcIGNORE;
      IDABORT:    Result := uimbcABORT;
   end;
end;

END.
