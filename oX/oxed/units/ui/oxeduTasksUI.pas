{
   oxeduTasksUI, ui to show active tasks
   Copyright (C) 2017. Dejan Boras

   Started On:    08.07.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduTasksUI;

INTERFACE

   USES
      uStd, StringUtils,
      {ox}
      oxuRunRoutines, oxuTexture,
      {ui}
      uiuWindowTypes, wdguToolbar,
      {oxed}
      uOXED, oxeduIcons, oxeduTasks, oxuThreadTask,
      oxeduMenubar, oxeduMenuToolbar;

TYPE
   oxedTTasksWindow = class(uiTWindow)
   end;

   oxedTTasksUI = record
      Wdg: record
         Tasks: wdgPToolbarItem;
      end;

      Icons: record
         Tasks,
         Running: oxTTexture;
      end;

      Wnd: oxedTTasksWindow;
   end;

VAR
   oxedTasksUI: oxedTTasksUI;

IMPLEMENTATION

procedure showTasks();
begin
end;

procedure toggleAnimate();
var
   tasksRunning: loopint;
   tasksString: string;
   i: loopint;
   task: oxTThreadTask;

begin
   if(oxedMenuToolbar.Toolbar = nil) then
      exit;

   tasksRunning := 0;
   tasksString := '';

   for i := 0 to oxedTasks.List.n - 1 do begin
      task := oxedTasks.List.List[i];

      if(task.IsRunning()) then begin
         inc(tasksRunning);

         tasksString := tasksString + #13;

         if(task.Name <> '') then
            tasksString := tasksString + task.Name
         else
            tasksString := tasksString + 'Unknown';
      end;
   end;


   if(tasksRunning > 0) then begin
      oxedTasksUI.Wdg.Tasks^.Glyph := oxedTasksUI.Icons.Running;
      oxedTasksUI.Wdg.Tasks^.SetSpin();

      tasksString := sf(tasksRunning) + ' tasks are running'#13#13 + tasksString;

      oxedTasksUI.Wdg.Tasks^.Hint := tasksString;
   end else begin
      oxedTasksUI.Wdg.Tasks^.Glyph := oxedTasksUI.Icons.Tasks;
      oxedTasksUI.Wdg.Tasks^.SetSpin(false);
      oxedTasksUI.Wdg.Tasks^.Hint := 'No tasks running';
   end;
end;


procedure initialize();
begin
   if(oxedMenuToolbar.Toolbar = nil) then
      exit;

   oxedMenuToolbar.Toolbar.AddSeparator();

   oxedTasksUI.Icons.Tasks := oxedIcons.Create($f0ae);
   if(oxedTasksUI.Icons.Tasks <> nil) then
     oxedTasksUI.Icons.Tasks.MarkUsed();

   oxedTasksUI.Icons.Running := oxedIcons.Create($f110);
   if(oxedTasksUI.Icons.Running <> nil) then
     oxedTasksUI.Icons.Running.MarkUsed();

   oxedTasksUI.Wdg.Tasks := oxedMenuToolbar.Toolbar.AddButton(oxedTasksUI.Icons.Running, 0, @showTasks);

   toggleAnimate();

   oxedMenuToolbar.OnResize();
end;

procedure deinit();
begin
end;

VAR
   oxedInitRoutines: oxTRunRoutine;

INITIALIZATION
   oxed.Init.dAdd(oxedInitRoutines, 'oxed.tasks-ui', @deinit);
   oxedMenubar.OnInit.Add(@initialize);

   oxedTasks.OnTaskStart.Add(@toggleAnimate);
   oxedTasks.OnTaskDone.Add(@toggleAnimate);

END.
