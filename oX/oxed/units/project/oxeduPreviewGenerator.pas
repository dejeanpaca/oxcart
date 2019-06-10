{
   oxeduPreviewGenerator, generates previews
   Copyright (C) 2019. Dejan Boras

   Started On:    10.06.2019.
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

      procedure TaskStart(); override;

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
   with oxedPreviewGenerator do begin
      Task := oxedTPreviewGeneratorTask.Create();
      Task.SetAsContinuous();
      Task.EmitAllEvents();
      {$IFNDEF NO_THREADS}
      {NOTE: We can't generate previews with no thread support}
      Task.Start();
      {$ENDIF}
   end;
end;

{ TBuildTask }

constructor oxedTPreviewGeneratorTask.Create();
begin
   inherited;

   Name := 'Preview Generator';
end;

procedure oxedTPreviewGeneratorTask.Run();
begin
   inherited Run;

   log.v('Preview generator started ...');

   try
      // TODO: Implement
   except
      on e: Exception do begin
         log.e('Preview scanner failed running');
         log.e(DumpExceptionCallStack(e));
      end;
   end;
end;

procedure oxedTPreviewGeneratorTask.TaskStart();
begin
   inherited;
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
   FreeObject(oxedPreviewGenerator.Task);
end;

procedure projectClosed();
begin
   if(oxedPreviewGenerator.Task <> nil) then
      oxedPreviewGenerator.Task.StopWait();
end;

procedure projectOpen();
begin
   projectClosed();

   oxedPreviewGenerator.Task.Run();
end;

VAR
   oxedInitRoutines: oxTRunRoutine;

INITIALIZATION
   oxed.Init.Add(oxedInitRoutines, 'preview_generator', @oxedPreviewGenerator.Initialize, @deinit);

   TProcedures.InitializeValues(oxedPreviewGenerator.OnStart);
   TProcedures.InitializeValues(oxedPreviewGenerator.OnDone);
   TProcedures.InitializeValues(oxedPreviewGenerator.OnFile);

   oxedProjectManagement.OnOpen.Add(@projectOpen);
   oxedProjectManagement.OnClosed.Add(@projectClosed);

END.
