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

END.
