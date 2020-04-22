{
   oxeduStatusInfo, status bar information
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduStatusInfo;

INTERFACE

   USES
      uStd, uBinarySize, uTiming,
      {ox}
      uOX, oxuRunRoutines,
      {widgets}
      uiWidgets, wdguToolbar,
      {oxed}
      uOXED, oxeduIcons, oxeduStatusbar;

TYPE
   oxedTStatusInfo = record
      Wdg: record
         Info: wdgPToolbarItem;
      end;
   end;

VAR
   oxedStatusInfo: oxedTStatusInfo;

IMPLEMENTATION

procedure SetupInfo();
begin
   if(oxedStatusbar.Status = nil) then
      exit;
end;

procedure Initialize();
begin
   if(oxedStatusbar.Status = nil) then
      exit;

   if(oxedStatusbar.Status.Items.n > 0) then
      oxedStatusbar.Status.AddSeparator();

   oxedStatusInfo.Wdg.Info := oxedStatusbar.Status.AddButton(oxedIcons.Create($f538));

   SetupInfo();
end;

VAR
   interval: TTimerInterval;

procedure updateInfo();
var
   status: StdString;
   heapStatus: THeapStatus;

begin
   if(oxedStatusInfo.Wdg.Info <> nil) and (interval.Elapsed())  then begin
      heapStatus := GetHeapStatus;

      status := 'Heap total free: ' + getiecByteSizeHumanReadableSI(heapStatus.TotalFree) + #13 +
         'Total allocated: ' + getiecByteSizeHumanReadableSI(heapStatus.TotalAllocated) + #13 +
         'Total addressable space: ' + getiecByteSizeHumanReadableSI(heapStatus.TotalAddrSpace);

      if(oxedStatusInfo.Wdg.Info^.Caption <> status) then begin
         oxedStatusInfo.Wdg.Info^.SetHint(status);
      end;
   end;
end;

INITIALIZATION
   TTimerInterval.Initialize(interval, 250);

   oxed.PostInit.Add('status_info', @initialize);

   ox.OnRun.Add('oxed.update_status_info', @updateInfo);

END.
