{
   uiuFiles, file related ui stuff
   Copyright (C) 2018. Dejan Boras

   Started On:    13.12.2018.
}

{$INCLUDE oxdefines.inc}
UNIT uiuFiles;

INTERFACE

   USES
      udvars, uStd,
      {ox}
      oxuUI;

TYPE
   uiTFileSettings = record
      SortFoldersFirst,
      ShowHiddenFiles: boolean;
   end;

VAR
  uiFileSettings: uiTFileSettings;

IMPLEMENTATION

VAR
   dvSortFoldersFirst,
   dvShowHiddenFiles: TDVar;

INITIALIZATION
   uiFileSettings.SortFoldersFirst := true;

   oxTUI.dvg.Add(dvSortFoldersFirst, 'sort_folders_first', dtcBOOL, @uiFileSettings.SortFoldersFirst);
   oxTUI.dvg.Add(dvShowHiddenFiles, 'show_hidden_files', dtcBOOL, @uiFileSettings.ShowHiddenFiles);

END.
