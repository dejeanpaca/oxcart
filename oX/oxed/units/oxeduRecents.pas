{
   oxeduRecents, recents list for oxed
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduRecents;

INTERFACE

   USES
     uStd, udvars, dvaruFile, sysutils, uFileUtils, uFilePathList,
     {oxed}
     uOXED, oxeduProject, oxeduProjectManagement;

TYPE
   oxedTRecentsList = TFilePathStringList;

   { oxedTRecents }

   oxedTRecents = record
      Max: longint;
      Directories: boolean;

      List: oxedTRecentsList;
      LastOpen: StdString;

      OnUpdate: TProcedures;

      {validates given path (checks if exists)}
      function Validate(const path: StdString): boolean;

      procedure Add(const path: StdString);
   end;

VAR
   oxedRecents: oxedTRecents;

IMPLEMENTATION

VAR
   dvLastOpen: TDVar;
   dvgRecents: TDVarGroup;

   currentListFile: StdString;
   dvFile: TDVar;

procedure dvSaveHandler(var context: TDVarNotificationContext);
begin
   if(context.What = DVAR_NOTIFICATION_WRITE) then begin
      context.Result := 0;

      dvarPFileData(context.f)^.Write(context.Parent, dvLastOpen, oxedRecents.LastOpen);
      dvarPFileData(context.f)^.Write(context.Parent, dvFile, oxedRecents.List.List, oxedRecents.List.n);
   end;
end;

procedure dvListFileNotify(var {%H-}context: TDVarNotificationContext);
begin
   oxedRecents.Add(currentListFile);
end;

procedure OnProjectOpen();
begin
   if(oxedProject.Path <> '') then begin
      oxedRecents.LastOpen := oxedProject.Path;
      oxedRecents.Add(oxedProject.Path);

      oxedRecents.OnUpdate.Call();
   end;
end;

procedure OnProjectClosed();
begin
   if(not oxed.Deinitializing) and (oxed.Initialized) then
      oxedRecents.LastOpen := '';
end;

{ oxedTRecents }

function oxedTRecents.Validate(const path: StdString): boolean;
begin
   if(not Directories) then
      Result := FileUtils.Exists(path) > 0
   else
      Result := FileUtils.DirectoryExists(path);
end;

procedure oxedTRecents.Add(const path: StdString);
var
   correctPath: StdString;
   index: loopint;

begin
   if(List.n >= oxedRecents.Max) then
      List.RemoveLast();

   correctPath := ExcludeTrailingPathDelimiter(path);

   {check if already exists}
   index := List.FindPath(correctPath);

   if(index > -1) then begin
      {move to top if already exists}
      if(index > 0) then begin
         List.Remove(index);
         List.Insert(0, correctPath);
      end;

      exit;
   end;

   if(oxedRecents.Validate(correctPath)) then
      List.Add(correctPath);
end;

INITIALIZATION
   oxedRecents.Max := 10;
   oxedRecents.Directories := true;
   oxedTRecentsList.InitializeValues(oxedRecents.List);
   TProcedures.InitializeValues(oxedRecents.OnUpdate);

   dvgOXED.Add('recent', dvgRecents);

   dvgRecents.Add(dvLastOpen, 'last_open', dtcSTRING, @oxedRecents.LastOpen);
   dvgRecents.Add(dvFile, 'file', dtcSTRING, @currentListFile);
   Include(dvFile.Properties, dvarINVISIBLE);
   dvFile.pNotify := @dvListFileNotify;

   dvgRecents.pNotify := @dvSaveHandler;

   oxedProjectManagement.OnOpen.Add(@OnProjectOpen);
   oxedProjectManagement.OnSaved.Add(@OnProjectOpen);
   oxedProjectManagement.OnClosed.Add(@OnProjectClosed);
   oxedProjectManagement.OnNew.Add(@OnProjectClosed);

END.
