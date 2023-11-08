{
   oxuFileIcons, file icons
   Copyright (c) 2013. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuFileIcons;

INTERFACE

   USES
      uStd,
      {ox}
      uOX, oxuRunRoutines, oxuTypes,
      oxuTexture, oxuResourcePool;

TYPE
   oxTFileIcon = record
      Texture: oxTTexture;
      FileType: string;
   end;

   oxTFileIconList = specialize TSimpleList<oxTFileIcon>;

   { oxTFileIcons }

   oxTFileIcons = record
      Icons: oxTFileIconList;

      GenericFile,
      GenericDirectory,
      GenericDirectoryOpen: oxTFileIcon;

      procedure Add(tex: oxTTexture; const fileType: string);

      {set generic file icon}
      procedure SetFile(tex: oxTTexture);
      {set generic directory icon}
      procedure SetDirectory(tex: oxTTexture);
      {set generic directory icon}
      procedure SetDirectoryOpen(tex: oxTTexture);

      {get generic file icon}
      function GetFile(): oxTTexture;
      {get generic directory icon}
      function GetDirectory(): oxTTexture;
      {get generic directory open icon}
      function GetDirectoryOpen(): oxTTexture;

      procedure DestroyIcon(var icon: oxTFileIcon);

      {get file icon for specified file type}
      function Get(const fileType: string): oxTTexture;
   end;

VAR
   oxFileIcons: oxTFileIcons;

IMPLEMENTATION

{ oxTFileIcons }

procedure oxTFileIcons.Add(tex: oxTTexture; const fileType: string);
var
   f: oxTFileIcon;

begin
   f.Texture := tex;
   f.FileType := fileType;

   if(tex <> nil) then
      tex.MarkUsed();

   Icons.Add(f);
end;

procedure oxTFileIcons.SetFile(tex: oxTTexture);
begin
   oxResource.Destroy(GenericFile.Texture);

   GenericFile.Texture := tex;

   if(tex <> nil) then
      tex.MarkUsed();
end;

procedure oxTFileIcons.SetDirectory(tex: oxTTexture);
begin
   oxResource.Destroy(GenericDirectory.Texture);

   GenericDirectory.Texture := tex;

   if(tex <> nil) then
      tex.MarkUsed();
end;

procedure oxTFileIcons.SetDirectoryOpen(tex: oxTTexture);
begin
   oxResource.Destroy(GenericDirectoryOpen.Texture);

   GenericDirectoryOpen.Texture := tex;

   if(tex <> nil) then
      tex.MarkUsed();
end;

function oxTFileIcons.GetFile(): oxTTexture;
begin
   Result := GenericFile.Texture;
end;

function oxTFileIcons.GetDirectory(): oxTTexture;
begin
   Result := GenericDirectory.Texture;
end;

function oxTFileIcons.GetDirectoryOpen(): oxTTexture;
begin
   Result := GenericDirectoryOpen.Texture;
end;

procedure oxTFileIcons.DestroyIcon(var icon: oxTFileIcon);
begin
   oxResource.Destroy(icon.Texture);

   icon.FileType := '';
end;

function oxTFileIcons.Get(const fileType: string): oxTTexture;
var
   i: loopint;
   ft: string;

begin
   if(Icons.n > 0) then begin
      ft := lowercase(fileType);

      for i := 0 to (Icons.n - 1) do begin
         if(Icons.List[i].FileType = ft) then
            exit(Icons.List[i].Texture);
      end;
   end;

   Result := GenericFile.Texture;
end;

procedure deinit();
var
   i: loopint;

begin
   for i := 0 to (oxFileIcons.Icons.n - 1) do begin
      oxFileIcons.DestroyIcon(oxFileIcons.Icons.List[i]);
   end;

   oxFileIcons.DestroyIcon(oxFileIcons.GenericFile);
   oxFileIcons.DestroyIcon(oxFileIcons.GenericDirectory);
   oxFileIcons.DestroyIcon(oxFileIcons.GenericDirectoryOpen);

   oxFileIcons.Icons.Dispose();
end;

INITIALIZATION
   ox.Init.dAdd('ox.file_icons', @deinit);
   oxFileIcons.Icons.Initialize(oxFileIcons.Icons);

END.
