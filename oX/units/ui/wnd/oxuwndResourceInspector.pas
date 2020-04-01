{
   oxuwndResourceInspector, resource inspector
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndResourceInspector;

INTERFACE

USES
   uStd, StringUtils,
   {app}
   appuMouse,
   {oX}
   uOX, oxuTypes, oxuRunRoutines, oxuResourcePool,
   {$IFDEF OX_FEATURE_CONSOLE}
   oxuConsoleBackend,
   {$ENDIF}
   oxuwndBase,
   {ui}
   uiuControl, uiuWindow, uiWidgets, uiuWidget,
   {widgets}
   wdguButton, wdguDivisor, wdguInputBox, wdguGrid;

TYPE
   { oxwdgTResourceInspectorGrid }

   oxwdgTResourceInspectorGrid = class(wdgTStringGrid)
      constructor Create; override;

      function GetValue(index, column: loopint): StdString; override;
      function GetItemCount(): loopint; override;

      procedure ItemClicked(index: loopint; button: TBitSet = appmcLEFT); override;

      procedure Reload();
   end;

   { oxuiTResourceInspectorWindow }

   oxuiTResourceInspectorWindow = class(oxuiTWindowBase)
      procedure SizeChanged(); override;
   end;

   { oxTResourceInspectorWindow }

   oxTResourceInspectorWindow = object(oxTWindowBase)
      wdg: record
         Divisor: wdgTDivisor;
         Close: wdgTButton;
         Filter: wdgTInputBox;
         List: oxwdgTResourceInspectorGrid;
      end;

      constructor Create();

      protected
      procedure CreateWindow(); virtual;
      procedure AddWidgets(); virtual;

      protected
      procedure Resized();
      procedure WindowDestroyed({%H-}wnd: oxuiTWindowBase); virtual;
   end;

VAR
   oxwndResourceInspector: oxTResourceInspectorWindow;

IMPLEMENTATION
{ oxwdgTResourceInspectorGrid }

constructor oxwdgTResourceInspectorGrid.Create;
begin
   inherited Create;
end;

function oxwdgTResourceInspectorGrid.GetValue(index, column: loopint): StdString;
begin
   if(column = 0) then
      Result := oxResource.Pools.List[index].Name
   else
      Result := sf(oxResource.Pools.List[index].n);
end;

function oxwdgTResourceInspectorGrid.GetItemCount(): loopint;
begin
   Result := oxResource.Pools.n;
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
      oxTResourceInspectorWindow(BaseHandler^).Resized();
end;

procedure oxTResourceInspectorWindow.AddWidgets();
begin
   wdg.Close := wdgButton.Add('Close', oxNullPoint, oxNullDimensions, @Close);

   wdg.Divisor := wdgDivisor.Add('');

   wdg.Filter := wdgInputBox.Add('');
   wdg.Filter.SetPlaceholder('Filter');

   uiWidget.Create.Instance := oxwdgTResourceInspectorGrid;
   wdg.List := oxwdgTResourceInspectorGrid(wdgGrid.Add());
   wdg.List.AddColumn('Name')^.Ratio := 0.3;
   wdg.List.AddColumn('Count');
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
   ID := uiControl.GetID('ox.resource_inspector');
   Width := 480;
   Height := 360;
   Title := 'Resource inspector';
   Instance := oxuiTResourceInspectorWindow;

   inherited Create;
end;

procedure oxTResourceInspectorWindow.CreateWindow();
begin
   inherited;
end;

{$IFDEF OX_FEATURE_CONSOLE}
procedure consoleCallback({%H-}con: conPConsole);
begin
   oxwndResourceInspector.Open();
end;
{$ENDIF}

procedure Initialize();
begin
   oxwndResourceInspector.Create();

   {$IFDEF OX_FEATURE_CONSOLE}
   if(console.Selected <> nil) then
      console.Selected^.AddCommand('wnd:resource_inspector', @consoleCallback);
   {$ENDIF}
end;

procedure deinitialize();
begin
   oxwndResourceInspector.Destroy();
end;

INITIALIZATION
   ox.Init.Add('ox.wnd.resource_inspector', @initialize, @deinitialize);

END.
