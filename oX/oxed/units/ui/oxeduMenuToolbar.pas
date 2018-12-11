{
   oxeduMenuToolbar, menu bar toolbar
   Copyright (C) 2017. Dejan Boras

   Started On:    02.07.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduMenuToolbar;

INTERFACE

   USES
      uStd,
      {ox}
      uOX, oxuFramerate,
      {widgets}
      uiWidgets, uiuWidget, wdguToolbar, wdguWorkbar,
      {oxed}
      oxeduMenubar;

TYPE
   oxedTMenuToolbar = record
      Toolbar: wdgTToolbar;
      FrameRate: wdgPToolbarItem;

      class procedure OnResize(); static;
   end;

VAR
   oxedMenuToolbar: oxedTMenuToolbar;

IMPLEMENTATION

class procedure oxedTMenuToolbar.OnResize();
begin
   if(oxedMenuToolbar.Toolbar <> nil) then begin
      oxedMenuToolbar.Toolbar.AutoSetDimensions(true);
      oxedMenuToolbar.Toolbar.SetPosition(wdgPOSITION_HORIZONTAL_RIGHT, false);
   end;
end;

procedure Initialize();
begin
   oxedMenubar.Bar.SetTarget();

   oxedMenuToolbar.Toolbar := wdgToolbar.Add();
   oxedMenuToolbar.Toolbar.AutoPositionTarget := wdgWORKBAR_POSITION_NONE;
   oxedMenuToolbar.Toolbar.Transparent := true;

   oxedMenuToolbar.FrameRate := oxedMenuToolbar.Toolbar.AddCaption('');
   oxedMenuToolbar.FrameRate^.Hint := 'Editor frame rate';

   oxedMenuToolbar.OnResize();
end;

procedure deinitialize();
begin
   oxedMenuToolbar.Toolbar := nil;
   oxedMenuToolbar.FrameRate := nil;
end;

procedure updateFramerate();
begin
   if(oxedMenubar.Bar <> nil) and (oxedMenuToolbar.FrameRate <> nil) then begin
      oxedMenuToolbar.FrameRate^.Caption := oxFramerate.Get();
      oxedMenuToolbar.OnResize();
   end;
end;

INITIALIZATION
   oxedMenubar.OnInit.Add(@initialize);
   oxedMenubar.OnDeInit.Add(@deinitialize);
   oxedMenubar.OnResize.Add(@oxedMenuToolbar.OnResize);

   ox.OnRun.Add(@updateFramerate);

END.
