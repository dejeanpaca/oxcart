{
   windowsutils, Windows OS utilities
   Copyright (C) 2009. Dejan Boras

   Started On:    05.09.2016.
}


{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT windowsutils;

INTERFACE

   USES sysutils, windows, StringUtils;

function GetConsoleWindow(): HWND;
function OpenRegistryKey(base: HKEY; const name: string): HKEY;
function OpenRegistryKeyUnicode(base: HKEY; const name: UnicodeString): HKEY;
function GetRegistryString(key: HKEY; const name: string): string;
function GetRegistryStringUnicode(key: HKEY; const name: UnicodeString): UnicodeString;
function GetRegistryDWord(key: HKEY; const name: string): windows.DWORD;
function GetVidAndPidFromDeviceId(const deviceId: string; out vid, pid: longint): boolean;

IMPLEMENTATION

function GetConsoleWindow(): HWND;
const
   BUFSIZE = 1024;
var
   pszNewWindowTitle,
   pszOldWindowTitle: array[0..BUFSIZE - 1] of char;
   hwndFound: HWND;

begin
   windows.GetConsoleTitle(pszOldWindowTitle, BUFSIZE);

   pszNewWindowTitle := '' + sf(Now()) + sf(GetCurrentProcessId());
   windows.SetConsoleTitle(@pszNewWindowTitle);

   Sleep(100);
   hwndFound := windows.FindWindow(nil, pszNewWindowTitle);
   windows.SetConsoleTitle(pszOldWindowTitle);

   result := hwndFound;
end;

function OpenRegistryKey(base: HKEY; const name: string): HKEY;
begin
   Result := 0;

   if(windows.RegOpenKeyEx(base, PChar(name), 0, KEY_READ, @Result) <> ERROR_SUCCESS) then
      Result := 0;
end;

function OpenRegistryKeyUnicode(base: HKEY; const name: UnicodeString): HKEY;
begin
   Result := 0;

   if(windows.RegOpenKeyW(base, PWCH(name), Result) <> ERROR_SUCCESS) then
      Result := 0;
end;

function GetRegistryString(key: HKEY; const name: string): string;
VAR
   buffer: array[0..4095] of byte;
   bufSize: windows.DWORD = 4096;
   lpType: windows.DWORD;

begin
   if(RegQueryValueEx(key, pchar(name), nil, @lpType, @buffer, @bufSize) = ERROR_SUCCESS) then begin
      if(bufSize < high(buffer)) then
         buffer[bufSize + 1] := 0
      else
         buffer[high(buffer)] := 0;

      exit(PChar(@buffer[0]));
   end;

   Result := '';
end;

function GetRegistryStringUnicode(key: HKEY; const name: UnicodeString): UnicodeString;
VAR
   buffer: array[0..8191] of byte;
   bufSize: windows.DWORD = 8192;
   lpType: windows.DWORD;

begin
   if(RegQueryValueExW(key, PWCHAR(name), nil, @lpType, @buffer, @bufSize) = ERROR_SUCCESS) then begin
      if(bufSize < high(buffer)) then
         buffer[bufSize + 1] := 0
      else
         buffer[high(buffer)] := 0;

      exit(PWChar(@buffer[0]));
   end;

   Result := '';
end;

function GetRegistryDWord(key: HKEY; const name: string): windows.DWORD;
VAR
   contents: windows.DWORD;
   bufSize: windows.DWORD = sizeof(contents);

begin
   contents := 0;

   if(RegQueryValueEx(key, pchar(name), nil, nil, @contents, @bufSize) = ERROR_SUCCESS) then
      exit(contents);

   Result := 0;
end;

function GetVidAndPidFromDeviceId(const deviceId: string; out vid, pid: longint): boolean;
var
   code,
   index: longint;
   id: string;

begin
   vid := 0;
   pid := 0;

   {get VID}
   index := Pos('VID_', deviceId);
   if(index > 0) then begin
      id := copy(deviceId, index, 4);
      Val(id, vid, code);

      {get PID}
      if(code = 0) then begin
         index := Pos('PID_', deviceId);

         if(index > 0) then begin
            id := copy(deviceId, index, 4);
            Val(id, pid, code);

            if(code = 0) then
               exit(true);
         end;
      end;
   end;

   Result := false;
end;

END.
