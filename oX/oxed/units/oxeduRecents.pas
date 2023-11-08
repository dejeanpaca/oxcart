{
   oxeduRecents, recents list for oxed
   Copyright (C) 2016. Dejan Boras

   Started On:    13.10.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduRecents;

INTERFACE

   USES
     uStd, udvars, dvaruFile, sysutils, uFileUtils,
     {oxed}
     uOXED, oxeduProject, oxeduProjectManagement;

TYPE
   oxedTRecentsList = TPreallocatedStringArrayList;

   { oxedTRecents }

   oxedTRecents = record
      Max: longint;
      Directories: boolean;

      List: oxedTRecentsList;
      LastOpen: string;

      OnUpdate: TProcedures;

      function FindRecent(const path: string): boolean;
      {validates given path (checks if exists)}
      function Validate(const path: string): boolean;

      procedure Add(const path: string);
   end;

VAR
   oxedRecents: oxedTRecents;

IMPLEMENTATION

VAR
   dvLastOpen: TDVar;
   dvgRecents: TDVarGroup;

   currentListFile: StdString;
   dvFile: TDVar;

procedure dvSaveHandler(var df: dvarTFileData; const parent: StdString);
begin
   df.Write(parent, dvLastOpen, oxedRecents.LastOpen);
   df.Write(parent, dvFile, oxedRecents.List.List, oxedRecents.List.n);
end;

procedure dvListFileNotify({%H-}p: PDVar; {%H-}what: longword);
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

function oxedTRecents.FindRecent(const path: string): boolean;
var
   i: loopint;
   {$IFDEF WINDOWS}
   lpath: string;
   {$ENDIF}

begin
   {$IFDEF WINDOWS}
   lpath := LowerCase(path);
   {$ENDIF}

   for i := 0 to List.n - 1 do begin
      {$IFDEF WINDOWS}
      if(LowerCase(List[i]) = lpath) then
         exit(true);
      {$ELSE}
      if(LowerCase(List[i]) = path) then
         exit(true);
      {$ENDIF}
   end;

   Result := false;
end;

function oxedTRecents.Validate(const path: string): boolean;
begin
   if(not Directories) then begin
     Result := FileUtils.Exists(path) > 0;
   end else begin
     Result := FileUtils.DirectoryExists(path);
   end;
end;

procedure oxedTRecents.Add(const path: string);
var
   correctPath: string;

begin
   correctPath := ExcludeTrailingPathDelimiter(path);

   if(FindRecent(correctPath)) then
      exit;

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

   dvarf.OnSave.Add(@dvgRecents, @dvSaveHandler);

   oxedProjectManagement.OnOpen.Add(@OnProjectOpen);
   oxedProjectManagement.OnSaved.Add(@OnProjectOpen);
   oxedProjectManagement.OnClosed.Add(@OnProjectClosed);
   oxedProjectManagement.OnNew.Add(@OnProjectClosed);

END.
