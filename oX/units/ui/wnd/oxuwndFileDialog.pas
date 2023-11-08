{
   oxuwndFileDialog, oX file operations(open/save/save as) dialog
   Copyright (C) 2011. Dejan Boras

   TODO: Make files selectable, and add file type filters
}

{$INCLUDE oxheader.inc}
UNIT oxuwndFileDialog;

INTERFACE

USES
   sysutils, uStd, StringUtils,
   {app}
   appuPaths, appuMouse,
   {oX}
   oxuTypes, oxuUI, oxuWindowTypes, oxuWindows,
   {ui}
   uiuControl, uiuTypes, uiuWindow, uiuWindowTypes, uiuWidget, uiWidgets, uiuMessageBox,
   uiuFiles,
   uiuWidgetWindow, oxuwndFileContextMenu, uiuContextMenu,
   {widgets}
   wdguInputBox, wdguButton, wdguGroup, wdguList, wdguFileList, wdguDivisor;

TYPE
   oxTFileDialogType  = (
      oxFILE_DLG_OPEN,
      oxFILE_DLG_SAVE,
      oxFILE_DLG_SAVE_AS
   );

CONST
   {default dimensions}
   oxFILE_DLG_WIDTH              = 600;
   oxFILE_DLG_HEIGHT             = 320;

TYPE
   oxPFileDialog = ^oxTFileDialog;

   { wdgTFileDialogFileList }

   wdgTFileDialogFileList = class(wdgTFileList)
      Dialog: oxPFileDialog;

      constructor Create(); override;

      procedure OnPathChanged(); override;
      procedure ItemClicked(index: loopint; button: TBitSet = appmcLEFT); override;
      procedure ItemCleared(); override;

      procedure OnContextMenuDone();
      procedure SetupRequireFile();
   end;

   { oxTFileDialog }

   oxTFileDialog = object
      public
         Title,
         SelectedFile: StdString;

         Canceled,
         {prevent deactivating the window cause a dialog cancelation}
         DoneCalled,
         {can be set by the callback to prevent closing after call}
         PreventClose,
         {only show directories}
         ShowDirectoriesOnly,
         {show hidden files}
         ShowHiddenFiles,
         {show filename input (should be false when saving into a directory instead of file)}
         ShowFilenameInput,
         {require a file to be entered or selected}
         RequireFile: boolean;

         StoredDimensions: oxTDimensions; static;

         Callback: procedure(var dialog: oxTFileDialog);
         OnPathChange: procedure(var dialog: oxTFileDialog);

         wdg: record
            Path,
            Filename: wdgTInputBox;

            Cancel,
            Ok,
            Up,
            CreateDirectory: wdgTButton;

            SystemGroup,
            RecentsGroup: wdgTGroup;

            Separator: wdgTDivisor;

            System,
            Recents: wdgTStringList;
            Files: wdgTFileDialogFileList;
         end;

      protected
         wnd: uiTWindow;
         DialogType: oxTFileDialogType;
         wndID: uiTControlID;

         SystemLocations,
         RecentsLocations: TStringArray;

      public
         {create the dialog}
         constructor Create(dt: oxTFileDialogType);
         {open the dialog}
         procedure Open();
         {close the dialog}
         procedure Close();
         {set the tile of the dialog}
         procedure SetTitle(const t: StdString);

         procedure SetPath(const path: StdString);

         {get the selected file}
         function GetSelectedFile(): StdString;

         {called when the dialog is finished}
         procedure Done(isCanceled: boolean);

         procedure CreateDirectory();

         {on window resize}
         procedure OnResize();
   end;

   { oxuiTFileDialogWindow }

   oxuiTFileDialogWindow = class(uiTWindow)
      Dialog: oxPFileDialog;

      SuppressDeactivate: boolean;

      constructor Create(); override;

      procedure DeInitialize(); override;

      procedure OnDeactivate; override;
      procedure OnClose(); override;
      procedure SizeChanged(); override;
   end;

   { oxTFileDialogGlobal }

   oxTFileDialogGlobal = record
      doDestroy: boolean;

      ids: record
         wndOPEN,
         wndSAVE,
         wndSAVE_AS,
         wdgUP,
         wdgPATH,
         wdgCREATE_DIRECTORY: uiTControlId;
      end;

      {create a new Open file dialog}
      function Open(): oxTFileDialog;
      {create a new Open file dialog}
      function OpenDirectories(): oxTFileDialog;
      {create a new Save file dialog}
      function Save(): oxTFileDialog;
      {create a new Save file dialog}
      function SaveDirectories(): oxTFileDialog;
      {create a new SaveAs file dialog}
      function SaveAs(): oxTFileDialog;
   end;

VAR
   oxFileDialog: oxTFileDialogGlobal;

IMPLEMENTATION

TYPE
   TFileList = class(wdgTStringItemList)
      Dialog: oxPFileDialog;
   end;

   { TRecentsList }

   TRecentsList = class(TFileList)
   end;

   { TSystemFilesList }

   TSystemFilesList = class(TFileList)
      protected
         procedure ItemClicked(index: loopint; button: TBitSet = appmcLEFT); override;
   end;

{ oxTFileDialogWindow }

constructor oxuiTFileDialogWindow.Create();
begin
   inherited Create();

   MinimumSize.Assign(240, 160);
end;

procedure oxuiTFileDialogWindow.DeInitialize();
begin
   Dialog^.wnd := nil;
end;

procedure oxuiTFileDialogWindow.OnDeactivate;
begin
   if(oxui.Select.GetSelectedWnd().IsType(uiTContextMenuWindow)) then
      exit;

   if(not SuppressDeactivate) then
      Dialog^.Done(true)
   else
      SuppressDeactivate := false;

   inherited OnDeactivate;
end;

procedure oxuiTFileDialogWindow.OnClose();
begin
   inherited OnClose();

   oxTFileDialog.StoredDimensions := Dimensions;
end;

procedure oxuiTFileDialogWindow.SizeChanged();
begin
   inherited SizeChanged();

   Dialog^.OnResize();
end;

{ wdgTFileDialogFileList }

constructor wdgTFileDialogFileList.Create();
begin
   inherited;

   Selectable := true;
end;

procedure wdgTFileDialogFileList.OnPathChanged();
begin
   inherited;

   Dialog^.wdg.Path.SetText(CurrentPath);

   if(Dialog^.OnPathChange <> nil) then
      Dialog^.OnPathChange(Dialog^);
end;

procedure wdgTFileDialogFileList.ItemClicked(index: loopint; button: TBitSet = appmcLEFT);
var
   from: uiTWidgetWindowOrigin;

begin
   inherited ItemClicked(index, button);

   if(button = appmcLEFT) then begin
      if(LastGridItemUnderPointer <> -1) and (Dialog^.wdg.Filename <> nil) then begin
         if(Dialog^.DialogType <> oxFILE_DLG_OPEN) then
            Dialog^.wdg.Filename.SetText(Files.List[LastGridItemUnderPointer].Name)
      end;

      SetupRequireFile();
   end else if(button = appmcRIGHT) then begin
      if(index < 0) then
         oxwndFileContextMenu.Prepare(CurrentPath, uiFILE_CONTEXT_MENU_TARGET_HERE)
      else
         oxwndFileContextMenu.Prepare(IncludeTrailingPathDelimiterNonEmpty(CurrentPath) +
            Files.List[index].Name, uiFILE_CONTEXT_MENU_TARGET_SPECIFIC);

      oxwndFileContextMenu.Parameters.OnDone.Use(@OnContextMenuDone);

      oxuiTFileDialogWindow(Dialog^.wnd).SuppressDeactivate := true;
      from.SetPoint(GetAbsolutePointer(LastPointerPosition), Self);

      oxwndFileContextMenu.Open(from);
   end;
end;

procedure wdgTFileDialogFileList.ItemCleared();
begin
   inherited ItemCleared();

   SetupRequireFile();
end;

procedure wdgTFileDialogFileList.OnContextMenuDone();
begin
   Dialog^.wdg.Files.Reload();
end;

procedure wdgTFileDialogFileList.SetupRequireFile();
begin
   if(Dialog^.RequireFile) and (Dialog^.DialogType = oxFILE_DLG_OPEN) then begin
      if(LastGridItemUnderPointer < 0) then
         Dialog^.wdg.Ok.Disable()
      else begin
         if(not Files[LastGridItemUnderPointer].IsDirectory()) then
            Dialog^.wdg.Ok.Enable()
         else
            Dialog^.wdg.Ok.Disable();
      end;
   end;
end;

{ TSystemFilesList }

procedure TSystemFilesList.ItemClicked(index: loopint; button: TBitSet = appmcLEFT);
begin
   inherited ItemClicked(index, button);

   if(button = appmcLEFT) then begin
      if(Dialog <> nil) then
         Dialog^.SetPath(Dialog^.SystemLocations[index]);
   end;
end;

{ CLASS }

constructor oxTFileDialog.Create(dt: oxTFileDialogType);
begin
   DialogType := dt;

   Canceled := true;
   ShowFilenameInput := true;
   ShowHiddenFiles := uiFiles.ShowHiddenFiles;

   if(DialogType = oxFILE_DLG_OPEN) then begin
      Title := 'Open File';
      wndID := oxFileDialog.ids.wndOPEN;
      ShowFilenameInput := false;
   end else if(DialogType = oxFILE_DLG_SAVE) then begin
      Title := 'Save File';
      wndID := oxFileDialog.ids.wndSAVE;
   end else if(DialogType = oxFILE_DLG_SAVE_AS) then begin
      Title := 'Save File As';
      wndID := oxFileDialog.ids.wndSAVE_AS;
   end;
end;

function wdgControl(wdg: uiTWidget; what: loopint): loopint;
var
   dlg: oxPFileDialog;

begin
   result := -1;

   dlg := oxuiTFileDialogWindow(wdg.wnd).Dialog;

   if(wdg = oxFileDialog.ids.wdgPATH) then begin
      result := 0;

      if(what = wdghINPUTBOX_CONFIRM) then begin
         if(DirectoryExists(dlg^.wdg.Path.GetText())) then
            dlg^.wdg.Files.FindAll(dlg^.wdg.Path.GetText());
         end;
   end else if(wdg = uiWidget.IDs.CANCEL) then
      dlg^.Done(true)
   else if(wdg = uiWidget.IDs.OK) then
      dlg^.Done(false)
   else if (wdg = oxFileDialog.ids.wdgUP) then begin
      if(what = wdghBUTTON_CLICKED) then
         dlg^.wdg.Files.GoUp();
   end;
end;

function getSystemPaths(var dialog: oxTFileDialog): TAnsiStringArray;
CONST
   COUNT = 2;

VAR
   i,
   systemCount: loopint;
   systemPaths: appTSystemPaths;

begin
   Result := nil;

   systemPaths := appPath.GetSystemPaths();
   systemCount := Length(systemPaths);

   SetLength(Result, COUNT + systemCount);
   SetLength(dialog.SystemLocations, COUNT + systemCount);

   Result[0] := 'User (Home)';
   dialog.SystemLocations[0] := appPath.Get(appPATH_HOME);
   Result[1] := 'Documents';
   dialog.SystemLocations[1] := appPath.Get(appPATH_DOCUMENTS);

   if(systemCount > 0) then begin
      for i := 0 to systemCount - 1 do begin
         Result[COUNT + i] := systemPaths[i].Name;
         dialog.SystemLocations[COUNT + i] := systemPaths[i].Path;
      end;
   end;
end;

procedure mbNotifyFail(var mb: uiTMessageBoxData);
var
   dialog: oxPFileDialog;

begin
   dialog := oxPFileDialog(uiTMessageBoxWindow(mb.Window).ExternalPtr);

   Exclude(mb.Window.Properties, uiwndpCLOSE_SELECT);
   dialog^.wnd.Select();
end;

procedure mbNotify(var mb: uiTMessageBoxData);
var
   dialog: oxPFileDialog;
   path: StdString;

begin
   dialog := oxPFileDialog(uiTMessageBoxWindow(mb.Window).ExternalPtr);

   if(mb.Input <> '') and (mb.What = uimbcWHAT_BUTTON) and (mb.Button = uimbcOK) then begin
      path := dialog^.wdg.Files.CurrentPath;
      if(path <> '') then
         path := IncludeTrailingPathDelimiter(path);

      path := path + mb.Input;

      if(CreateDir(path)) then
         dialog^.wdg.Files.Reload()
      else begin
         uiMessageBox.ShowWarning('Faile to create directory', 'Failed to create directory at ' + #13 + path, @mbNotifyFail).ExternalPtr := dialog;
         exit;
      end;
   end;

   Exclude(mb.Window.Properties, uiwndpCLOSE_SELECT);
   dialog^.wnd.Select();
end;

function filenameInputControl(wdg: uiTWidget; what: loopint): loopint;
var
   dialog: oxPFileDialog;

begin
   if(what = wdghINPUTBOX_CHANGED) then begin
      dialog := oxuiTFileDialogWindow(wdg.wnd).Dialog;

      if(wdgTInputBox(wdg).GetText() <> '') then
         dialog^.wdg.Ok.Enable()
      else
         dialog^.wdg.Ok.Disable();
   end;

   Result := -1;
end;

procedure oxTFileDialog.Open();
var
   caption: StdString = '?';
   parent: uiTWindow;
   dialogWidth,
   dialogHeight: loopint;
   filenameInput: boolean = false;

begin
   DoneCalled := false;

   {if there is no window create one}
   if(wnd = nil) then begin
      {create the window}
      dialogWidth := oxFILE_DLG_WIDTH;
      dialogHeight := oxFILE_DLG_HEIGHT;

      if(ShowFilenameInput) then
         dialogHeight := dialogHeight + 20 + (uiWidget.GridSize.h * 2);

      if(StoredDimensions.w <> 0) then
         dialogWidth := StoredDimensions.w;

      if(StoredDimensions.h <> 0) then
         dialogHeight := StoredDimensions.h;

      parent := oxTWindow(oxui.GetUseWindow().oxwParent);

      uiWindow.Create.Properties := uiWindow.Create.Properties + [uiwndpAUTO_CENTER, uiwndpNO_DISPOSE_OF_EXT_DATA];
      uiWindow.Create.Instance := oxuiTFileDialogWindow;

      wnd := uiWindow.MakeChild(parent,
         Title, oxNullPoint,
            oxDimensions(dialogWidth, dialogHeight)).
            SetID(wndID);

      if(wnd <> nil) then begin
         {link the oxTFileDialog object with the window}
         oxuiTFileDialogWindow(wnd).Dialog := @Self;

         if(DialogType <> oxFILE_DLG_OPEN) and (ShowFilenameInput) then
            filenameInput := true;

         { create the widgets }
         uiWidget.SetTarget(wnd, @wdgControl);

         {up button}
         wdg.Up := wdgTButton(wdgButton.Add('^').
            SetID(oxFileDialog.ids.wdgUP));

         { path }
         wdg.Path := wdgTInputBox(wdgInputBox.Add('').
            SetID(oxFileDialog.ids.wdgPATH));

         wdg.Path.SetPlaceholder('path');

         {store widget target}
         uiWidget.PushTarget();

         { system locations list }
         wdg.SystemGroup := wdgTGroup(wdgGroup.Add('System'));

         wdg.SystemGroup.SetTarget();

         uiWidget.Create.Instance := TSystemFilesList;
         wdg.System := wdgTStringList(wdgStringList.Add());
         TFileList(wdg.System).Dialog := @Self;

         wdg.System.Assign(getSystemPaths(Self));

         uiWidget.PopTarget();

         { recent locations list }

         uiWidget.PushTarget();

         wdg.RecentsGroup := wdgTGroup(wdgGroup.Add('Recents'));

         wdg.RecentsGroup.SetTarget();

         uiWidget.Create.Instance := TRecentsList;
         wdg.Recents := wdgTStringList(wdgStringList.Add());
         TFileList(wdg.Recents).Dialog := @Self;

         { restore previous target }
         uiWidget.PopTarget();

         { files }
         uiWidget.Create.Instance := wdgTFileDialogFileList;
         wdg.Files := wdgTFileDialogFileList(wdgFileList.Add());
         wdg.Files.SetDirectoriesOnly(ShowDirectoriesOnly);
         wdg.Files.Dialog := @Self;
         wdg.Files.IncludeParentDirectoryLink := false;

         uiWidget.LastRect.GoLeft();

         if(filenameInput) then begin
            wdg.Filename := wdgInputBox.Add('');

            wdg.Filename.SetPlaceholder('Save file as');
            wdg.Filename.SetControlMethod(@filenameInputControl);
         end;

         { divisor }
         wdg.Separator := wdgDivisor.Add('');

         { cancel button }
         wdg.Cancel := wdgTButton(wdgButton.Add('Cancel').
            SetID(uiWidget.IDs.Cancel));

         { save/open button }
         if(DialogType = oxFILE_DLG_OPEN) then
            caption := 'Open'
         else if(DialogType = oxFILE_DLG_SAVE) or (DialogType = oxFILE_DLG_SAVE_AS) then
            caption := 'Save';

         wdg.Ok := wdgTButton(wdgButton.Add(caption).
            SetID(uiWidget.IDs.OK));

         {disable by default if filename input enabled}
         if(filenameInput) then
            wdg.Ok.Disable();

         {create directory}
         if(DialogType <> oxFILE_DLG_OPEN) then begin
            wdg.CreateDirectory := wdgTButton(wdgButton.Add('Create Directory').
               SetID(oxFileDialog.ids.wdgCREATE_DIRECTORY));

            wdg.CreateDirectory.Callback.Use(@createDirectory);
         end;

         wdg.Files.SetupRequireFile();

         SetPath(GetCurrentDir());

         OnResize();
      end;
   end;

   wnd.Open();
end;

{close the window}
procedure CloseWindow(wnd: uiTWindow);
begin
   if(wnd <> nil) then begin
      if(oxFileDialog.doDestroy) then
         uiWindow.DisposeQueue(wnd)
      else
         wnd.Close();
   end;
end;

procedure oxTFileDialog.Close();
begin
   uiWindow.DisposeQueue(wnd);
end;

procedure oxTFileDialog.SetTitle(const t: StdString);
begin
   Title := t;

   if(wnd <> nil) then
      wnd.SetTitle(t);
end;

procedure oxTFileDialog.SetPath(const path: StdString);
begin
   if(wdg.Path <> nil) then
      wdg.Path.SetText(path);

   if(wdg.Files <> nil) then begin
      wdg.Files.Pattern := '*';
      wdg.Files.FindAll(path);
   end;
end;

function oxTFileDialog.GetSelectedFile(): StdString;
begin
   if(ShowFilenameInput) and (wdg.Filename <> nil) then begin
      Result := IncludeTrailingPathDelimiterNonEmpty(wdg.Files.CurrentPath) + wdg.Filename.GetText();
   end else begin
      Result := wdg.Files.CurrentPath;

      if(wdg.Files.LastGridItemUnderPointer <> -1) then begin
         Result := IncludeTrailingPathDelimiterNonEmpty(Result) +
            wdg.Files.Files.List[wdg.Files.LastGridItemUnderPointer].Name;
      end;
   end;
end;

procedure oxTFileDialog.Done(isCanceled: boolean);
begin
   if(not DoneCalled) then begin
      DoneCalled := true;

      Canceled := isCanceled;
      SelectedFile := GetSelectedFile();

      if(Callback <> nil) then
         Callback(Self);

      if(not PreventClose) then
         Close()
      else
         DoneCalled := false;

      PreventClose := false;
   end;
end;

procedure oxTFileDialog.CreateDirectory();
begin
   oxuiTFileDialogWindow(wnd).SuppressDeactivate := true;

   uiMessageBox.ShowInput('Create directory', 'Enter the name of the directory', @mbNotify).ExternalPtr := oxuiTFileDialogWindow(wnd).Dialog;
end;

procedure oxTFileDialog.OnResize();
var
   leftWidth,
   groupHeight,
   dialogHeight,
   bottomHeight,
   top: loopint;
   filenameInput: boolean = false;
   gw,
   gh: loopint;

begin
   if(wnd <> nil) then begin
      leftWidth := 175;
      dialogHeight := wnd.Dimensions.h;

      gw := uiWidget.GridSize.w;
      gh := uiWidget.GridSize.h;

      if(DialogType <> oxFILE_DLG_OPEN) and (ShowFilenameInput) then
         filenameInput := true;

      if(not filenameInput) then
         bottomHeight := 75
      else
         bottomHeight := 105;

      top := dialogHeight - wdgDEFAULT_SPACING;

      groupHeight := (dialogHeight - bottomHeight) div 2;

      {up button}
      wdg.Up.Move(leftWidth + uiWidget.GridSize.h * 2, top);
      wdg.Up.Resize(20, 25);

      { path }
      wdg.Path.Move(wdg.Up.RightOf(), top);
      wdg.Path.Resize(5, 25).SetSize(wdgWIDTH_MAX_HORIZONTAL);

      { system locations list }
      wdg.SystemGroup.Move(uiWidget.GridSize.w, top);
      wdg.SystemGroup.Resize(leftWidth, groupHeight);

      wdg.System.Move(gw, wdg.SystemGroup.Dimensions.h - gw * 2);
      wdg.System.Resize(wdg.SystemGroup.Dimensions.w - gw * 2, wdg.SystemGroup.Dimensions.h - gh * 3);

      { recent locations list }

      wdg.RecentsGroup.Move(gw, wdg.SystemGroup.Position.y - wdg.SystemGroup.Dimensions.h - gh);
      wdg.RecentsGroup.Resize(leftWidth, wnd.Dimensions.h - bottomHeight - wdg.SystemGroup.Dimensions.h);

      wdg.Recents.Move(gw, wdg.RecentsGroup.Dimensions.h - gh * 2);
      wdg.Recents.Resize(wdg.RecentsGroup.Dimensions.w - gw * 2,
         wdg.RecentsGroup.Dimensions.h - gh * 2);

      { files }
      wdg.Files.Move(leftWidth + gw * 2, dialogHeight - 40);
      wdg.Files.Resize(5, wnd.Dimensions.h - bottomHeight - 20).SetSize(wdgWIDTH_MAX_HORIZONTAL);

      if(wdg.Filename <> nil) then begin
         wdg.Filename.Move(wdg.Files.Position.x, wdg.Files.BelowOf());
         wdg.Filename.Resize(wdg.Files.Dimensions.w, 25);
      end;

      { divisor }
      uiWidget.LastRect.GoZero();
      wdg.Separator.Move(uiWidget.LastRect.BelowOf());

      { cancel button }
      wdg.Cancel.Resize(90, 25);
      wdg.Cancel.SetPosition(wdgPOSITION_VERTICAL_BOTTOM or wdgPOSITION_HORIZONTAL_RIGHT);
      wdg.Cancel.SetButtonPosition([uiCONTROL_GRID_RIGHT]);

      wdg.Ok.Resize(90, 25);
      wdg.Ok.Move(wdg.Cancel.LeftOf(0) - wdg.Ok.Dimensions.w + 1, wdg.Cancel.Position.y);
      wdg.Ok.SetButtonPosition([uiCONTROL_GRID_LEFT]);

      {create directory}
      if(wdg.CreateDirectory <> nil) then begin
         wdg.CreateDirectory.Move(leftWidth + gw * 2, wdg.Cancel.Position.y);
         wdg.CreateDirectory.Resize(140, 25);
      end;
   end;
end;

{ GENERAL ROUTINES }

function oxTFileDialogGlobal.Open(): oxTFileDialog;
begin
   Result.Create(oxFILE_DLG_OPEN);
end;

function oxTFileDialogGlobal.OpenDirectories(): oxTFileDialog;
begin
   Result := Open();
   Result.ShowDirectoriesOnly := true;
end;

function oxTFileDialogGlobal.Save(): oxTFileDialog;
begin
   Result.Create(oxFILE_DLG_SAVE);
end;

function oxTFileDialogGlobal.SaveDirectories(): oxTFileDialog;
begin
   Result := Save();
   Result.ShowDirectoriesOnly := true;
end;

function oxTFileDialogGlobal.SaveAs(): oxTFileDialog;
begin
   Result.Create(oxFILE_DLG_SAVE_AS);
end;

INITIALIZATION
   oxFileDialog.doDestroy := true;

   oxFileDialog.ids.wndOPEN      := uiControl.GetID('ox.open_file');
   oxFileDialog.ids.wndSAVE      := uiControl.GetID('ox.save_file');
   oxFileDialog.ids.wndSAVE_AS   := uiControl.GetID('ox.save_file_as');

   oxFileDialog.ids.wdgUP        := uiControl.GetID('ox.file_dialg.up');
   oxFileDialog.ids.wdgPATH      := uiControl.GetID('ox.file_dialog.path');
   oxFileDialog.ids.wdgCREATE_DIRECTORY := uiControl.GetID('ox.file_dialog.create_directory');
END.
