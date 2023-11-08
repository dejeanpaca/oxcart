{
   oxeduMenuToolbar, menu bar toolbar
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduMenuToolbar;

INTERFACE

   USES
      uStd,
      {ox}
      uOX, oxuFramerate, oxuRunRoutines,
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
var
   frameRate: StdString;

begin
   if(oxedMenubar.Bar <> nil) and (oxedMenuToolbar.FrameRate <> nil) then begin
      frameRate := oxFramerate.Get();

      if(oxedMenuToolbar.FrameRate^.Caption <> frameRate) then begin
         oxedMenuToolbar.FrameRate^.Caption := frameRate;
         oxedMenuToolbar.OnResize();
      end;
   end;
end;

INITIALIZATION
   oxedMenubar.OnInit.Add(@initialize);
   oxedMenubar.OnDeInit.Add(@deinitialize);
   oxedMenubar.OnResize.Add(@oxedMenuToolbar.OnResize);

   ox.OnRun.Add('oxed.menubar_update', @updateFramerate);

END.
