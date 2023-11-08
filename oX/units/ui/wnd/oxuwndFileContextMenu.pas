{
   oxuwndFileContextMenu, generic file context menu
   Copyright (C) 2011. Dejan Boras

   Started On:    27.01.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndFileContextMenu;

INTERFACE

   USES
      sysutils, uStd, StringUtils, uFileUtils,
      {app}
      uApp, appuEvents, appuActionEvents,
      {ox}
      oxuRunRoutines,
      {ui}
      oxuUI,  uiuTypes, uiuWidget, uiuContextMenu, uiuWidgetWindow, uiuMessageBox, uiuFiles;

TYPE
   uiTFileContextMenuTarget = (
      uiFILE_CONTEXT_MENU_TARGET_SPECIFIC,
      uiFILE_CONTEXT_MENU_TARGET_HERE
   );

   uiTFileContextMenuCallback = procedure(const parameters);
   uiTFileContextMenuObjectCallback = procedure(const parameters) of object;

   { uiTFileContextMenuParameters }

   uiTFileContextMenuParameters = record
      Target: uiTFileContextMenuTarget;
      TargetPath: StdString;
      IsDirectory,
      {allow the create directory options in any case}
      AllowCreateDirectory: boolean;
      OnDone: uiTWidgetCallback;
      OnDoneExt: uiTFileContextMenuCallback;
      OnDoneExtObj: uiTFileContextMenuObjectCallback;

      procedure OnDoneCall();
   end;

   { uiTFileContextMenuWindow }

   uiTFileContextMenuWindow = class(uiTContextMenuWindow)
      Parameters: uiTFileContextMenuParameters;
   end;

   uiTFileContextMenuWindowClass = class of uiTFileContextMenuWindow;

   { oxwndTFileContextMenu }

   oxwndTFileContextMenu = record
      {the menu to open by default}
      OpenMenu: uiTContextMenu;
      {the file context menu}
      Menu: uiTContextMenu;

      Events: record
         NONE,
         SHOW_IN_FILE_MANAGER,
         OPEN_FILE,
         RENAME_FILE,
         DELETE_FILE,
         CREATE_DIRECTORY: TEventID;
      end;

      Parameters: uiTFileContextMenuParameters;
      LastAction: TEventID;

      procedure Prepare(const pTargetPath: StdString = ''; pTarget: uiTFileContextMenuTarget = uiFILE_CONTEXT_MENU_TARGET_SPECIFIC);

      function Open(const from: uiTWidgetWindowOrigin; Instance: uiTFileContextMenuWindowClass = nil): uiTFileContextMenuWindow;
      procedure SetupItems(m: uiTContextMenu);

      procedure Initialize();
   end;

   uiTFileContextMenuMessageBoxWindow = class(uiTMessageBoxWindow)
      Parameters: uiTFileContextMenuParameters;
   end;

VAR
   oxwndFileContextMenu: oxwndTFileContextMenu;

IMPLEMENTATION

procedure init();
begin
   oxwndFileContextMenu.Initialize();
end;

procedure deinit();
begin
   FreeObject(oxwndFileContextMenu.Menu);
end;

{ uiTFileContextMenuParameters }

procedure uiTFileContextMenuParameters.OnDoneCall();
begin
   OnDone.Call();

   if(OnDoneExt <> nil) then
      OnDoneExt(self);

   if(OnDoneExtObj <> nil) then
      OnDoneExtObj(self);
end;

{ oxwndTFileContextMenu }

procedure oxwndTFileContextMenu.Prepare(const pTargetPath: StdString; pTarget: uiTFileContextMenuTarget);
begin
   Parameters.Target := pTarget;
   Parameters.TargetPath := pTargetPath;
   Parameters.IsDirectory := DirectoryExists(Parameters.TargetPath);
   Parameters.AllowCreateDirectory := false;
end;

function oxwndTFileContextMenu.Open(const from: uiTWidgetWindowOrigin; Instance: uiTFileContextMenuWindowClass): uiTFileContextMenuWindow;
var
   item: uiPContextMenuItem;
   m: uiTContextMenu;
   enable: boolean;

begin
   LastAction := Events.NONE;

   if(OpenMenu = nil) then
      m := Menu
   else
      m := OpenMenu;

   enable := Parameters.Target <> uiFILE_CONTEXT_MENU_TARGET_HERE;

   item := m.FindByAction(Events.OPEN_FILE);
   if(item <> nil) then
      item^.Enable(enable);

   item := m.FindByAction(Events.RENAME_FILE);
   if(item <> nil) then
      item^.Enable(enable);

   item := m.FindByAction(Events.DELETE_FILE);
   if(item <> nil) then
      item^.Enable(enable);

   item := m.FindByAction(Events.CREATE_DIRECTORY);
   if(item <> nil) then
      item^.Enable((not enable) or Parameters.AllowCreateDirectory);

   if(Instance = nil) then
      Instance := uiTFileContextMenuWindow;

   uiContextMenu.Instance := Instance;
   m.Show(from);

   Result := uiTFileContextMenuWindow(uiContextMenu.LastWindow);
   if(Result <> nil) then begin
      Result.Parameters.Target := Parameters.Target;
      Result.Parameters.TargetPath := Parameters.TargetPath;
      Result.Parameters.IsDirectory := Parameters.IsDirectory;
      Result.Parameters.OnDone := Parameters.OnDone;
   end;

   Parameters.OnDone.Clear();
end;

function getWindow(wdg: uiTWidget): uiTFileContextMenuWindow;
begin
   Result := uiTFileContextMenuWindow(wdg.wnd);
end;

procedure showInFileManager(wdg: uiTWidget; menu{%H-}: TObject; item{%H-}: uiPContextMenuItem);
var
   wnd: uiTFileContextMenuWindow;
   path: StdString;

begin
   wnd := getWindow(wdg);

   if(not wnd.Parameters.IsDirectory) then
      path := ExtractFilePath(wnd.Parameters.TargetPath)
   else
      path := wnd.Parameters.TargetPath;

   if(path = '') then
      path := GetCurrentDir();

   app.OpenFileManager(path);

   oxwndFileContextMenu.LastAction := oxwndFileContextMenu.Events.SHOW_IN_FILE_MANAGER;
   wnd.Parameters.OnDoneCall();
end;

procedure openFile(wdg: uiTWidget; menu{%H-}: TObject; item{%H-}: uiPContextMenuItem);
var
   wnd: uiTFileContextMenuWindow;

begin
   wnd := getWindow(wdg);

   app.OpenLink(wnd.Parameters.TargetPath);

   oxwndFileContextMenu.LastAction := oxwndFileContextMenu.Events.OPEN_FILE;
   wnd.Parameters.OnDone.Call(wdg);
end;

procedure mbRenameNotify(var mb: uiTMessageBoxData);
var
   path: StdString;
   wnd: uiTFileContextMenuMessageBoxWindow;

begin
   if(mb.Button = uimbcOK) and (mb.What = uimbcWHAT_BUTTON) then begin
      wnd := uiTFileContextMenuMessageBoxWindow(mb.Window);

      if(mb.Input <> '') then begin
         if(wnd.Parameters.IsDirectory) then
            path := ExcludeTrailingPathDelimiter(wnd.Parameters.TargetPath)
         else
            path := wnd.Parameters.TargetPath;

         path := IncludeTrailingPathDelimiterNonEmpty(ExtractFilePath(path));

         RenameFile(wnd.Parameters.TargetPath, path + mb.Input);

         oxwndFileContextMenu.LastAction := oxwndFileContextMenu.Events.RENAME_FILE;
         wnd.Parameters.OnDone.Call();
      end;
   end;
end;

procedure renameFile(wdg: uiTWidget; menu{%H-}: TObject; item{%H-}: uiPContextMenuItem);
var
   wnd: uiTFileContextMenuWindow;
   mbWindow: uiTMessageBoxWindow;
   fn: StdString;

begin
   wnd := getWindow(wdg);

   if(not wnd.Parameters.IsDirectory) then
      fn := ExtractFileName(wnd.Parameters.TargetPath)
   else
      fn := ExtractFileName(StdString(ExcludeTrailingPathDelimiter(wnd.Parameters.TargetPath)));

   if(fn <> '') then begin
      uiMessageBox.WindowType := uiTFileContextMenuMessageBoxWindow;
      mbWindow := uiMessageBox.ShowInput('Enter new filename', 'Enter new file name: ', @mbRenameNotify);
      uiTFileContextMenuMessageBoxWindow(mbWindow).Parameters := wnd.Parameters;
      mbWindow.MessageBox.wdg.Input.SetText(fn);
   end;
end;

procedure deleteFile(wdg: uiTWidget; menu{%H-}: TObject; item{%H-}: uiPContextMenuItem);
var
   wnd: uiTFileContextMenuWindow;
   ok: boolean;

begin
   wnd := getWindow(wdg);

   if(wnd.Parameters.IsDirectory) then
      ok := FileUtils.RmDir(wnd.Parameters.TargetPath)
   else
      ok := FileUtils.Erase(wnd.Parameters.TargetPath);

   if(ok) then begin
      oxwndFileContextMenu.LastAction := oxwndFileContextMenu.Events.DELETE_FILE;
      wnd.Parameters.OnDone.Call(wdg);
   end else
      uiMessageBox.Show('Failed to delete', 'Failed to delete target: ' + wnd.Parameters.TargetPath, uimbsCRITICAL, uimbcOK);
end;

procedure mbCreateDirectoryNotify(var mb: uiTMessageBoxData);
var
   path: StdString;
   wnd: uiTFileContextMenuMessageBoxWindow;

begin
   if(mb.Input <> '') and (mb.What = uimbcWHAT_BUTTON) and (mb.Button = uimbcOK) then begin
      wnd := uiTFileContextMenuMessageBoxWindow(mb.Window);
      path := wnd.Parameters.TargetPath;

      if(path <> '') then
         path := IncludeTrailingPathDelimiter(path);

      path := path + mb.Input;

      if(CreateDir(path)) then begin
         oxwndFileContextMenu.LastAction := oxwndFileContextMenu.Events.CREATE_DIRECTORY;
         wnd.Parameters.OnDone.Call();
      end else
         uiMessageBox.ShowWarning('Faile to create directory', 'Failed to create directory at ' + #13 + path);
   end;
end;

procedure createDirectory(wdg: uiTWidget; menu{%H-}: TObject; item{%H-}: uiPContextMenuItem);
var
   mbwWindow: uiTMessageBoxWindow;

begin
   uiMessageBox.WindowType := uiTFileContextMenuMessageBoxWindow;
   mbwWindow := uiMessageBox.ShowInput('Enter directory name', 'Enter new directory name: ', @mbCreateDirectoryNotify);
   uiTFileContextMenuMessageBoxWindow(mbwWindow).Parameters := getWindow(wdg).Parameters;
end;

procedure clearMessagesOnStartToggle({%H-}wdg: uiTWidget; {%H-}menu: TObject; item: uiPContextMenuItem);
begin
   uiFiles.ShowHiddenFiles := item^.IsChecked();
end;

procedure oxwndTFileContextMenu.SetupItems(m: uiTContextMenu);
var
   item: uiPContextMenuItem;

begin
   m.AddItem('Show in file manager', Events.SHOW_IN_FILE_MANAGER, @showInFileManager);
   m.AddItem('Open', Events.OPEN_FILE, @openFile);
   m.AddItem('Rename', Events.RENAME_FILE, @renameFile);
   m.AddItem('Delete', Events.DELETE_FILE, @deleteFile);
   m.AddItem('Create Directory', Events.CREATE_DIRECTORY, @createDirectory);

   item := m.AddCheckbox('Show hidden files', uiFiles.ShowHiddenFiles);
   item^.Callback := @clearMessagesOnStartToggle;
end;

procedure oxwndTFileContextMenu.Initialize();
begin
   Menu := uiTContextMenu.Create('File');

   Events.SHOW_IN_FILE_MANAGER := appActionEvents.GetID();
   Events.OPEN_FILE := appActionEvents.GetID();
   Events.RENAME_FILE := appActionEvents.GetID();
   Events.DELETE_FILE := appActionEvents.GetID();
   Events.CREATE_DIRECTORY := appActionEvents.GetID();

   SetupItems(Menu);

   OpenMenu := Menu;
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   oxui.BaseInitializationProcs.Add(initRoutines, 'ox.wnd.file_context_menu', @init, @deinit);

END.
