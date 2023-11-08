{
   oxeduProjectContextMenu, oxed menu for project browser
   Copyright (C) 2017. Dejan Boras

   Started On:    12.08.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectContextMenu;

INTERFACE

   USES
      sysutils, uStd, StringUtils, uFileUtils,
      {app}
      appuEvents, appuActionEvents,
      {ox}
      oxuRunRoutines,
      {ui}
      uiuContextMenu, uiuWidgetWindow,
      wdguFileList, oxuwndFileContextMenu, oxuFilePreviewWindow,
      {oxed}
      uOXED, oxeduIcons, oxeduActions;

TYPE
   { oxedTProjectContextMenuGlobal }

   oxedTProjectContextMenuGlobal = record
      Parameters: uiTFileContextMenuParameters;
      Browser: wdgTFileGrid;
      Hierarchy: wdgTHierarchicalFileList;

      Menus: record
         Current,
         Create: uiTContextMenu;
      end;

      Items: record
         Duplicate,
         Create,
         Preview: uiPContextMenuItem;
      end;

      Events: record
         DUPLICATE: TEventId;
      end;

      procedure OpenMenu(const from: uiTWidgetWindowOrigin);

      procedure Initialize();
   end;

VAR
   oxedProjectContextMenu: oxedTProjectContextMenuGlobal;

IMPLEMENTATION

procedure reloadBrowserNav(navigation: boolean);
begin
   if(oxwndFileContextMenu.LastAction <> oxwndFileContextMenu.Events.OPEN_FILE) and
      (oxwndFileContextMenu.LastAction <> oxwndFileContextMenu.Events.SHOW_IN_FILE_MANAGER) then begin
      if(oxedProjectContextMenu.Browser <> nil) then
         oxedProjectContextMenu.Browser.Reload();

      if(oxedProjectContextMenu.Hierarchy <> nil) and (navigation) then
         oxedProjectContextMenu.Hierarchy.Reload();
   end;
end;

procedure reloadBrowser();
begin
   reloadBrowserNav(true);
end;

{ oxedTProjectContextMenuGlobal }

procedure oxedTProjectContextMenuGlobal.OpenMenu(const from: uiTWidgetWindowOrigin);
var
   handler: oxTFilePreviewHandler;

begin
   oxwndFileContextMenu.Prepare(Parameters.TargetPath, Parameters.Target);
   oxwndFileContextMenu.Parameters.AllowCreateDirectory := Parameters.AllowCreateDirectory;

   oxwndFileContextMenu.Parameters.OnDone.Use(@reloadBrowser);
   oxwndFileContextMenu.OpenMenu := Menus.Current;
   oxwndFileContextMenu.Open(from);

   if(Parameters.Target = uiFILE_CONTEXT_MENU_TARGET_HERE) then begin
      Items.Duplicate^.Disable();
      Items.Create^.Enable();
   end else begin
      Items.Duplicate^.Enable();
      Items.Create^.Disable();
   end;

   if(not Parameters.IsDirectory) and (oxFilePreviewWindow.Previewable(Parameters.TargetPath, handler)) then begin
      Items.Preview^.Enable(true);
   end else
      Items.Preview^.Enable(false);

   Parameters.IsDirectory := oxwndFileContextMenu.Parameters.IsDirectory;

   if(Parameters.IsDirectory) then
      Menus.Current.FindByAction(Events.DUPLICATE)^.Disable();
end;

procedure duplicateFile();
var
   i: loopint;
   base, destination, ext: string;

begin
   if(not oxedProjectContextMenu.Parameters.IsDirectory) then begin
      base := ExtractAllNoExt(oxedProjectContextMenu.Parameters.TargetPath);
      ext := ExtractFileExt(oxedProjectContextMenu.Parameters.TargetPath);

      destination := base + ' (Copy)' + ext;

      if(FileUtils.Exists(destination) > 0) then begin
         i := 0;
         repeat
           inc(i);
           destination := base + ' (Copy ' + sf(i) + ')' + ext;
         until FileUtils.Exists(destination) < 0;
      end;

      FileUtils.Copy(oxedProjectContextMenu.Parameters.TargetPath, destination);
      reloadBrowserNav(false);
   end;
end;

function getCreatePath(): string;
begin
   if(oxedProjectContextMenu.Parameters.Target = uiFILE_CONTEXT_MENU_TARGET_SPECIFIC) then
      Result := ExtractFilePath(oxedProjectContextMenu.Parameters.TargetPath)
   else
      Result := oxedProjectContextMenu.Parameters.TargetPath;

   if(Result <> '') then
      Result := IncludeTrailingPathDelimiter(Result);
end;

procedure createUnit();
var
   path: string;
   p: TAppendableString;

begin
   path := getCreatePath();

   p := '';
   p.Add('UNIT template;');
   p.Add('');
   p.Add('INTERFACE');
   p.Add('');
   p.Add('IMPLEMENTATION');
   p.Add('');
   p.Add('END.' + LineEnding);

   FileUtils.WriteString(path + 'new.pas', p);

   reloadBrowserNav(false);
end;

procedure createEntityUnit();
begin
   createUnit();
end;

procedure createEditorUnit();
begin
   createUnit();
end;

procedure createEmptyUnit();
begin
   createUnit();
end;

procedure createTextFile();
begin
   FileUtils.WriteString(getCreatePath() + 'new.txt', '');
   reloadBrowserNav(false);
end;

procedure openLazarus();
begin
   appActionEvents.Queue(oxedActions.OPEN_LAZARUS);
end;

procedure previewFile();
begin
   if(not oxedProjectContextMenu.Parameters.IsDirectory) then begin
      if(oxFilePreviewWindow <> nil) then
         oxFilePreviewWindow.Show(oxedProjectContextMenu.Parameters.TargetPath);
   end;
end;

procedure oxedTProjectContextMenuGlobal.Initialize;
var
   item: uiPContextMenuItem;

begin
   Events.DUPLICATE := appActionEvents.GetID();

   Menus.Current := uiTContextMenu.Create('Project menu');
   oxwndFileContextMenu.SetupItems(Menus.Current);

   item := Menus.Current.FindByAction(oxwndFileContextMenu.Events.RENAME_FILE);
   oxedIcons.Create(item, $f246);
   item := Menus.Current.FindByAction(oxwndFileContextMenu.Events.DELETE_FILE);
   oxedIcons.Create(item, $f00d);
   item := Menus.Current.FindByAction(oxwndFileContextMenu.Events.CREATE_DIRECTORY);
   oxedIcons.Create(item, $f07b);

   Menus.Current.InsertAt(Menus.Current.FindIndexByAction(oxwndFileContextMenu.Events.DELETE_FILE));

   Items.Duplicate := Menus.Current.AddItem('Duplicate', @duplicateFile);
   Items.Duplicate^.Action := Events.DUPLICATE;
   oxedIcons.Create(Items.Duplicate, $f0c5);

   Menus.Create := uiTContextMenu.Create('Create');
   Menus.Create.AddItem('Entity unit', @createEntityUnit);
   Menus.Create.AddItem('Editor unit', @createEditorUnit);
   Menus.Create.AddItem('Empty unit', @createEmptyUnit);
   Menus.Create.AddItem('Text file', @createTextFile);
   Menus.Create.AddSeparator();
   Menus.Create.AddItem('Material');
   Menus.Create.AddItem('Shader');

   Menus.Current.InsertAt(Menus.Current.FindIndexByAction(oxwndFileContextMenu.Events.CREATE_DIRECTORY));
   Menus.Current.AddSeparator();
   Menus.Current.InsertAfter(Menus.Current.FindIndexByAction(oxwndFileContextMenu.Events.CREATE_DIRECTORY));
   Items.Create := Menus.Current.AddSub('Create', Menus.Create);

   Menus.Current.AddSeparator();
   Items.Preview := Menus.Current.AddItem('Preview', @previewFile);
   item := Menus.Current.AddItem('Open Lazarus', @openLazarus);
   oxedIcons.Create(item, $f1b0);
end;


procedure init();
begin
   oxedProjectContextMenu.Initialize();
end;

procedure deinit();
begin
   uiContextMenu.Destroy();

   FreeObject(oxedProjectContextMenu.Menus.Current);
end;

VAR
   oxedInitRoutines: oxTRunRoutine;

INITIALIZATION
   oxed.Init.Add(oxedInitRoutines, 'project_context_menu', @init, @deinit);

END.

