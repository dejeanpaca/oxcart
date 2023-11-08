{
   oxeduPreviewGenerator, generates previews
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduPreviewGenerator;

INTERFACE

   USES
      sysutils, uStd, uLog,
      {app}
      appuActionEvents,
      {ox}
      oxuRunRoutines, oxuThreadTask,
      {oxed}
      uOXED, oxeduProject, oxeduProjectManagement, oxeduTasks;

TYPE
   { oxedTPreviewGeneratorTask }

   oxedTPreviewGeneratorTask = class(oxedTTask)
      constructor Create(); override;
      procedure Run(); override;

      procedure ThreadStart(); override;
      procedure ThreadDone(); override;
   end;

   { oxedTPreviewGeneratorTask }

   oxedTPreviewGeneratorGlobal = record
      Task: oxedTPreviewGeneratorTask;

      OnStart,
      OnDone: TProcedures;
      OnFile: TProcedures;

      class procedure Initialize(); static;
   end;

VAR
   oxedPreviewGenerator: oxedTPreviewGeneratorGlobal;

IMPLEMENTATION

{ oxedTPreviewGeneratorGlobal }

class procedure oxedTPreviewGeneratorGlobal.Initialize();
begin
   {$IFNDEF NO_THREADS}
   with oxedPreviewGenerator do begin
      Task := oxedTPreviewGeneratorTask.Create();
      Task.SetAsContinuous();
      Task.EmitAllEvents();
   end;
   {$ELSE}
   {NOTE: We can't generate previews with no thread support}
   exit;
   {$ENDIF}
end;

{ TBuildTask }

constructor oxedTPreviewGeneratorTask.Create();
begin
   inherited;

   Name := 'Preview Generator';
   Background := true;
end;

procedure oxedTPreviewGeneratorTask.Run();
begin
   inherited;

   try
      // TODO: Implement
   except
      on e: Exception do begin
         log.e('Preview scanner failed running');
         log.e(DumpExceptionCallStack(e));
      end;
   end;
end;

procedure oxedTPreviewGeneratorTask.ThreadStart();
begin
   inherited;

   oxedPreviewGenerator.OnStart.Call();
end;

procedure oxedTPreviewGeneratorTask.ThreadDone();
begin
   inherited;

   oxedPreviewGenerator.OnDone.Call();
end;

procedure deinit();
begin
   if(oxedPreviewGenerator.Task <> nil) then begin
      oxedPreviewGenerator.Task.StopWait();
      FreeObject(oxedPreviewGenerator.Task);
   end;
end;

procedure projectClosed();
begin
   if(oxedPreviewGenerator.Task <> nil) and (oxedPreviewGenerator.Task.IsRunning()) then
      oxedPreviewGenerator.Task.Stop();
end;

procedure projectOpen();
begin
   if(oxedPreviewGenerator.Task <> nil) and (not oxedPreviewGenerator.Task.IsRunning()) then
      oxedPreviewGenerator.Task.Start();
end;

INITIALIZATION
   oxed.Init.Add('preview_generator', @oxedPreviewGenerator.Initialize, @deinit);

   TProcedures.InitializeValues(oxedPreviewGenerator.OnStart);
   TProcedures.InitializeValues(oxedPreviewGenerator.OnDone);
   TProcedures.InitializeValues(oxedPreviewGenerator.OnFile);

   oxedProjectManagement.OnOpen.Add(@projectOpen);
   oxedProjectManagement.OnClosed.Add(@projectClosed);

END.
