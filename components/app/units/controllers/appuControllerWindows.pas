{
   appuControllerWindows, common windows functionality for controller support
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT appuControllerWindows;

INTERFACE

   USES
      windowsutils,
      uStd, Utilwmi;

TYPE

   { appTControllerWindows }

   appTControllerWindows = record
      function IsXInputDevice(const deviceID: StdString): boolean;
   end;

VAR
   appControllerWindows: appTControllerWindows;

IMPLEMENTATION

   USES classes, contnrs;

{ appTControllerWindows }

function appTControllerWindows.IsXInputDevice(const deviceID: StdString): boolean;
var
   i,
   j: longint;

   list: TFPObjectList;
   strings: TStringList;

   {vid and pid of the DI device}
   vid,
   pid,
   {vid and pid of the current device}
   currentVid,
   currentPid: longint;

begin
   list := GetWMIInfo('Win32_PNPEntity', ['DeviceID'], '');

   {get vid and pid of the DI device}
   windowsutils.GetVidAndPidFromDeviceId(deviceID, vid, pid);

   for i := 0 to list.Count - 1 do begin
      strings := TStringList(list[i]);

      for j := 0 to strings.Count - 1 do begin
         {this seems like a XInput device if it has IG_ in it}
         if(pos('IG_', strings[j]) > 0) then begin
            {compare the IDs}
            windowsutils.GetVidAndPidFromDeviceId(strings[j], currentVid, currentPid);

            if(currentVid = vid) and (currentPid = pid) then
               exit(true);
         end;
      end;
   end;

   Result := false;
end;

END.
