{
   oxeduRecents, recents list for oxed
   Copyright (C) 2016. Dejan Boras

   Started On:    13.10.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduRecents;

INTERFACE

   USES
     uStd, udvars, dvaruFile, sysutils,
     {oxed}
     uOXED, oxeduProject, oxeduProjectManagement;

TYPE
   oxedTRecentsList = TPreallocatedStringArrayList;

   { oxedTRecents }

   oxedTRecents = record
      Max: longint;

      List: oxedTRecentsList;
      LastOpen: string;

      OnUpdate: TProcedures;

      function FindRecent(const path: string): boolean;
      procedure Add(const path: string);
   end;

VAR
   oxedRecents: oxedTRecents;

IMPLEMENTATION

VAR
   dvLastOpen: TDVar;
   dvgRecents: TDVarGroup;

   currentListFile: string;
   dvFile: TDVar;

procedure dvSaveHandler(var df: dvarTFileData; const parent: string);
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
   oxedRecents.LastOpen := oxedProject.Path;
   oxedRecents.Add(oxedProject.Path);

   oxedRecents.OnUpdate.Call();
end;

procedure OnProjectClosed();
begin
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

procedure oxedTRecents.Add(const path: string);
var
   correctPath: string;

begin
   correctPath := ExcludeTrailingPathDelimiter(path);

   if(FindRecent(correctPath)) then
      exit;

   List.Add(correctPath);
end;

INITIALIZATION
   oxedRecents.Max := 10;
   oxedTRecentsList.Initialize(oxedRecents.List);
   TProcedures.Initialize(oxedRecents.OnUpdate);
   dvgOXED.Add('recent', dvgRecents);

   dvgRecents.Add(dvLastOpen, 'last_open', dtcSTRING, @oxedRecents.LastOpen);
   dvgRecents.Add(dvFile, 'file', dtcSTRING, @currentListFile);
   Include(dvFile.Properties, dvarINVISIBLE);
   dvFile.pNotify := @dvListFileNotify;

   dvarf.OnSave.Add(@dvgRecents, @dvSaveHandler);

   oxedProjectManagement.OnProjectOpen.Add(@OnProjectOpen);
   oxedProjectManagement.OnProjectSaved.Add(@OnProjectOpen);
   oxedProjectManagement.OnProjectClosed.Add(@OnProjectClosed);
   oxedProjectManagement.OnNewProject.Add(@OnProjectClosed);

END.
