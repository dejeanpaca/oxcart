{
   oxeduwndPackagesSettings, packages settings windows
   Copyright (C) 2020. Dejan Boras

   Started On:    06.02.2020.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduwndPackagesSettings;

INTERFACE

   USES
      {app}
      uStd,
      {oX}
      oxuRunRoutines, oxuTypes,
      {ui}
      uiuWindow, uiWidgets, uiuControl, uiuWidget,
      {widgets}
      wdguLabel, wdguButton, wdguTabs, wdguCheckboxHierarchy,
      {oxed}
      uOXED, oxeduProject, oxeduProjectPackages,
      oxeduProjectSettingsWindow;

TYPE
   { oxedwdgTPackagesList }

   oxedwdgTPackagesList = class(wdgTCheckboxHierarchy)
      function GetValue(index: loopint): StdString; override;
      function GetSubItems({%H-}index: loopint; ref: pointer): TSimplePointerList; override;
      function Expandable({%H-}index: loopint): boolean; override;
      function IsChecked({%H-}ref: pointer): boolean; override;
   end;


IMPLEMENTATION

VAR
   wdg: record
      List: oxedwdgTPackagesList;
   end;

function validateCallback(): TAppendableString;
begin
   Result := '';
end;


procedure revertCallback();
begin
end;

procedure saveCallback();
begin
end;

procedure addPath();
begin

end;

procedure removePackage();
begin

end;

procedure removeAll();
begin

end;

{ oxedTSettingsWindow }

procedure Initialize();
var
   tabs: wdgTTabs;

begin
   tabs := oxedwndProjectSettings.Tabs;

   tabs.AddTab('Packages', 'packages');

   // TODO: Add Widgets
   wdgLabel.Add('Packages');

   wdgButton.Add('Add Path').
      UseCallback(@addPath).SetHint('Include a directory as a package');

   wdgButton.Add('Remove', uiWidget.LastRect.RightOf(), oxNullDimensions, @removePackage).SetHint('Remove the package selected in the list');
   wdgButton.Add('Remove All', uiWidget.LastRect.RightOf(), oxNullDimensions, @removeAll).SetHint('Remove all packages from the list');

   uiWidget.LastRect.GoLeft();

   uiWidget.Create.Instance := oxedwdgTPackagesList;
   wdg.List := oxedwdgTPackagesList(wdgCheckboxHierarchy.Add());
   wdg.List.Load();

   wdg.List.Resize(tabs.Container.Dimensions.w - wdgDEFAULT_SPACING, wdg.List.Position.y - wdgDEFAULT_SPACING * 2);

   revertCallback();
end;

procedure init();
begin
   oxedwndProjectSettings.PostAddTabs.Add(@Initialize);
   oxedwndProjectSettings.OnSave.Add(@saveCallback);
   oxedwndProjectSettings.OnRevert.Add(@revertCallback);
   oxedwndProjectSettings.OnValidate.Add(@validateCallback);
end;

{ oxedwdgTPackagesList }

function oxedwdgTPackagesList.GetValue(index: loopint): StdString;
begin
   Result := oxedProject.Packages.List[index].GetDisplayName();
end;

function oxedwdgTPackagesList.GetSubItems(index: loopint; ref: pointer): TSimplePointerList;
var
   i: loopint;

begin
   Result.Initialize(Result);

   if(ref = nil) then begin
     Result.a := oxedProject.Packages.n;
     Result.n := Result.a;

      if(Result.n > 0) then begin
        SetLength(Result.List, Result.n);

        for i := 0 to (Result.n - 1) do
           Result.List[i] := @oxedProject.Packages.List[i];
      end;
   end;
end;

function oxedwdgTPackagesList.Expandable(index: loopint): boolean;
begin
   {NOTE: We don't have subpackages for now}
   Result := false;
end;

function oxedwdgTPackagesList.IsChecked(ref: pointer): boolean;
begin
   {NOTE: We can't enable/disable packages for now}
   Result := true;
end;

INITIALIZATION
   oxed.Init.Add('oxed.packages_settings_window', @init);

END.
