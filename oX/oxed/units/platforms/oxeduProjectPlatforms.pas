{
   oxeduProjectPlatforms, handles platforms per project
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectPlatforms;

INTERFACE

   USES
      uStd, uLog, udvars,
      {oxed}
      oxeduPlatform, oxeduProjectManagement, oxeduPlatformSettingsFile;

IMPLEMENTATION

procedure reset();
var
   i: loopint;

begin
   for i := 0 to oxedPlatforms.List.n - 1 do begin;
      oxedPlatforms.List.List[i].ProjectReset();
   end;
end;

procedure loadProject();
var
   i: loopint;
   p: oxedTPlatform;

begin
   for i := 0 to oxedPlatforms.List.n - 1 do begin
      p := oxedPlatforms.List.List[i];

      if(not p.Enabled) then
         continue;

      log.v('Loaded platform > ' + p.Name);
      p.ProjectReset();
      oxedPlatformSettingsFile.Load(p);
      p.Load();
   end;
end;

procedure saveProject();
var
   i: loopint;
   p: oxedTPlatform;

begin
   for i := 0 to oxedPlatforms.List.n - 1 do begin
      p := oxedPlatforms.List.List[i];

      if(not p.Enabled) then
         continue;

      oxedPlatformSettingsFile.Save(p);
      p.Save();

      log.v('Saved platform > ' + p.Name);
   end;
end;

INITIALIZATION
   oxedProjectManagement.OnNew.Add(@reset);
   oxedProjectManagement.OnClosed.Add(@reset);

   oxedProjectManagement.OnLoadProject.Add(@loadProject);
   oxedProjectManagement.OnSaveProject.Add(@saveProject);

END.
