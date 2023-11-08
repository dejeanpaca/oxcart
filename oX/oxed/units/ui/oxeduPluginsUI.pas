{
   oxeduPluginsUI
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduPluginsUI;

INTERFACE

   USES
      uStd,
      {ox}
      uOX, oxuRunRoutines, oxuTypes, oxuwndBase, uiWidgets, uiuWidget,
      wdguButton, wdguDivisor, wdguGrid, uiuContextMenu,
      {oxed}
      uOXED, oxeduMenubar, oxeduPlugins, oxeduIcons;

TYPE

   { oxeduiTPluginsWindow }

   oxeduiTPluginsWindow = class(oxuiTWindowBase)
      procedure SizeChanged(); override;
   end;

   { oxedwdgTPluginsGrid }

   oxedwdgTPluginsGrid = class(wdgTStringGrid)
      function GetItemCount(): loopint; override;
      function GetValue(index, column: loopint): StdString; override;
   end;

   oxedPPluginsWindow = ^oxedTPluginsWindow;

   { oxedTPluginsWindow }

   oxedTPluginsWindow = object(oxTWindowBase)
      wdg: record
         Divisor: wdgTDivisor;
         List: oxedwdgTPluginsGrid;
         Ok: wdgTButton;
      end;

      constructor Create();
      procedure AddWidgets(); virtual;
   end;

VAR
   oxedPluginsWindow: oxedTPluginsWindow;

IMPLEMENTATION

{ oxeduiTPluginsWindow }

procedure oxeduiTPluginsWindow.SizeChanged();
var
   handler: oxedPPluginsWindow;

begin
   inherited SizeChanged();

   handler := BaseHandler;

   if(handler <> nil) and (handler^.wdg.Ok <> nil) then begin
      handler^.wdg.Ok.SetPosition(wdgPOSITION_HORIZONTAL_RIGHT or wdgPOSITION_VERTICAL_BOTTOM);
      handler^.wdg.Divisor.Move(0, handler^.wdg.Ok.AboveOf() + wdgDEFAULT_SPACING);
      handler^.wdg.Divisor.AutoSize();

      handler^.wdg.List.SetPosition(wdgPOSITION_HORIZONTAL_LEFT or wdgPOSITION_VERTICAL_TOP);
      handler^.wdg.List.Resize(Dimensions.w - wdgDEFAULT_SPACING * 2, Dimensions.h - handler^.wdg.Divisor.AboveOf() - wdgDEFAULT_SPACING);
   end;
end;

{ oxedwdgTPluginsGrid }

function oxedwdgTPluginsGrid.GetItemCount(): loopint;
begin
   Result := oxedPlugins.List.n;
end;

function oxedwdgTPluginsGrid.GetValue(index, column: loopint): StdString;
begin
   if(column = 0) then
      Result := oxedPlugins.List.List[index].Name
   else if (column = 1) then
      Result := oxedPlugins.List.List[index].Description
   else
      Result := '';
end;

{ oxedTPluginsWindow }

constructor oxedTPluginsWindow.Create();
begin
   Title := 'Plugins';
   Instance := oxeduiTPluginsWindow;

   inherited;
end;

procedure oxedTPluginsWindow.AddWidgets();
begin
   wdg.Ok := wdgTButton(wdgButton.Add('OK', oxNullPoint, oxNullDimensions, @Close));

   wdg.Divisor := wdgDivisor.Add('', oxNullPoint);

   uiWidget.Create.Instance := oxedwdgTPluginsGrid;
   wdg.List := oxedwdgTPluginsGrid(wdgStringGrid.Add(oxNullPoint, oxNullDimensions));
   wdg.List.SetPadding(2);
   wdg.List.AddColumn('Name')^.Width := 80;
   wdg.List.AddColumn('Description')^.Width := 140;
   wdg.List.Assigned();
   wdg.List.OddColored := true;

   wdg.List.SetPosition(wdgPOSITION_VERTICAL_TOP);

   oxeduiTPluginsWindow(Window).SizeChanged();
end;

procedure menubarInit();
var
   item: uiPContextMenuItem;

begin
   item := oxedMenubar.Editor.AddItem('Plugins', oxedPluginsWindow.OpenWindowAction);
   oxedIcons.Create(item, $f1e6);
end;

procedure init();
begin
   oxedPluginsWindow.Create();
end;

procedure deinit();
begin
   oxedPluginsWindow.Destroy();
end;


INITIALIZATION
   oxed.Init.Add('ox.settings', @init, @deinit);
   oxedMenubar.OnInit.Add(@menubarInit);

END.
