{
   oxeduProjectBrowser, project browser window
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectBrowser;

INTERFACE

   USES
      uStd,
      {app}
      appuMouse, appuKeys, uApp,
      {ox}
      oxuTypes,
      {ui}
      uiuControl, uiuWindow, uiWidgets, uiuWidgetWindow,
      wdguToolbar, wdguFileList, wdguLabel, wdguInputBox, wdguDivisor, oxuwndFileContextMenu,
      oxuFilePreviewWindow,
      {oxed}
      uOXED, oxeduWindow, oxeduMenubar, oxeduIcons,
      oxeduProjectContextMenu, oxeduProject, oxeduProjectManagement;

TYPE
   { wdgTOXEDProjectBrowserNavigate }

   wdgTOXEDProjectBrowserNavigate = class(wdgTHierarchicalFileList)
      FileBrowser: wdgTFileGrid;

      procedure ItemNavigated(index: loopint); override;
      procedure ItemClicked(index: loopint; button: TBitSet = appmcLEFT); override;
      procedure OnLoad; override;
   end;

   { wdgTOXEDProjectBrowserFiles }

   wdgTOXEDProjectBrowserFiles = class(wdgTFileGrid)
      FileNavigate: wdgTOXEDProjectBrowserNavigate;

      function Key(var k: appTKeyEvent): boolean; override;

      procedure FileDoubleClicked(index: loopint; button: TBitSet); override;
      procedure FileClicked(index: loopint; button: TBitSet = appmcLEFT); override;
   end;

   { oxedTProjectBrowserWindow }

   oxedTProjectBrowserWindow = class(oxedTWindow)
      wdg: record
         Workbar: wdgTToolbar;
         Separator: wdgTDivisor;
         Search: wdgTInputBox;
         Navigation: wdgTOXEDProjectBrowserNavigate;
         Files: wdgTOXEDProjectBrowserFiles;
         FilePath: wdgTLabel;
      end;

      procedure Initialize(); override;
      procedure SizeChanged(); override;
      procedure ParentSizeChange(); override;
      procedure SetupWidgets();
   end;

   { oxedTProjectBrowserClass }

   oxedTProjectBrowserClass = class(oxedTWindowClass)
      constructor Create(const sName: StdString; InstanceType: oxedTUIWindowClass); override;
      procedure WindowCreated({%H-}wnd: oxedTWindow); override;
   end;

VAR
   oxedProjectBrowser: oxedTProjectBrowserClass;

IMPLEMENTATION

VAR
   suppressChange: boolean;

procedure openContext(wdg: wdgTOXEDProjectBrowserFiles; var origin: uiTWidgetWindowOrigin; fileIndex: loopint);
begin
   oxedProjectContextMenu.Parameters.IsDirectory := false;
   oxedProjectContextMenu.Browser := wdg;
   oxedProjectContextMenu.Hierarchy := wdg.FileNavigate;

   if(fileIndex > -1) then begin
      oxedProjectContextMenu.Parameters.Target := uiFILE_CONTEXT_MENU_TARGET_SPECIFIC;
      oxedProjectContextMenu.Parameters.TargetPath := oxedProject.Path + wdg.CurrentPath + wdg.Files.List[fileIndex].Name;

      oxedProjectContextMenu.OpenMenu(origin);
   end else begin
      oxedProjectContextMenu.Parameters.Target := uiFILE_CONTEXT_MENU_TARGET_HERE;
      oxedProjectContextMenu.Parameters.TargetPath := oxedProject.Path + wdg.CurrentPath;

      oxedProjectContextMenu.OpenMenu(origin);
   end;
end;

{ wdgTOXEDProjectBrowserFiles }

function wdgTOXEDProjectBrowserFiles.Key(var k: appTKeyEvent): boolean;
begin
   if(k.Key.Equal(kcSPACE, 0)) then begin
      if(LastGridItemUnderPointer > -1) and (k.Key.Released()) then
         oxFilePreviewWindow.Show(GetFilePath(LastGridItemUnderPointer));

      Result := true;
   end else  if(k.Key.Equal(kcF2)) then begin
      {TODO: Rename file}
   end else
      Result := inherited Key(k);
end;

procedure wdgTOXEDProjectBrowserFiles.FileDoubleClicked(index: loopint; button: TBitSet);
begin
   {open file or directory}
   if(index > -1) and (button = appmcLEFT) then begin
      if(Files.List[index].IsDirectory()) then
         inherited FileDoubleClicked(index, button)
      else
         app.OpenLink(GetFilePath(index));
   end;
end;

procedure wdgTOXEDProjectBrowserFiles.FileClicked(index: loopint; button: TBitSet);
var
   origin: uiTWidgetWindowOrigin;

begin
   if(button <> appmcRIGHT) then begin
      inherited FileClicked(index, button);
      exit;
   end;

   origin.Initialize(origin);

   origin.SetControl(Self);
   openContext(Self, origin, index);
end;

{ wdgTProjectBrowserNavigate }

procedure wdgTOXEDProjectBrowserNavigate.ItemNavigated(index: loopint);
var
   givenPath: StdString;

begin
   if(FileBrowser <> nil) and (index > -1) then begin
      suppressChange := true;

      if(index <> 0) then begin
         if(Files.List[index].IsDirectory()) then begin
            givenPath := GetPath(index);

            FileBrowser.FindAll(givenPath);
         end;
      end else begin
         FileBrowser.LoadCurrentEmpty();
      end;
   end;
end;

procedure wdgTOXEDProjectBrowserNavigate.ItemClicked(index: loopint; button: TBitSet);
var
   origin: uiTWidgetWindowOrigin;

begin
   if(button <> appmcRIGHT) then
      exit;

   origin.SetPoint(GetAbsolutePointer(LastPointerPosition), Self);

   oxedProjectContextMenu.Parameters.IsDirectory := true;
   oxedProjectContextMenu.Browser := FileBrowser;
   oxedProjectContextMenu.Hierarchy := Self;
   oxedProjectContextMenu.Parameters.AllowCreateDirectory := true;

   if(index > 0) then begin
      oxedProjectContextMenu.Parameters.Target := uiFILE_CONTEXT_MENU_TARGET_SPECIFIC;
      oxedProjectContextMenu.Parameters.TargetPath := GetPath(index);

      oxedProjectContextMenu.OpenMenu(origin);
   end else begin
      oxedProjectContextMenu.Parameters.Target := uiFILE_CONTEXT_MENU_TARGET_HERE;
      oxedProjectContextMenu.Parameters.TargetPath := Path;

      oxedProjectContextMenu.OpenMenu(origin);
   end;
end;

procedure wdgTOXEDProjectBrowserNavigate.OnLoad;
begin
   inherited OnLoad;

   if(FileBrowser <> nil) then
      FileBrowser.FindAll(Path);
end;

procedure pathChange();
var
   wnd: oxedTProjectBrowserWindow;

begin
   wnd := oxedTProjectBrowserWindow(oxedProjectBrowser.Instance);

   if(wnd <> nil) and (oxedProjectValid()) then begin
      if(wnd.wdg.Files.CurrentPath <> oxedProject.Path) then
         wnd.wdg.FilePath.SetCaption(wnd.wdg.Files.CurrentPath)
      else
         wnd.wdg.FilePath.SetCaption('');

      wnd.wdg.FilePath.AutoSize();

      if(not suppressChange) then
         wnd.wdg.Navigation.ExpandPath(wnd.wdg.Files.CurrentPath)
      else
         suppressChange := false;
   end;
end;

procedure openProjectBrowser();
begin
   oxedProjectBrowser.CreateWindow();
end;

procedure init();
begin
   oxedProjectBrowser := oxedTProjectBrowserClass.Create('Project', oxedTProjectBrowserWindow);
end;

procedure initMenubar();
begin
   oxedMenubar.OpenWindows.AddItem(oxedProjectBrowser.Name, @openProjectBrowser);
end;

procedure deinit();
begin
   FreeObject(oxedProjectBrowser);
end;

{ oxedTProjectBrowserClass }

constructor oxedTProjectBrowserClass.Create(const sName: StdString; InstanceType: oxedTUIWindowClass);
begin
   inherited Create(sName, InstanceType);

   SingleInstance := true;
end;

procedure oxedTProjectBrowserClass.WindowCreated(wnd: oxedTWindow);
begin
   pathChange();
end;

{ oxedTProjectBrowserWindow }

procedure oxedTProjectBrowserWindow.Initialize();
begin
   inherited;

   wdg.Workbar := wdgToolbar.Add(Self);
   wdg.Workbar.ObscuresMaximization := uiCONTROL_MAXIMIZATION_OBSCURE_NONE;

   uiWidget.Create.Instance := wdgTOXEDProjectBrowserNavigate;
   wdg.Navigation := wdgTOXEDProjectBrowserNavigate(wdgHierarchicalFileList.Add(oxNullPoint, oxNullDimensions));
   wdg.Navigation.Selectable := true;
   wdg.Navigation.Pattern := '*';
   wdg.Navigation.IncludeParentDirectoryLink := false;
   wdg.Navigation.DirectoriesOnly := true;
   wdg.Navigation.SetBorder(1);
   wdg.Navigation.RootFile := 'Project';

   wdg.Separator := wdgDivisor.Add('', oxNullPoint, true);
   wdg.Separator.NoAutomaticSizing := true;

   wdg.FilePath := wdgLabel.Add('Path', oxNullPoint, oxNullDimensions);
   wdg.FilePath.SetPadding(4);

   uiWidget.Create.Instance := wdgTOXEDProjectBrowserFiles;
   wdg.Files := wdgTOXEDProjectBrowserFiles(wdgFileGrid.Add(oxNullPoint, oxNullDimensions));
   wdg.Files.Callbacks.PathChange := @pathChange;
   wdg.Files.OddColored := true;
   wdg.Files.SetBorder(1);

   wdg.Navigation.FileBrowser := wdg.Files;
   wdg.Files.FileNavigate := wdg.Navigation;

   if(oxedProjectValid()) then begin
      wdg.Navigation.LoadCurrentEmpty();
      wdg.Files.LoadCurrentEmpty();
   end;

   wdg.Workbar.SetTarget();

   wdg.Search := wdgInputBox.Add('', oxNullPoint, oxNullDimensions);
   wdg.Search.SetBorder(0);
   wdg.Search.SetPlaceholder('Search');
end;

procedure oxedTProjectBrowserWindow.SizeChanged();
begin
   inherited SizeChanged;

   SetupWidgets();
end;

procedure oxedTProjectBrowserWindow.ParentSizeChange();
begin
   inherited ParentSizeChange;

   SetupWidgets();
end;

procedure oxedTProjectBrowserWindow.SetupWidgets();
begin
   {place to the left}
   wdg.Workbar.AutoPosition();

   wdg.Navigation.Move(0, wdg.Workbar.BelowOf(0));
   wdg.Navigation.Resize(Dimensions.w div 5, wdg.Workbar.RemainingHeight());

   wdg.Separator.Move(wdg.Navigation.RightOf(0), wdg.Workbar.BelowOf(0));
   wdg.Separator.Resize(5, wdg.Workbar.RemainingHeight());
   wdg.Separator.SetHorizontalPadding(2);
   wdg.Separator.SetVerticalPadding(2);

   wdg.FilePath.Move(wdg.Separator.RightOf(0), wdg.Workbar.BelowOf(0));
   wdg.FilePath.AutoSize();

   wdg.Files.Move(wdg.Separator.RightOf(0), wdg.FilePath.BelowOf(0));
   wdg.Files.Resize(wdg.Separator.RemainingWidth(), wdg.FilePath.RemainingHeight());

   wdg.Search.Resize(wdg.Workbar.Dimensions.w div 2, wdg.Workbar.Dimensions.h);
   wdg.Search.CenterVertically().MoveRightmost(0);
end;

procedure projectOpen();
var
   wnd: oxedTProjectBrowserWindow;

begin
   wnd := oxedTProjectBrowserWindow(oxedProjectBrowser.Instance);

   if(wnd <> nil) and (oxedProject.Path <> '') then begin
      wnd.wdg.Navigation.RemoveAll();
      wnd.wdg.Navigation.LoadCurrentEmpty();
      wnd.wdg.Files.LoadCurrentEmpty();
   end;
end;

procedure projectClose();
var
   wnd: oxedTProjectBrowserWindow;

begin
   wnd := oxedTProjectBrowserWindow(oxedProjectBrowser.Instance);

   if(wnd <> nil) then begin
      wnd.wdg.Navigation.RemoveAll();
      wnd.wdg.Files.RemoveAll();
      wnd.wdg.FilePath.SetCaption('');
   end;
end;

INITIALIZATION
   oxed.Init.Add('scene.projectbrowser', @init, @deinit);
   oxedMenubar.OnInit.Add(@initMenubar);

   oxedProjectManagement.OnOpen.Add(@projectOpen);
   oxedProjectManagement.OnNew.Add(@projectClose);
   oxedProjectManagement.OnClosed.Add(@projectClose);
   oxedProjectManagement.OnSaved.Add(@projectOpen);

END.
