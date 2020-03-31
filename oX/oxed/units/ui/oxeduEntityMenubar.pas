{
   oxeduEntityMenubar, entity menu bar
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduEntityMenubar;

INTERFACE

   USES
      uStd,
      {ui}
      uiuContextMenu,
      {OXED}
      oxeduEntityMenu, oxeduMenubar,
      oxeduProject, oxeduProjectManagement, oxeduProjectRunner;

IMPLEMENTATION

VAR
   Entities: uiTContextMenu;

procedure OnProjectChange();
begin
   if(Entities <> nil) then
      Entities.Enable(oxedProjectValid());
end;

procedure init();
var
   index: loopint;

begin
   index := oxedMenubar.Bar.Menus.FindIndexOfSub(oxedMenubar.ObjectMenu);
   oxedMenubar.Bar.Menus.InsertAt(index);

   Entities := oxedMenubar.Bar.Add('Entities');

   oxedTEntityMenuGlobal.AddTo(Entities);
end;

INITIALIZATION
   oxedProjectManagement.OnOpen.Add(@OnProjectChange);
   oxedProjectManagement.OnClosed.Add(@OnProjectChange);
   oxedProjectManagement.OnSaved.Add(@OnProjectChange);
   oxedProjectManagement.OnNew.Add(@OnProjectChange);

   oxedProjectRunner.OnStart.Add(@OnProjectChange);
   oxedProjectRunner.OnStop.Add(@OnProjectChange);
   oxedProjectRunner.OnPauseToggle.Add(@OnProjectChange);

   oxedMenubar.OnInit.Add(@init);

END.

