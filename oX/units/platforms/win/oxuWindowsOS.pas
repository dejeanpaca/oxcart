{
   oxuWindowsOS, Windows OS specific functionality
   Copyright (c) 2013. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuWindowsOS;

INTERFACE

   USES
      uStd, uLog, Windows,
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
      class function FormatMessage(messsageID: DWORD; includeCode: boolean = true): StdString; static;
      {get the last error code, and log it if silent is set to false}
      function GetLastError(silent: boolean = true): DWORD;

      function MessageBox(wParent: uiTWindow; const Title, Say: StdString;
         Style: uiTMessageBoxStyle; Buttons: longword): longword;

      function LoadIcon(const fn: StdString; w: windows.UINT = 0; h: windows.UINT = 0; flags: windows.UINT = 0): HICON;
   end;

VAR
   winos: winTWindowsOSGlobal;

IMPLEMENTATION

{ winTWindowsOSGlobal }

function winTWindowsOSGlobal.LogError(const prefix: string): DWORD;
begin
   LastError := windows.GetLastError();
   windows.SetLastError(0);
   Result := LastError;

   if(Result <> 0) then begin
      LastErrorDescription := 'winOS > ' + prefix + ': ' + FormatMessage(Result);
      log.e(LastErrorDescription);
   end;
end;

class function winTWindowsOSGlobal.FormatMessage(messsageID: DWORD; includeCode: boolean = true): StdString;
var
   len: loopint;
   buf: array[0..65535] of char;

function copyMessage(): StdString;
begin
   if(len > 0) then
      Result := Copy(PChar(@buf[0]), 1, len - 2)
   else
      Result := '';
end;

begin
   len := windows.FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, nil, messsageID, 0, @buf, Length(buf) - 1, nil);

   if(includeCode) then
      Result := '(0x' + hexstr(messsageID, 8) + ') ' + copyMessage()
   else
      Result := copyMessage();
end;

function winTWindowsOSGlobal.GetLastError(silent: boolean): DWORD;
begin
   LastError := windows.GetLastError();
   windows.SetLastError(0);
   Result := LastError;

   if(Result <> 0) and (not silent) then
      log.e('winos > error: ' + FormatMessage(Result));
end;

function winTWindowsOSGlobal.MessageBox(wParent: uiTWindow;
   const Title, Say: StdString; Style: uiTMessageBoxStyle; Buttons: longword): longword;
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

function winTWindowsOSGlobal.LoadIcon(const fn: StdString; w: windows.UINT; h: windows.UINT; flags: windows.UINT): windows.HICON;
begin
   if(w = 0) or (h = 0) then
      flags := flags or LR_DEFAULTSIZE;

   Result := Windows.LoadImage(0, pchar(fn), IMAGE_ICON, 0, 0, LR_LOADFROMFILE or flags);

   if(winos.GetLastError(true) <> 0) then
      Result := 0;
end;

END.
