{
   oxedu, toolbar
   Copyright (C) 2016. Dejan Boras

   Started On:    29.07.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduToolbar;

INTERFACE

   USES
      uStd,
      {ox}
      oxuTexture,
      {ui}
      uiuControl, uiWidgets, wdguToolbar, wdguWorkbar,
      {oxed}
      oxeduProject, oxeduProjectManagement,
      oxeduMenubar, oxeduIcons, oxeduWorkbar, oxeduActions;

TYPE

   { wdgTOXEDToolbar }

   wdgTOXEDToolbar = class(wdgTToolbar)
      procedure ParentSizeChange; override;

      procedure _Position();
   end;

   { oxedTToolbarGlobal }

   oxedTToolbarGlobal = record
      Toolbar: wdgTOXEDToolbar;

      Buttons: record
         Translate,
         Rotate,
         Scale: wdgPToolbarItem;
      end;

      procedure Initialize();
   end;

VAR
   oxedToolbar: oxedTToolbarGlobal;

IMPLEMENTATION

{ wdgTOXEDToolbar }

procedure wdgTOXEDToolbar.ParentSizeChange;
begin
   inherited ParentSizeChange;

   _Position();
end;

procedure wdgTOXEDToolbar._Position;
var
   bar: wdgTWorkbar;

begin
   bar := oxedWorkbar.Workbar;
   if(bar = nil) then
      bar := oxedMenubar.Bar;

   Move(0, bar.BelowOf(0));
   Resize(20, bar.BelowOf(0) + 1 - oxedMenubar.Bar.Dimensions.h);
end;

{ oxedTToolbarGlobal }

procedure oxedTToolbarGlobal.Initialize;
var
   btn: wdgPToolbarItem;

begin
   uiWidget.Create.Instance := wdgTOXEDToolbar;
   uiWidget.SetTarget();

   Toolbar := wdgTOXEDToolbar(wdgToolbar.Add(true));
   Toolbar.ObscuresMaximization := uiCONTROL_MAXIMIZATION_OBSCURE_HORIZONTAL;
   Toolbar.AutoPositionTarget := wdgWORKBAR_POSITION_NONE;
   Toolbar._Position();

   Toolbar.AddSeparator();

   Buttons.Translate := Toolbar.AddButton(oxedIcons.Create($f245), oxedActions.TOOL_TRANSLATE);
   Buttons.Translate^.Hint := 'Move the selected object';
   Buttons.Translate^.Activate(true);

   Buttons.Rotate := Toolbar.AddButton(oxedIcons.Create($f01e), oxedActions.TOOL_ROTATE);
   Buttons.Rotate^.Hint := 'Rotate the selected object';

   Buttons.Scale := Toolbar.AddButton(oxedIcons.Create($f0b2), oxedActions.TOOL_SCALE);
   Buttons.Scale^.Hint := 'Scale the selected object';

   Toolbar.AddSeparator();

   btn := Toolbar.AddButton(oxedIcons.Create($f060), oxedActions.VIEW_LEFT);
   btn^.Hint := 'Set the view left (CONTROL for right)';

   btn := Toolbar.AddButton(oxedIcons.Create($f062), oxedActions.VIEW_UP);
   btn^.Hint := 'Set the view up (CONTROL for down)';

   btn := Toolbar.AddButton(oxedIcons.Create($f0aa), oxedActions.VIEW_FRONT);
   btn^.Hint := 'Set the view front (CONTROL for back)';

   Toolbar.EnableItems(false);
end;

procedure projectChange();
begin
   oxedToolbar.Toolbar.EnableItems(oxedProject <> nil);
end;

INITIALIZATION
   oxedProjectManagement.OnNew.Add(@projectChange);
   oxedProjectManagement.OnClosed.Add(@projectChange);
   oxedProjectManagement.OnOpen.Add(@projectChange);
   oxedProjectManagement.OnSaved.Add(@projectChange);

END.
