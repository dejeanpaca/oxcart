{
   oxeduAssets, oxed asset management
   Copyright (C) 2020. Dejan Boras

   TODO: Ignore oX data files which are not used
}

{$INCLUDE oxheader.inc}
UNIT oxeduAssets;

INTERFACE

   USES
      uStd, StringUtils, uLog, uFilePathList,
      {ox}
      oxuPaths,
      {oxed}
      uOXED, oxeduPackageTypes, oxeduPackage, oxeduProjectManagement;

CONST
   OX_NO_ASSETS_FILE = '.noassets';

TYPE

   { oxedTAssetsIgnorePaths }

   oxedTAssetsIgnorePaths = record
      FileTypes,
      Directories: TFilePathStringList;

      class procedure Initialize(out ig: oxedTAssetsIgnorePaths); static;
   end;

   { oxedTAssets }

   oxedTAssets = record
      {a package containing oX data (assets)}
      oxDataPackage: oxedTPackage;
      {a package containing oX code}
      oxPackage: oxedTPackage;

      {ignore these file types when building (don't copy over)}
      Ignore,
      ProjectIgnore: oxedTAssetsIgnorePaths;

      function ShouldIgnore(const ext: StdString): boolean;
      function ShouldIgnoreDirectory(const name: StdString): boolean;

      {add a file ignore}
      procedure AddFileIgnore(const path: StdString);
      {remove a file ignore}
      procedure RemoveFileIgnore(const path: StdString);

      {add a directory ignore}
      procedure AddDirectoryIgnore(const path: StdString);
      {remove a directory ignore}
      procedure RemoveDirectoryIgnore(const path: StdString);

      function IsLastPath(const path: StdString; var list: TSimpleStringList): boolean;
   end;

VAR
   oxedAssets: oxedTAssets;

IMPLEMENTATION

{ oxedTAssetsIgnorePaths }

class procedure oxedTAssetsIgnorePaths.Initialize(out ig: oxedTAssetsIgnorePaths);
begin
   ZeroOut(ig, SizeOf(ig));
   TSimpleStringList.Initialize(ig.Directories, 128);
   TSimpleStringList.Initialize(ig.FileTypes, 128);
end;

{ oxedTAssets }

function oxedTAssets.ShouldIgnore(const ext: StdString): boolean;
{$IFDEF WINDOWS}
var
   lext: StdString;
{$ENDIF}

begin
   {$IFDEF WINDOWS}
   lext := LowerCase(ext);

   if(Ignore.FileTypes.FindLowercase(lext) >= 0) or (ProjectIgnore.FileTypes.FindLowercase(lext) >= 0) then
      exit(true);
   {$ELSE}
   if(Ignore.FileTypes.FindString(ext) >= 0) or (ProjectIgnore.FileTypes.FindString(ext) >= 0) then
      exit(true);
   {$ENDIF}

   Result := false;
end;

function oxedTAssets.ShouldIgnoreDirectory(const name: StdString): boolean;
begin
   Result := IsLastPath(name, Ignore.Directories) or IsLastPath(name, ProjectIgnore.Directories);
end;

procedure oxedTAssets.AddFileIgnore(const path: StdString);
begin
   if(path <> '') then
      Ignore.FileTypes.AddUniquePath(path);
end;

procedure oxedTAssets.RemoveFileIgnore(const path: StdString);
begin
   if(path <> '') then
      Ignore.FileTypes.RemovePath(path);
end;

procedure oxedTAssets.AddDirectoryIgnore(const path: StdString);
begin
   if(path <> '') then
      Ignore.Directories.AddUniquePath(path);
end;

procedure oxedTAssets.RemoveDirectoryIgnore(const path: StdString);
begin
   if(path <> '') then
      Ignore.Directories.RemovePath(path);
end;

function oxedTAssets.IsLastPath(const path: StdString; var list: TSimpleStringList): boolean;
var
   i,
   len,
   p: loopint;
{$IFDEF WINDOWS}
   lpath: StdString;
{$ENDIF}

begin
   Result := false;

   if(path <> '') then begin
      {$IFDEF WINDOWS}
      lpath := LowerCase(path);
      len := Length(lpath);
      {$ELSE}
      len := length(path);
      {$ENDIF}

      for i := 0 to list.n - 1 do begin
         p := len - Length(list.List[i]) + 1;

         {mismatched length}
         if(p < 0) then
            continue;

         {$IFDEF WINDOWS}
         if StringPos(lpath, list.List[i], p) <> 0 then begin
         {$ELSE}
         if StringPos(path, list.List[i], p) <> 0 then begin
         {$ENDIF}
            dec(p);
            if(p > 0) then begin
               {make sure we don't match with a partial path}
               if(path[p] = DirectorySeparator) then
                  exit(true);
            end else
               exit(true);
         end;
      end;
   end;
end;

procedure init();
begin
   oxedAssets.oxDataPackage.Id := 'ox_data';
   oxedAssets.oxDataPackage.Path := oxPaths.BasePath + 'data' + DirSep;

   oxedAssets.oxPackage.Id := 'ox';
   oxedAssets.oxPackage.Path := oxPaths.BasePath;
end;

procedure ResetIgnores();
begin
   oxedAssets.Ignore.FileTypes.Dispose();
   oxedAssets.Ignore.Directories.Dispose();

   oxedAssets.Ignore.FileTypes.Add('.pas');
   oxedAssets.Ignore.FileTypes.Add('.pp');
   oxedAssets.Ignore.FileTypes.Add('.inc');
   oxedAssets.Ignore.FileTypes.Add('.blend');
   oxedAssets.Ignore.FileTypes.Add('.temp');
   oxedAssets.Ignore.FileTypes.Add('.tmp');
   oxedAssets.Ignore.FileTypes.Add('.md');
   oxedAssets.Ignore.FileTypes.Add(OX_NO_ASSETS_FILE);
   oxedAssets.Ignore.FileTypes.Add(OX_PACKAGE_PROPS_FILE_NAME);

   oxedAssets.Ignore.Directories.Add('backup');
end;

INITIALIZATION
   oxed.Init.Add('assets', @init);

   oxedTPackage.Init(oxedAssets.oxDataPackage);
   oxedTPackage.Init(oxedAssets.oxPackage);

   oxedTAssetsIgnorePaths.Initialize(oxedAssets.Ignore);
   oxedTAssetsIgnorePaths.Initialize(oxedAssets.ProjectIgnore);

   oxedProjectManagement.OnPreOpen.Add(@ResetIgnores);

END.
