{
   oxedu, toolbar
   Copyright (C) 2017. Dejan Boras

   Started On:    29.07.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduToolbar;

INTERFACE

   USES
      uStd, uColors,
      {app}
      appuEvents,
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

CONST
   ToolButtonColor: TColor4ub = (192, 192, 255, 255);
   ViewButtonColor: TColor4ub = (192, 255, 192, 255);

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


function CreateButton(icon: loopint; action: TEventID; const color: TColor4ub; const hint: StdString = ''): wdgPToolbarItem;
begin
   Result := oxedToolbar.Toolbar.AddButton(oxedIcons.Create(icon), action);
   Result^.Hint := hint;
   Result^.Color := color;
end;

{ oxedTToolbarGlobal }

procedure oxedTToolbarGlobal.Initialize();
begin
   uiWidget.Create.Instance := wdgTOXEDToolbar;
   uiWidget.SetTarget();

   Toolbar := wdgTOXEDToolbar(wdgToolbar.Add(true));
   Toolbar.ObscuresMaximization := uiCONTROL_MAXIMIZATION_OBSCURE_HORIZONTAL;
   Toolbar.AutoPositionTarget := wdgWORKBAR_POSITION_NONE;
   Toolbar._Position();

   Toolbar.AddSeparator();

   Buttons.Translate := CreateButton($f245, oxedActions.TOOL_TRANSLATE, ToolButtonColor,
      'Move the selected object');
   Buttons.Translate^.Activate(true);

   Buttons.Rotate := CreateButton($f01e, oxedActions.TOOL_ROTATE, ToolButtonColor,
      'Rotate the selected object');
   Buttons.Scale := CreateButton($f0b2, oxedActions.TOOL_SCALE, ToolButtonColor,
      'Scale the selected object');

   Toolbar.AddSeparator();

   CreateButton($f060, oxedActions.VIEW_LEFT, ViewButtonColor,
      'Set the view left (CONTROL for right)');
   CreateButton($f062, oxedActions.VIEW_UP, ViewButtonColor,
      'Set the view up (CONTROL for down)');
   CreateButton($f0aa, oxedActions.VIEW_FRONT, ViewButtonColor,
      'Set the view front (CONTROL for back)');

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
