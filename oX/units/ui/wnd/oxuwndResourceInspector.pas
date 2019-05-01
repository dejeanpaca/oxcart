{
   oxuwndResourceInspector, resource inspector
   Copyright (C) 2019. Dejan Boras

   Started On:    18.04.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndResourceInspector;

INTERFACE

USES
   uStd,
   {app}
   appuMouse,
   {oX}
   uOX, oxuTypes, oxuRunRoutines,
   {$IFNDEF NO_OXCONSOLE}oxuConsoleBackend,{$ENDIF}
   oxuwndBase,
   {ui}
   uiuControl, uiuWindow, uiWidgets, uiuWidget,
   {widgets}
   wdguButton, wdguDivisor, wdguInputBox, wdguGrid;

TYPE
   { oxwdgTResourceInspectorGrid }

   oxwdgTResourceInspectorGrid = class(wdgTStringGrid)
      constructor Create; override;

      function GetValue(index, column: loopint): string; override;
      function GetItemCount(): loopint; override;

      procedure ItemClicked(index: loopint; button: TBitSet = appmcLEFT); override;

      procedure Reload();
   end;

   { oxuiTResourceInspectorWindow }

   oxuiTResourceInspectorWindow = class(oxuiTWindowBase)
      procedure SizeChanged(); override;
   end;

   { oxTResourceInspectorWindow }

   oxTResourceInspectorWindow = class(oxTWindowBase)
      wdg: record
         Divisor: wdgTDivisor;
         Close: wdgTButton;
         Filter: wdgTInputBox;
         List: oxwdgTResourceInspectorGrid;
      end;

      constructor Create(); override;

      protected
      procedure CreateWindow(); override;
      procedure AddWidgets(); override;

      protected
      procedure Resized();
      procedure WindowDestroyed({%H-}wnd: oxuiTWindowBase); override;
   end;

VAR
   oxwndResourceInspector: oxTResourceInspectorWindow;

IMPLEMENTATION
{ oxwdgTResourceInspectorGrid }

constructor oxwdgTResourceInspectorGrid.Create;
begin
   inherited Create;
end;

function oxwdgTResourceInspectorGrid.GetValue(index, column: loopint): string;
begin
   Result := '';
end;

function oxwdgTResourceInspectorGrid.GetItemCount(): loopint;
begin
   Result := 0;
end;

procedure oxwdgTResourceInspectorGrid.ItemClicked(index: loopint;  button: TBitSet);
begin
   inherited ItemClicked(index, button);
end;

procedure oxwdgTResourceInspectorGrid.Reload();
begin
   Assigned();
end;

{ oxuiTResourceInspectorWindow }

procedure oxuiTResourceInspectorWindow.SizeChanged();
begin
   inherited SizeChanged();

   if(BaseHandler <> nil) then
      oxTResourceInspectorWindow(BaseHandler).Resized();
end;

procedure oxTResourceInspectorWindow.AddWidgets();
begin
   wdg.Close := wdgButton.Add('Close', oxNullPoint, oxDimensions(80, 20), @Close);

   wdg.Divisor := wdgDivisor.Add('', oxNullPoint);

   wdg.Filter := wdgInputBox.Add('', oxNullPoint, oxNullDimensions);
   wdg.Filter.SetPlaceholder('Filter');

   uiWidget.Create.Instance := oxwdgTResourceInspectorGrid;
   wdg.List := oxwdgTResourceInspectorGrid(wdgGrid.Add(oxNullPoint, oxNullDimensions));
   wdg.List.AddColumn('Name')^.Ratio := 0.3;
   wdg.List.AddColumn('Value');
   wdg.List.Selectable := true;

   Resized();

   wdg.List.Reload();
end;

procedure oxTResourceInspectorWindow.Resized();
begin
   wdg.Close.SetPosition(wdgPOSITION_HORIZONTAL_RIGHT or wdgPOSITION_VERTICAL_BOTTOM);

   wdg.Divisor.Move(5, wdg.Close.AboveOf());

   wdg.Filter.SetPosition(wdgPOSITION_HORIZONTAL_LEFT or wdgPOSITION_VERTICAL_TOP);
   wdg.Filter.Resize(wdg.Filter.MaximumWidth(), wdg.Filter.Dimensions.h);

   wdg.List.Move(wdgDEFAULT_SPACING, wdg.Filter.BelowOf());
   wdg.List.Resize(wdg.List.MaximumWidth(), wdg.List.Position.y - wdg.Divisor.Position.y);
end;

procedure oxTResourceInspectorWindow.WindowDestroyed(wnd: oxuiTWindowBase);
begin
   ZeroPtr(@wdg, SizeOf(wdg));
end;

constructor oxTResourceInspectorWindow.Create();
begin
   ID := uiControl.GetID('ox.dvar_editor');
   Width := 480;
   Height := 360;
   Title := 'DVar Editor';
   Instance := oxuiTResourceInspectorWindow;

   inherited Create;
end;

procedure oxTResourceInspectorWindow.CreateWindow();
begin
   inherited;
end;

procedure consoleCallback({%H-}con: conPConsole);
begin
   oxwndResourceInspector.Open();
end;

procedure Initialize();
begin
   oxwndResourceInspector := oxTResourceInspectorWindow.Create();
   console.Selected^.AddCommand('resource_inspector', @consoleCallback);
end;

procedure deinitialize();
begin
   FreeObject(oxwndResourceInspector);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   ox.Init.Add(initRoutines, 'ox.wnd.dvar_edit', @initialize, @deinitialize);

END.
