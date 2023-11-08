{
   oxuwndSettingsBase, oX settings window base mechanism
   Copyright (C) 2014. Dejan Boras

   Started On:    16.06.2014.
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndSettingsBase;

INTERFACE

USES
   {app}
   uStd,
   {oX}
   oxuTypes,
   {ui}
   uiuControl, uiuWindow, uiWidgets, uiuTypes, uiuWidget, uiuMessageBox,
   oxuwndBase,
   {widgets}
   wdguInputBox, wdguButton, wdguTabs;

TYPE
   oxTSettingsWindowStringFunction = function(): TAppendableString;
   oxTSettingsWindowStringFunctions = specialize TSimpleList<oxTSettingsWindowStringFunction>;

   { oxTSettingsWindowBase }

   oxTSettingsWindowBase = class(oxTWindowBase)
      Tabs: wdgTTabs;

      {list of procedures called when splash window is initialized}
      OnInit,
      PreAddTabs,
      OnAddTabs,
      PostAddTabs: TProcedures;

      DefaultButtonWidth: loopint;

      wdg: record
         Save,
         Cancel,
         RestoreDefaults,
         Revert: wdgTButton;
      end;

      OnSave,
      OnRevert,
      OnCancel: TProcedures;
      OnValidate: oxTSettingsWindowStringFunctions;

      constructor Create(); override;

      protected
      procedure CreateTabsWidget();
      procedure DoneTabs();
      procedure AddCancelSaveButtons();
      procedure AddRestoreDefaultsButton();
      procedure AddRevertButton();

      procedure CreateWindow(); override;

      procedure Save(); virtual;
      procedure Revert(); virtual;
      procedure Cancel(); virtual;
      function Validate(): TAppendableString; virtual;
   end;

IMPLEMENTATION

constructor oxTSettingsWindowBase.Create();
begin
   inherited;

   OnInit.InitializeValues(OnInit);
   PreAddTabs.InitializeValues(PreAddTabs);
   OnAddTabs.InitializeValues(OnAddTabs);
   PostAddTabs.InitializeValues(PostAddTabs);

   OnSave.InitializeValues(OnSave);
   OnRevert.InitializeValues(OnRevert);
   OnCancel.InitializeValues(OnCancel);
   OnValidate.InitializeValues(OnValidate);

   DefaultButtonWidth := 120;

   if(Title = '') then
      Title := 'Settings';
   if(Name = '') then
      Name := '';

   DoDestroy := true;

   if(Width = 0) then
      Width := 600;
   if(Height = 0) then
      Height := 400;

   if(ID.ID = 0) then
      ID := uiControl.GetID('ox.' + name);
end;

procedure oxTSettingsWindowBase.CreateTabsWidget();
var
   y: longint;

begin
   {add the label}
   y := Window.Dimensions.h - wdgDEFAULT_SPACING;

   Tabs := wdgTabs.Add(oxPoint(5, y), oxDimensions(Window.Dimensions.w - 10, Window.Dimensions.h - 40), true);

   PreAddTabs.Call();
   OnAddTabs.Call();
end;

procedure oxTSettingsWindowBase.DoneTabs();
begin
   PostAddTabs.Call();

   Tabs.Done();
end;

procedure oxTSettingsWindowBase.AddCancelSaveButtons();
var
   point: oxTPoint = (x: 0; y: 0);

begin
   wdg.Cancel := wdgButton.Add('Cancel', point, oxDimensions(DefaultButtonWidth, 0), @Cancel);
   wdg.Cancel.ResizeHeight(wdg.Cancel.GetComputedHeight());
   wdg.Cancel.SetPosition(wdgPOSITION_HORIZONTAL_RIGHT or wdgPOSITION_VERTICAL_BOTTOM);
   wdg.Cancel.Callback.Use(@Cancel);
   wdg.Cancel.SetButtonPosition([uiCONTROL_GRID_RIGHT]);

   wdg.Save := wdgButton.Add('Save', point, oxDimensions(DefaultButtonWidth, 0), @Save);
   wdg.Save.ResizeHeight(wdg.Save.GetComputedHeight());
   wdg.Save.SetButtonPosition([uiCONTROL_GRID_LEFT]);

   wdg.Save.Move(wdg.Cancel.LeftOf(0) - wdg.Save.Dimensions.w + 1, wdg.Cancel.Position.y);

   Include(wdg.Cancel.Properties, wdgpDEFAULT_ESCAPE);
   Include(wdg.Save.Properties, wdgpDEFAULT_CONFIRM);
end;

procedure oxTSettingsWindowBase.AddRestoreDefaultsButton();
var
   point: oxTPoint = (x: 0; y: 0);

begin
   if(wdg.Revert <> nil) then
      point.Assign(wdg.Revert.RightOf(), wdg.Revert.Position.y);

   wdg.RestoreDefaults := wdgButton.Add('Restore Defaults', point, oxNullDimensions, 0);

   if(wdg.Revert = nil) then
      wdg.RestoreDefaults.SetPosition(wdgPOSITION_HORIZONTAL_LEFT or wdgPOSITION_VERTICAL_BOTTOM);
end;

procedure oxTSettingsWindowBase.AddRevertButton();
var
   point: oxTPoint = (x: 0; y: 0);

begin
   if(wdg.RestoreDefaults <> nil) then
      point.Assign(wdg.RestoreDefaults.RightOf(), wdg.RestoreDefaults.Position.y);

   wdg.Revert := wdgButton.Add('Revert', point, oxNullDimensions, @Revert);

   if(wdg.RestoreDefaults = nil) then
      wdg.Revert.SetPosition(wdgPOSITION_HORIZONTAL_LEFT or wdgPOSITION_VERTICAL_BOTTOM);
end;

procedure oxTSettingsWindowBase.CreateWindow();
begin
   inherited;

   if(Window <> nil) then
      {call OnInit methods }
      OnInit.Call();

   Revert();
end;

procedure oxTSettingsWindowBase.Save();
var
   messages: TAppendableString;

begin
   messages := Validate();

   if(messages = '') then begin
      OnSave.Call();
      Close();
   end else
      uiMessageBox.Show(Title, 'Errors in settings: ' + #13 + messages, uimbsWARNING, uimbcOK);
end;

procedure oxTSettingsWindowBase.Revert();
begin
   OnRevert.Call();
end;

procedure oxTSettingsWindowBase.Cancel();
begin
   OnCancel.Call();
   Close();
end;

function oxTSettingsWindowBase.Validate(): TAppendableString;
var
   i: loopint;
   current: TAppendableString;

begin
   Result := '';

   for i := 0 to OnValidate.n - 1 do begin
      current := OnValidate.List[i]();

      if(current <> '') then
         Result.Add(current);
   end;
end;

END.
