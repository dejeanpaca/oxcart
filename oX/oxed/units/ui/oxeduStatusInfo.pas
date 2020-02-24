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

   oxedStatusInfo.Wdg.Info := oxedStatusbar.Status.AddCaption('0');

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

      status := getiecByteSizeHumanReadableSI(heapStatus.TotalFree) + '/' +
         getiecByteSizeHumanReadableSI(heapStatus.TotalAllocated) + '/' +
         getiecByteSizeHumanReadableSI(heapStatus.Unused) + '/' +
         getiecByteSizeHumanReadableSI(heapStatus.TotalAddrSpace);

      if(oxedStatusInfo.Wdg.Info^.Caption <> status) then begin
         oxedStatusInfo.Wdg.Info^.Caption := status;
         oxedStatusbar.Status.ItemChanged();
      end;
   end;
end;

INITIALIZATION
   TTimerInterval.Initialize(interval);

   oxed.PostInit.Add('status_info', @initialize);

   ox.OnRun.Add('oxed.update_status_info', @updateInfo);

END.
