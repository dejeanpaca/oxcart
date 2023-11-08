{
   oxeduProjectStatisticsWindow, project statistics window
   Copyright (C) 2019. Dejan Boras

   Started On:    29.10.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectStatisticsWindow;

INTERFACE

   USES
      uStd,
      {oX}
      oxuTypes, oxuConsoleBackend,
      {wnd}
      oxuwndBase, oxuwndSettingsBase,
      {ui}
      uiuControl, uiuWidget, uiWidgets, uiuMessageBox, uiuTypes,
      {wdg}
      wdguButton, wdguDivisor, wdguLabel, wdguList,
      {oxed}
      uOXED, oxeduProject;

TYPE
   { oxeduiTProjectStatisticsWindow }

   oxeduiTProjectStatisticsWindow = class(oxuiTWindowBase)
   end;

   { oxedTProjectStatisticsWindow }

   oxedTProjectStatisticsWindow = class(oxTSettingsWindowBase)
      widgets: record
         Statistics: wdgTStringList;
         AddParameter,
         RemoveParameter: wdgTButton;
         Separator: wdgTDivisor;
      end;

      constructor Create(); override;
      procedure Open(); override;

      protected
      procedure AddWidgets(); override;
   end;

VAR
   oxedwndProjectStatistics: oxedTProjectStatisticsWindow;

IMPLEMENTATION

procedure closeSettingsWindow();
begin
   oxedwndProjectStatistics.Close();
end;

{ oxedTProjectStatisticsWindow }

procedure oxedTProjectStatisticsWindow.AddWidgets();
begin
   inherited;

   AddCancelSaveButtons();
   wdg.Save.Callback.Use(@Save);
   AddRevertButton();
   wdg.Revert.Callback.Use(@Revert);
   widgets.Separator := wdgDivisor.Add('', uiWidget.LastRect.AboveOf());

   uiWidget.LastRect.Assign(Window);
   wdgLabel.Add('File Statistics:');
   widgets.Statistics := wdgStringList.Add(uiWidget.LastRect.BelowOf(), oxDimensions(Window.Dimensions.w - wdgDEFAULT_SPACING*2, 120));
   widgets.Statistics.Selectable := true;
   widgets.Statistics.OddColored := true;
end;

{$IFDEF OX_FEATURE_CONSOLE}
procedure consoleCallback({%H-}con: conPConsole);
begin
   if(oxedwndProjectStatistics <> nil) then
      oxedwndProjectStatistics.Open();
end;
{$ENDIF}

constructor oxedTProjectStatisticsWindow.Create();
begin
   Name := 'project_statistics';
   Title := 'Project Statistics';

   Instance := oxeduiTProjectStatisticsWindow;

   {$IFDEF OX_FEATURE_CONSOLE}
   if(console.Selected <> nil) then
      console.Selected^.AddCommand('wnd:project_statistics', @consoleCallback);
   {$ENDIF}

   inherited Create;
end;

procedure oxedTProjectStatisticsWindow.Open();
begin
   inherited Open;
end;

procedure init();
begin
   oxedwndProjectStatistics := oxedTProjectStatisticsWindow.Create();
end;

procedure deinit();
begin
   FreeObject(oxedwndProjectStatistics);
end;

INITIALIZATION
   oxed.Init.Add('oxed.statistics_window', @init, @deinit);

END.
