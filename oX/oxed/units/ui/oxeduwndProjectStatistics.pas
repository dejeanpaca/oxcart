{
   oxeduwndProjectStatistics, project statistics window
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduwndProjectStatistics;

INTERFACE

   USES
      uStd, StringUtils, uBinarySize,
      {oX}
      oxuTypes, oxuConsoleBackend,
      {wnd}
      oxuwndBase, oxuwndSettingsBase,
      {ui}
      uiuControl, uiuWidget, uiWidgets, uiuMessageBox, uiuTypes,
      {wdg}
      wdguButton, wdguDivisor, wdguLabel, wdguGrid,
      {oxed}
      uOXED, oxeduProject, oxeduProjectStatistics;

TYPE
   { oxeduiTProjectStatisticsWindow }

   oxeduiTProjectStatisticsWindow = class(oxuiTWindowBase)
   end;

   { oxedwdgTStatisticsGrid }

   oxedwdgTStatisticsGrid = class(wdgTStringGrid)
      function GetValue(index, column: loopint): StdString; override;
      function GetItemCount(): loopint; override;
   end;

   { oxedTProjectStatisticsWindow }

   oxedTProjectStatisticsWindow = object(oxTSettingsWindowBase)
      widgets: record
         Statistics: wdgTStringGrid;
         AddParameter,
         RemoveParameter: wdgTButton;
         Separator: wdgTDivisor;
      end;

      constructor Create();
      procedure Open(); virtual;

      protected
      procedure AddWidgets(); virtual;
   end;

VAR
   oxedwndProjectStatistics: oxedTProjectStatisticsWindow;

IMPLEMENTATION

procedure closeSettingsWindow();
begin
   oxedwndProjectStatistics.Close();
end;

{ oxedwdgTStatisticsGrid }

function oxedwdgTStatisticsGrid.GetValue(index, column: loopint): StdString;
begin
   if(column = 0) then
      Result := oxedProjectStatistics.FileTypes.List[index].Extension
   else if(column = 1) then
      Result := sf(oxedProjectStatistics.FileTypes.List[index].Count)
   else
      Result := getiecByteSizeHumanReadable(oxedProjectStatistics.FileTypes.List[index].TotalSize);
end;

function oxedwdgTStatisticsGrid.GetItemCount(): loopint;
begin
   Result := oxedProjectStatistics.FileTypes.n;
end;

{ oxedTProjectStatisticsWindow }

procedure oxedTProjectStatisticsWindow.AddWidgets();
begin
   inherited;

   AddCloseButton();
   widgets.Separator := wdgDivisor.Add('', uiWidget.LastRect.AboveOf());

   uiWidget.LastRect.Assign(Window);
   wdgLabel.Add('Files: ' + sf(oxedProjectStatistics.FileCount));
   wdgLabel.Add('Total size: ' + getiecByteSizeHumanReadable(oxedProjectStatistics.TotalSize));

   wdgDivisor.Add('');

   uiWidget.Create.Instance := oxedwdgTStatisticsGrid;

   widgets.Statistics := wdgStringGrid.Add(uiWidget.LastRect.BelowOf(),
      oxDimensions(Window.Dimensions.w - wdgDEFAULT_SPACING * 2, 200));

   widgets.Statistics.Selectable := true;
   widgets.Statistics.OddColored := true;

   widgets.Statistics.AddColumn('Extension')^.Ratio := 0.3;
   widgets.Statistics.AddColumn('Count')^.Ratio := 0.3;
   widgets.Statistics.AddColumn('Total size')^.Ratio := 0.4;

   widgets.Statistics.ComputeColumns();
   widgets.Statistics.Assigned();
end;

{$IFDEF OX_FEATURE_CONSOLE}
procedure consoleCallback({%H-}con: conPConsole);
begin
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
   oxedwndProjectStatistics.Create();
end;

procedure deinit();
begin
   oxedwndProjectStatistics.Destroy();
end;

INITIALIZATION
   oxed.Init.Add('oxed.statistics_window', @init, @deinit);

END.
