{
   oxeduMessagesWindow, messages window
   Copyright (C) 2017. Dejan Boras

   Started On:    04.02.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduMessagesWindow;

INTERFACE

   USES
      sysutils, uStd, uColors,
      {app}
      appuMouse,
      {ox}
      oxuTypes, oxuScene, oxuPaths, oxuFont, oxuRunRoutines,
      {ui}
      uiuControl, uiuTypes, uiuWindow, uiWidgets, wdguWorkbar, wdguToolbar, wdguList,
      {oxed}
      uOXED, oxeduSettings, oxeduWindow, oxeduMenubar, oxeduMessages, oxeduIcons,
      oxeduProjectRunner, oxeduProjectManagement;

TYPE

   { wdgTOXEDMessages }

   wdgTOXEDMessages = class(wdgTStringList)
      constructor Create; override;

      function GetValue(index: loopint): StdString; override;
      function GetItemCount: loopint; override;

      procedure RenderItem(index: loopint; r: oxTRect); override;

      procedure Update(); override;
      procedure Updated();
   end;

   { oxedTMessagesWindow }

   oxedTMessagesWindow = class(oxedTWindow)
      wdg: record
         Toolbar: wdgTToolbar;
         Messages: wdgTOXEDMessages;

         Clear,
         Copy,
         Logs: wdgPToolbarItem;
      end;

      procedure Initialize; override;

      procedure SizeChanged; override;
   end;

   { oxedTMessagesClass }

   oxedTMessagesClass = class(oxedTWindowClass)
      constructor Create(const sName: StdString; InstanceType: oxedTUIWindowClass); override;

      procedure Update();
   end;

VAR
   oxedMessagesWindow: oxedTMessagesClass;

IMPLEMENTATION

procedure openMessages();
begin
   oxedMessagesWindow.CreateWindow();
end;

procedure init();
begin
   oxedMessagesWindow := oxedTMessagesClass.Create('Messages', oxedTMessagesWindow);
end;

procedure initMenubar();
begin
   oxedMenubar.OpenWindows.AddItem(oxedMessagesWindow.Name, @openMessages);
end;

procedure deinit();
begin
   FreeObject(oxedMessagesWindow);
end;

procedure clearMessages();
begin
   oxedMessages.Clear();

   oxedMessagesWindow.Update();
end;

procedure copyMessages();
begin
end;

{ wdgTOXEDMessages }

constructor wdgTOXEDMessages.Create;
begin
   inherited Create;

   PaddingLeft := 5;

   OddColored := true;
   Selectable := true;
end;

function wdgTOXEDMessages.GetValue(index: loopint): StdString;
begin
   result := TimeToStr(oxedMessages.con.contents.list[index].Time) + ' ' + oxedMessages.con.contents.list[index].Txt;
end;

function wdgTOXEDMessages.GetItemCount: loopint;
begin
   result := oxedMessages.con.contents.n;
end;

procedure wdgTOXEDMessages.RenderItem(index: loopint; r: oxTRect);
var
   clr: TColor4ub;

begin
   clr := oxedMessages.con.contents.list[index].Color;
   if(clr[3] > 0) then begin
      SetColorBlended(clr);

      oxf.GetSelected().WriteCentered(GetValue(index), r, [oxfpCenterVertical]);
   end;
end;

procedure wdgTOXEDMessages.Update;
begin
   if(oxedMessages.con.contents.n <> ItemCount) then
      Updated();
end;

procedure wdgTOXEDMessages.Updated();
begin
   ItemsChanged();
   EndItem();
end;

{ oxedTMessagesClass }

constructor oxedTMessagesClass.Create(const sName: StdString; InstanceType: oxedTUIWindowClass);
begin
   inherited Create(sName, InstanceType);

   SingleInstance := true;
end;

procedure oxedTMessagesClass.Update();
begin
   if(Instance <> nil) then
      oxedTMessagesWindow(Instance).wdg.Messages.Updated();
end;

{ oxedTMessagesWindow }

procedure oxedTMessagesWindow.Initialize;
begin
   inherited;

   Background.Typ := uiwBACKGROUND_NONE;

   wdg.Toolbar := wdgToolbar.Add(Self, true);
   wdg.Toolbar.ObscuresMaximization := uiCONTROL_MAXIMIZATION_OBSCURE_NONE;
   wdg.Toolbar.AutoPositionTarget := wdgWORKBAR_POSITION_LEFT;

   {setup messages list}
   uiWidget.Create.Instance := wdgTOXEDMessages;
   wdg.Messages := wdgTOXEDMessages(wdgStringList.Add(oxPoint(wdg.Toolbar.Dimensions.w, Dimensions.h - 1),
      oxDimensions(Dimensions.w - wdg.Toolbar.Dimensions.w, Dimensions.h)));
   wdg.Messages.OddColored := true;
   wdg.Messages.SetBorder(0);
   wdg.Messages.Load();

   {toolbar items}
   wdg.Clear := wdg.Toolbar.AddButton(oxedIcons.Create($f00d), 0, @clearMessages);
   wdg.Clear^.Hint := 'Clear all messages';
   wdg.Clear^.Color.Assign(255, 64, 64, 255);

   wdg.Copy := wdg.Toolbar.AddButton(oxedIcons.Create($f0c5), 0, @copyMessages);
   wdg.Copy^.Hint := 'Copy selected messages to clipboard';

   wdg.Logs := wdg.Toolbar.AddButton(oxedIcons.Create($f03a), 0, @oxed.OpenLogs);
   wdg.Logs^.Hint := 'Open logs';

   SizeChanged;
end;

procedure oxedTMessagesWindow.SizeChanged;
begin
   inherited;

   {place to the left}
   wdg.Messages.Move(wdg.Toolbar.Dimensions.w, Dimensions.h - 1);
   wdg.Messages.Resize(Dimensions.w - wdg.Toolbar.Dimensions.w, Dimensions.h);
end;

procedure onStart();
begin
   if(oxedSettings.ClearMessagesOnStart) then
      oxedMessages.Clear();
end;

procedure onProjectClose();
begin
   oxedMessages.Clear();
end;

VAR
   oxedInitRoutines: oxTRunRoutine;

INITIALIZATION
   oxed.Init.Add(oxedInitRoutines, 'scene.messages', @init, @deinit);
   oxedMenubar.OnInit.Add(@initMenubar);

   oxedProjectRunner.OnBeforeStart.Add(@onStart);
   oxedProjectManagement.OnClosed.Add(@onProjectClose);

END.

