{
   oxeduwndConsole, console window
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduwndConsole;

INTERFACE

   USES
      sysutils, uStd, uColors,
      {ox}
      oxuTypes, oxuFont,
      {ui}
      uiuControl, uiuTypes, uiuSkin, uiuWindow,
      uiWidgets, wdguWorkbar, wdguToolbar, wdguList,
      {oxed}
      uOXED, oxeduSettings, oxeduWindow, oxeduMenubar, oxeduConsole, oxeduIcons,
      oxeduProjectRunner, oxeduProjectManagement, oxeduBuild;

TYPE

   { wdgTOXEDConsole }

   wdgTOXEDConsole = class(wdgTStringList)
      constructor Create; override;

      function GetValue(index: loopint): StdString; override;
      function GetItemCount: loopint; override;

      procedure RenderItem(index: loopint; r: oxTRect); override;

      procedure Update(); override;
      procedure Updated();
   end;

   { oxedTConsoleWindow }

   oxedTConsoleWindow = class(oxedTWindow)
      wdg: record
         Toolbar: wdgTToolbar;
         Console: wdgTOXEDConsole;

         Clear,
         Copy,
         Logs: wdgPToolbarItem;
      end;

      procedure Initialize; override;

      procedure SizeChanged; override;
   end;

   { oxedTConsoleClass }

   oxedTConsoleClass = class(oxedTWindowClass)
      constructor Create(const sName: StdString; InstanceType: oxedTUIWindowClass); override;

      procedure Update();
   end;

VAR
   oxedConsoleWindow: oxedTConsoleClass;

IMPLEMENTATION

procedure openConsole();
begin
   oxedConsoleWindow.CreateWindow();
end;

procedure init();
begin
   oxedConsoleWindow := oxedTConsoleClass.Create('Console', oxedTConsoleWindow);
end;

procedure initMenubar();
begin
   oxedMenubar.OpenWindows.AddItem(oxedConsoleWindow.Name, @openConsole);
end;

procedure deinit();
begin
   FreeObject(oxedConsoleWindow);
end;

procedure clearConsole();
begin
   oxedConsole.Clear();

   oxedConsoleWindow.Update();
end;

procedure copyConsole();
begin
end;

{ wdgTOXEDConsole }

constructor wdgTOXEDConsole.Create;
begin
   inherited Create;

   PaddingLeft := 5;

   OddColored := true;
   Selectable := true;
end;

function wdgTOXEDConsole.GetValue(index: loopint): StdString;
begin
   result := TimeToStr(oxedConsole.con.Contents.List[index].Time) + ' ' + oxedConsole.con.Contents.List[index].Txt;
end;

function wdgTOXEDConsole.GetItemCount: loopint;
begin
   result := oxedConsole.con.Contents.n;
end;

procedure wdgTOXEDConsole.RenderItem(index: loopint; r: oxTRect);
var
   clr: TColor4ub;

begin
   clr := oxedConsole.con.Contents.List[index].Color;
   if(clr[3] > 0) then begin
      SetColorBlended(clr);

      oxf.GetSelected().WriteCentered(GetValue(index), r, [oxfpCenterVertical]);
   end;
end;

procedure wdgTOXEDConsole.Update;
begin
   if(oxedConsole.con.Contents.n <> ItemCount) then
      Updated();
end;

procedure wdgTOXEDConsole.Updated();
begin
   ItemsChanged();
   EndItem();
end;

{ oxedTConsoleClass }

constructor oxedTConsoleClass.Create(const sName: StdString; InstanceType: oxedTUIWindowClass);
begin
   inherited Create(sName, InstanceType);

   SingleInstance := true;
end;

procedure oxedTConsoleClass.Update();
begin
   if(Instance <> nil) then
      oxedTConsoleWindow(Instance).wdg.Console.Updated();
end;

{ oxedTConsoleWindow }

procedure oxedTConsoleWindow.Initialize;
begin
   inherited;

   Background.Typ := uiwBACKGROUND_NONE;

   wdg.Toolbar := wdgToolbar.Add(Self, true);
   wdg.Toolbar.ObscuresMaximization := uiCONTROL_MAXIMIZATION_OBSCURE_NONE;
   wdg.Toolbar.AutoPositionTarget := wdgWORKBAR_POSITION_LEFT;

   {setup console list}
   uiWidget.Create.Instance := wdgTOXEDConsole;
   wdg.Console := wdgTOXEDConsole(wdgStringList.Add(oxPoint(wdg.Toolbar.Dimensions.w, Dimensions.h - 1),
      oxDimensions(Dimensions.w - wdg.Toolbar.Dimensions.w, Dimensions.h)));
   wdg.Console.OddColored := true;
   wdg.Console.SetBorder(0);
   wdg.Console.Load();

   {toolbar items}
   wdg.Clear := wdg.Toolbar.AddButton(oxedIcons.Create($f00d), 0, @clearConsole);
   wdg.Clear^.Hint := 'Clear all';
   wdg.Clear^.Color := uiSkin.StandardSkin.Colors.Delete;
   wdg.Clear^.Color.Assign(255, 64, 64, 255);

   wdg.Copy := wdg.Toolbar.AddButton(oxedIcons.Create($f0c5), 0, @copyConsole);
   wdg.Copy^.Hint := 'Copy selected logs to clipboard';

   wdg.Logs := wdg.Toolbar.AddButton(oxedIcons.Create($f03a), 0, @oxed.OpenLogs);
   wdg.Logs^.Hint := 'Open logs';

   SizeChanged;
end;

procedure oxedTConsoleWindow.SizeChanged;
begin
   inherited;

   {place to the left}
   wdg.Console.Move(wdg.Toolbar.Dimensions.w, Dimensions.h - 1);
   wdg.Console.Resize(Dimensions.w - wdg.Toolbar.Dimensions.w, Dimensions.h);
end;

procedure onStart();
begin
   if(oxedSettings.ClearConsoleOnStart) then
      oxedConsole.Clear();
end;

procedure onProjectClose();
begin
   oxedConsole.Clear();
end;

procedure onBuild();
begin
   if(oxedSettings.FocusConsoleOnBuild) and (oxedConsoleWindow.Instance <> nil) then
      oxedConsoleWindow.Instance.Select();
end;

INITIALIZATION
   oxed.Init.Add('oxed.console_window', @init, @deinit);
   oxedMenubar.OnInit.Add(@initMenubar);

   oxedProjectRunner.OnBeforeStart.Add(@onStart);
   oxedProjectManagement.OnClosed.Add(@onProjectClose);

   oxedBuild.OnPrepare.Add(@onBuild);

END.

