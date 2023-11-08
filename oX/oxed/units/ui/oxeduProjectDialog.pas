{
   oxeduProject, project for oxed
   Copyright (C) 2016. Dejan Boras

   Started On:    13.10.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectDialog;

INTERFACE

   USES
      sysutils, uStd, uLog, uFileUtils,
      appuActionEvents,
      {ox}
      oxuRunRoutines,
      {ui}
      uiuMessageBox, uiuTypes,
      {oxed}
      uOXED, oxeduActions, oxuwndFileDialog, oxeduProject, oxeduProjectManagement, oxeduSceneManagement, oxeduMessages;

TYPE

   { oxedTProjectDialog }

   oxedTProjectDialog = record
      {show the project open  dialog}
      class procedure OpenDialog(); static;
      {show the project open  dialog}
      class procedure SaveDialog(); static;

      {close the project}
      class procedure Close(); static;

      {scene open dialog}
      class procedure NewSceneDialog(); static;
      {scene open dialog}
      class procedure OpenSceneDialog(); static;
      {scene open dialog}
      class procedure SaveSceneDialog(); static;
   end;

VAR
   oxedProjectDialog: oxedTProjectDialog;

IMPLEMENTATION

VAR
   dlgOpen,
   dlgSave,
   dlgSceneOpen,
   dlgSceneSave: oxTFileDialog;

procedure openCallback(var dialog: oxTFileDialog);
begin
   if(not dialog.Canceled) then begin
      oxedProjectManagement.Open(dialog.SelectedFile);
   end;
end;

procedure openSceneCallback(var dialog: oxTFileDialog);
begin
   if(not dialog.Canceled) then begin
      oxedSceneManagement.Open(dialog.SelectedFile);
   end;
end;

procedure openOnPathChange(var dialog: oxTFileDialog);
begin
   if(FileUtils.DirectoryExists(IncludeTrailingPathDelimiter(dialog.wdg.Files.CurrentPath) + oxPROJECT_DIRECTORY)) then
      dialog.wdg.Ok.Enable(true)
   else
      dialog.wdg.Ok.Enable(false);
end;

class procedure oxedTProjectDialog.OpenDialog();
begin
   dlgOpen.Open();
end;

procedure saveTo(const path: string; overwrite: boolean = false);
begin
   log.i('project > Saving to: ' + path);

   oxedProject.SetPath(path);
   oxedProjectManagement.Save();

   if(overwrite) then
      oxedProjectManagement.OnOverwritten.Call();
end;

procedure saveSceneTo(const path: string);
begin
   log.i('scene > Saving to: ' + path);

   oxedProject.ScenePath := path;
   oxedSceneManagement.Save();
end;

procedure mbSaveNonEmpty(var data: uiTMessageBoxData);
var
   dialog: oxPFileDialog;

begin
   dialog := uiTMessageBoxWindow(data.Window).ExternalPtr;

   if(data.Button = uimbcOK) then begin
      saveTo(dialog^.SelectedFile, true);
      dialog^.Close();
   end;
end;

procedure mbSceneSaveExisting(var data: uiTMessageBoxData);
var
   dialog: oxPFileDialog;

begin
   dialog := uiTMessageBoxWindow(data.Window).ExternalPtr;

   if(data.Button = uimbcOK) then begin
      saveSceneTo(dialog^.SelectedFile);
      dialog^.Close();
   end;
end;

procedure saveCallback(var dialog: oxTFileDialog);
var
   mbwnd: uiTMessageBoxWindow;

begin
   if(not dialog.Canceled) then begin
      if(not FileUtils.DirectoryExists(dialog.SelectedFile)) then begin
         oxed.ErrorMessage('Save project', 'Selected path not accessible or not a directory: '#13#13 + dialog.SelectedFile);
         exit;
      end;

      {check if the directory is empty and warn}
      if(FileUtils.DirectoryEmpty(dialog.SelectedFile)) then begin
         saveTo(dialog.SelectedFile);
      end else begin
         mbwnd := uiMessageBox.Show('Directory not empty', 'Selected path is not empty: '#13#13 + dialog.SelectedFile + #13 +
            'Are you sure you want to use this directory?', uimbsWARNING, uimbcOK_CANCEL, uimbpDEFAULT, @mbSaveNonEmpty);

         mbwnd.ExternalPtr := @dialog;
         dialog.PreventClose := true;
      end;
   end;
end;

procedure saveSceneCallback(var dialog: oxTFileDialog);
var
   mbwnd: uiTMessageBoxWindow;

begin
   if(not dialog.Canceled) then begin
      if(FileUtils.Exists(dialog.SelectedFile) > 0) then begin
         oxed.ErrorMessage('Save scene', 'Overwrite file: '#13#13 + dialog.SelectedFile);
         mbwnd := uiMessageBox.Show('Overwrite scene?', 'File already exists: '#13#13 + dialog.SelectedFile + #13 +
            'Are you sure you want to overwrite this file?', uimbsWARNING, uimbcOK_CANCEL, uimbpDEFAULT, @mbSceneSaveExisting);

         mbwnd.ExternalPtr := @dialog;
         dialog.PreventClose := true;
      end else
         saveSceneTo(dialog.SelectedFile);
   end;
end;

class procedure oxedTProjectDialog.SaveDialog();
begin
   if(oxedProject <> nil) and (oxedProject.Path = '') then begin
      dlgSave.Open();
   end else
      oxedProjectManagement.Save();
end;

class procedure oxedTProjectDialog.Close();
begin
   oxedProjectManagement.Destroy();
   oxedMessages.i('Closed project');
end;

class procedure oxedTProjectDialog.NewSceneDialog();
begin
   if(oxedProject <> nil) then
      oxedSceneManagement.New();

   {TODO: Show a dialog asking to save the current scene}
end;

class procedure oxedTProjectDialog.OpenSceneDialog();
begin
   if(not oxedProjectValid()) then
      exit;

   dlgSceneOpen.Open();
end;

class procedure oxedTProjectDialog.SaveSceneDialog();
begin
   if(not oxedProjectValid()) then
      exit;

   if(oxedProject.ScenePath = '') then begin
      dlgSceneSave.Open();
   end else
      oxedSceneManagement.Save();
end;

INITIALIZATION
   oxedActions.OPEN_PROJECT := appActionEvents.SetCallback(@oxedProjectDialog.OpenDialog);
   oxedActions.NEW_PROJECT := appActionEvents.SetCallback(@oxedProjectManagement.New);
   oxedActions.SAVE_PROJECT := appActionEvents.SetCallback(@oxedProjectDialog.SaveDialog);
   oxedActions.CLOSE_PROJECT := appActionEvents.SetCallback(@oxedProjectDialog.Close);

   oxedActions.NEW_SCENE := appActionEvents.SetCallback(@oxedProjectDialog.NewSceneDialog);
   oxedActions.OPEN_SCENE := appActionEvents.SetCallback(@oxedProjectDialog.OpenSceneDialog);
   oxedActions.SAVE_SCENE := appActionEvents.SetCallback(@oxedProjectDialog.SaveSceneDialog);

   dlgOpen := oxFileDialog.OpenDirectories();
   dlgOpen.SetTitle('Open Project');
   dlgOpen.Callback := @openCallback;
   dlgOpen.OnPathChange := @openOnPathChange;

   dlgSave := oxFileDialog.SaveDirectories();
   dlgSave.Callback := @saveCallback;
   dlgSave.SetTitle('Save Project');
   dlgSave.ShowFilenameInput := false;

   dlgSceneOpen := oxFileDialog.Open();
   dlgSceneOpen.SetTitle('Open Scene');
   dlgSceneOpen.Callback := @openSceneCallback;
   dlgSceneOpen.RequireFile := true;

   dlgSceneSave := oxFileDialog.Save();
   dlgSceneSave.SetTitle('Save Scene');
   dlgSceneSave.Callback := @saveSceneCallback;
   dlgSceneSave.RequireFile := true;

END.
