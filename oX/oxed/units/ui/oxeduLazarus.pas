{
   oxeduLazarus, oxed lazarus management
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduLazarus;

INTERFACE

   USES
      process, sysutils,
      uLog, uBuild,
      {app}
      appuActionEvents,
      {oX}
      oxuwndToast,
      {oxed}
      uOXED, oxeduSettings,
      oxeduActions, oxeduBuild, oxeduConsole, oxeduProject;

TYPE

   { oxedTLazarusGlobal }

   oxedTLazarusGlobal = record
      {open lazarus ide for this project}
      class procedure OpenLazarus(); static;
   end;

VAR
   oxedLazarus: oxedTLazarusGlobal;

IMPLEMENTATION

VAR
   laz: TProcess;
   openLazarusFlag: boolean = false;

procedure runLazarus();
begin
   try
      if(oxedSettings.ShowNotifications) then
         oxToast.Show('Lazarus', 'Starting lazarus ... ');

      laz.Options := laz.Options - [poWaitOnExit];
      laz.Execute();
   except
      on e : Exception  do begin
         oxedConsole.e('Failed to run Lazarus ' + e.ToString());
      end;
   end;
end;

procedure openLazarusRecreate(recreateProject: boolean);
begin
   if(openLazarusFlag) then begin
      openLazarusFlag := false;

      if(recreateProject) then begin
         if(not oxedBuild.Recreate()) then
            exit;
      end;

      runLazarus();
   end;
end;

procedure openLazarusAfterRecreate();
begin
   openLazarusRecreate(true);
end;

class procedure oxedTLazarusGlobal.OpenLazarus();
begin
   if(oxedProjectValid()) then begin
      if(laz = nil) then begin
         laz := TProcess.Create(nil);
         laz.Executable := build.GetLazarusStartExecutable();
      end;

      if(not laz.Running) then begin
         laz.Parameters.Clear();
         laz.Parameters.Add('--no-splash-screen');
         laz.Parameters.Add('--force-new-instance');

         if(build.GetLazarus()^.ConfigPath <> '') then begin
            laz.Parameters.Add('--pcp=' + build.GetLazarus()^.ConfigPath);
            log.w('Config path: ' + build.GetLazarus()^.ConfigPath);
         end;

         laz.Parameters.Add(oxedProject.TempPath + oxPROJECT_LIB_LPI);
      end else begin
         if(oxedSettings.ShowNotifications) then
            oxToast.Show('Lazarus', 'Already running');

         log.v('Lazarus already running');
         exit;
      end;

      if(oxedProject.Running) then begin
         runLazarus();
         exit;
      end;

      {first recreate files}
      oxedBuild.RecreateTask();
      openLazarusFlag := true;
   end else
      log.v('Cannot open lazarus. No valid project');
end;


INITIALIZATION
   oxedBuild.OnDone.Add(@openLazarusAfterRecreate);

   oxedActions.OPEN_LAZARUS := appActionEvents.SetCallback(@oxedLazarus.OpenLazarus);

END.
