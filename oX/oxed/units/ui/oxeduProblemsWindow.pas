{
   oxeduProblemsWindow, problems window
   Copyright (C) 2018. Dejan Boras

   Started On:    30.08.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProblemsWindow;

INTERFACE

   USES
      sysutils, uStd, uColors,
      {app}
      appuMouse,
      {ox}
      oxuTypes, oxuRunRoutines, oxuScene, oxuPaths, oxuRender, oxuRenderer, oxuTimer, oxuFont,
      {ui}
      uiuControl, uiuTypes, uiuWindow, uiWidgets, wdguWorkbar, wdguToolbar, wdguList,
      {oxed}
      uOXED, oxeduSettings, oxeduWindow, oxeduMenubar, oxeduIcons, oxeduProblems,
      oxeduProjectRunner, oxeduProjectManagement;

TYPE

   { wdgTOXEDProblems }

   wdgTOXEDProblems = class(wdgTStringList)
      constructor Create; override;

      function GetValue(index: loopint): string; override;
      function GetItemCount: loopint; override;

      procedure RenderItem(index: loopint; r: oxTRect); override;

      procedure Update(); override;
      procedure Updated();
   end;

   { oxedTProblemsWindow }

   oxedTProblemsWindow = class(oxedTWindow)
      wdg: record
         Toolbar: wdgTToolbar;
         Problems: wdgTOXEDProblems;

         Clear,
         Copy: wdgPToolbarItem;
      end;

      procedure Initialize; override;

      procedure SizeChanged; override;
   end;

   { oxedTProblemsClass }

   oxedTProblemsWindowClass = class(oxedTWindowClass)
      constructor Create(const sName: string; InstanceType: oxedTUIWindowClass); override;

      procedure Update();
   end;

VAR
   oxedProblemsWindow: oxedTProblemsWindowClass;

IMPLEMENTATION

procedure openProblems();
begin
   oxedProblemsWindow.CreateWindow();
end;

procedure init();
begin
   oxedProblemsWindow := oxedTProblemsWindowClass.Create('Problems', oxedTProblemsWindow);
end;

procedure initMenubar();
begin
   oxedMenubar.OpenWindows.AddItem(oxedProblemsWindow.Name, @openProblems);
end;

procedure deinit();
begin
   FreeObject(oxedProblemsWindow);
end;

procedure clearProblems();
begin
   oxedProblems.Clear();

   oxedProblemsWindow.Update();
end;

procedure copyProblems();
begin
end;

{ wdgTOXEDProblems }

constructor wdgTOXEDProblems.Create;
begin
   inherited Create;

   PaddingLeft := 5;

   OddColored := true;
   Selectable := true;
end;

function wdgTOXEDProblems.GetValue(index: loopint): string;
begin
   result := TimeToStr(oxedProblems.con.contents.list[index].Time) + ' ' + oxedProblems.con.contents.list[index].Txt;
end;

function wdgTOXEDProblems.GetItemCount: loopint;
begin
   result := oxedProblems.con.contents.n;
end;

procedure wdgTOXEDProblems.RenderItem(index: loopint; r: oxTRect);
var
   clr: TColor4ub;

begin
   clr := oxedProblems.con.contents.list[index].Color;
   if(clr[3] > 0) then begin
      SetColorBlended(clr);

      oxf.GetSelected().WriteCentered(GetValue(index), r, [oxfpCenterVertical]);
   end;
end;

procedure wdgTOXEDProblems.Update;
begin
   if(oxedProblems.con.contents.n <> ItemCount) then
      Updated();
end;

procedure wdgTOXEDProblems.Updated();
begin
   ItemsChanged();
   EndItem();
end;

{ oxedTProblemsClass }

constructor oxedTProblemsWindowClass.Create(const sName: string; InstanceType: oxedTUIWindowClass);
begin
   inherited Create(sName, InstanceType);

   SingleInstance := true;
end;

procedure oxedTProblemsWindowClass.Update();
begin
   if(Instance <> nil) then
      oxedTProblemsWindow(Instance).wdg.Problems.Updated();
end;

{ oxedTProblemsWindow }

procedure oxedTProblemsWindow.Initialize;
begin
   inherited;

   Background.Typ := uiwBACKGROUND_NONE;

   wdg.Toolbar := wdgToolbar.Add(Self, true);
   wdg.Toolbar.ObscuresMaximization := uiCONTROL_MAXIMIZATION_OBSCURE_NONE;
   wdg.Toolbar.AutoPositionTarget := wdgWORKBAR_POSITION_LEFT;

   {setup problems list}
   uiWidget.Create.Instance := wdgTOXEDProblems;
   wdg.Problems := wdgTOXEDProblems(wdgStringList.Add(oxPoint(wdg.Toolbar.Dimensions.w, Dimensions.h - 1),
      oxDimensions(Dimensions.w - wdg.Toolbar.Dimensions.w, Dimensions.h)));
   wdg.Problems.OddColored := true;
   wdg.Problems.SetBorder(0);
   wdg.Problems.Load();

   {toolbar items}
   wdg.Clear := wdg.Toolbar.AddButton(oxedIcons.Create($f00d), 0, @clearProblems);
   wdg.Clear^.Hint := 'Clear all Problems';
   wdg.Clear^.Color.Assign(255, 64, 64, 255);

   wdg.Copy := wdg.Toolbar.AddButton(oxedIcons.Create($f0c5), 0, @copyProblems);
   wdg.Copy^.Hint := 'Copy selected Problems to clipboard';

   SizeChanged;
end;

procedure oxedTProblemsWindow.SizeChanged;
begin
   inherited;

   {place to the left}
   wdg.Problems.Move(wdg.Toolbar.Dimensions.w, Dimensions.h - 1);
   wdg.Problems.Resize(Dimensions.w - wdg.Toolbar.Dimensions.w, Dimensions.h);
end;

procedure onStart();
begin
end;

procedure onProjectClose();
begin
   oxedProblems.Clear();
end;

VAR
   oxedInitRoutines: oxTRunRoutine;

INITIALIZATION
   oxed.Init.Add(oxedInitRoutines, 'scene.Problems', @init, @deinit);
   oxedMenubar.OnInit.Add(@initMenubar);

   oxedProjectRunner.OnBeforeStart.Add(@onStart);
   oxedProjectManagement.OnProjectClosed.Add(@onProjectClose);

END.
