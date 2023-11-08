{
   oxeduAssets, oxed asset management
   Copyright (C) 2020. Dejan Boras

   TODO: Ignore oX data files which are not used
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAssets;

INTERFACE

   USES
      uStd, StringUtils, uLog,
      {ox}
      oxuPaths,
      {oxed}
      uOXED, oxeduPackage;

TYPE

   { oxedTAssets }

   oxedTAssets = record
      {a package containing oX data (assets)}
      oxDataPackage: oxedTPackage;

      {ignore these file types when building (don't copy over)}
      IgnoreFileTypes,
      IgnoreDirectories,
      ProjectIgnoreFileTypes,
      ProjectIgnoreDirectories: TSimpleStringList;

      function ShouldIgnore(const ext: StdString): boolean;
      function ShouldIgnoreDirectory(const name: StdString): boolean;

      function IsLastPath(const path: StdString): boolean;
   end;

VAR
   oxedAssets: oxedTAssets;

IMPLEMENTATION

{ oxedTAssets }

function oxedTAssets.ShouldIgnore(const ext: StdString): boolean;
{$IFDEF WINDOWS}
var
   lext: StdString;
{$ENDIF}

begin
   {$IFDEF WINDOWS}
   lext := LowerCase(ext);

   if(IgnoreFileTypes.FindLowercase(lext) >= 0) or (ProjectIgnoreFileTypes.FindLowercase(lext) >= 0) then
      exit(true);
   {$ELSE}
   if(IgnoreFileTypes.FindString(ext) >= 0) or (ProjectIgnoreFileTypes.FindString(ext) >= 0) then
      exit(true);
   {$ENDIF}

   Result := false;
end;

function oxedTAssets.ShouldIgnoreDirectory(const name: StdString): boolean;
{$IFDEF WINDOWS}
var
   lname: StdString;
{$ENDIF}

begin
   {$IFDEF WINDOWS}
   lname := LowerCase(name);

   if(IgnoreDirectories.FindLowercase(lname) >= 0) or (ProjectIgnoreDirectories.FindLowercase(lname) >= 0) then
      exit(true);
   {$ELSE}
   if(IgnoreFolders.FindString(name) >= 0) or (ProjectIgnoreFolders.FindString(name) >= 0) then
      exit(true);
   {$ENDIF}

   Result := false;
end;

function oxedTAssets.IsLastPath(const path: StdString): boolean;
var
   i,
   len: loopint;
{$IFDEF WINDOWS}
   lpath: StdString;
{$ENDIF}

begin
   len := Length(path);

   if(len > 0) then begin
      {$IFDEF WINDOWS}
      lpath := LowerCase(path);
      {$ENDIF}

      for i := 0 to IgnoreDirectories.n - 1 do begin
         {$IFDEF WINDOWS}
         if(StringPos(IgnoreDirectories.List[i], lpath, Length(IgnoreDirectories.List[i]) - len) > 0) then
            exit(true);
         {$ELSE}
         if(StringPos(IgnoreDirectories.List[i], path, Length(IgnoreDirectories.List[i]) - len) > 0) then
            exit(true);
         {$ENDif}
      end;

      for i := 0 to ProjectIgnoreDirectories.n - 1 do begin
         {$IFDEF WINDOWS}
         if(StringPos(ProjectIgnoreDirectories.List[i], lpath, Length(ProjectIgnoreDirectories.List[i]) - len) > 0) then
            exit(true);
         {$ELSE}
         if(StringPos(ProjectIgnoreDirectories.List[i], path, Length(ProjectIgnoreDirectories.List[i]) - len) > 0) then
            exit(true);
         {$ENDif}
      end;
   end;

   Result := false;
end;

procedure init();
begin
   oxedAssets.oxDataPackage.Id := 'ox';
   oxedAssets.oxDataPackage.Path := oxPaths.BasePath + 'data' + DirectorySeparator;
end;

INITIALIZATION
   oxed.Init.Add('assets', @init);

   TSimpleStringList.Initialize(oxedAssets.IgnoreFileTypes, 256);
   TSimpleStringList.Initialize(oxedAssets.IgnoreDirectories, 256);
   TSimpleStringList.Initialize(oxedAssets.ProjectIgnoreFileTypes, 256);

   oxedAssets.IgnoreFileTypes.Add('.pas');
   oxedAssets.IgnoreFileTypes.Add('.pp');
   oxedAssets.IgnoreFileTypes.Add('.inc');
   oxedAssets.IgnoreFileTypes.Add('.gitignore');
   oxedAssets.IgnoreFileTypes.Add('.blend');
   oxedAssets.IgnoreFileTypes.Add('.temp');
   oxedAssets.IgnoreFileTypes.Add('.tmp');
   oxedAssets.IgnoreFileTypes.Add('.md');

   oxedAssets.IgnoreDirectories.Add('backup');

END.
