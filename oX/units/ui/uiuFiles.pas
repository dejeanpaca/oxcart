{
   uiuFiles, file related ui stuff
   Copyright (C) 2018. Dejan Boras

   Started On:    13.12.2018.
}

{$INCLUDE oxdefines.inc}
UNIT uiuFiles;

INTERFACE

   USES
      udvars, uStd, uFileUtils,
      {ox}
      uiuUI;

TYPE
   { uiTFiles }

   uiTFiles = record
      Sort,
      SortFoldersFirst,
      ShowHiddenFiles,
      {should we send files to the trash/recycle location}
      UseTrash: boolean;

      {sort files}
      procedure SortFiles(var files: TFileDescriptorList);
   end;

VAR
  uiFiles: uiTFiles;

IMPLEMENTATION

VAR
   dvSortFiles,
   dvSortFoldersFirst,
   dvShowHiddenFiles,
   dvUseTrash: TDVar;

{ uiTFileSettings }

procedure uiTFiles.SortFiles(var files: TFileDescriptorList);
begin
  if(Sort) then
     FileUtils.Sort(files, SortFoldersFirst)
  else if(SortFoldersFirst) then
     FileUtils.SortDirectoriesFirst(files);
end;

INITIALIZATION
   uiFiles.SortFoldersFirst := true;
   uiFiles.Sort := true;
   uiFiles.UseTrash := true;

   uiTUI.dvg.Add(dvSortFiles, 'sort_files', dtcBOOL, @uiFiles.Sort);
   uiTUI.dvg.Add(dvSortFoldersFirst, 'sort_folders_first', dtcBOOL, @uiFiles.SortFoldersFirst);
   uiTUI.dvg.Add(dvShowHiddenFiles, 'show_hidden_files', dtcBOOL, @uiFiles.ShowHiddenFiles);
   uiTUI.dvg.Add(dvUseTrash, 'use_trash', dtcBOOL, @uiFiles.UseTrash);

END.
