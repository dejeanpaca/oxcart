{
   oxeduStatusInfo, status bar information
   Copyright (C) 2019. Dejan Boras

   Started On:    04.04.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduStatusInfo;

INTERFACE

   USES
      uStd, uBinarySize,
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

procedure updateInfo();
var
   heapStatus: THeapStatus;

begin
   if(oxedStatusInfo.Wdg.Info <> nil) then begin
      heapStatus := GetHeapStatus;

      oxedStatusInfo.Wdg.Info^.Caption := getiecByteSizeHumanReadableSI(heapStatus.TotalFree) + '/' +
         getiecByteSizeHumanReadableSI(heapStatus.TotalAllocated) + '/' +
         getiecByteSizeHumanReadableSI(heapStatus.Unused) + '/' +
         getiecByteSizeHumanReadableSI(heapStatus.TotalAddrSpace);

      oxedStatusbar.Status.ItemChanged();
   end;
end;

VAR
   updateRoutine: oxTRunRoutine;
   oxedInitRoutines: oxTRunRoutine;

INITIALIZATION
   oxed.PostInit.iAdd(oxedInitRoutines, 'status_info', @initialize);

   ox.OnRun.Add(updateRoutine, 'oxed.update_status_info', @updateInfo);

END.
