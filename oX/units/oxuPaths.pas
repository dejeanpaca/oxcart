{
   oxuPaths, common oX paths
   Copyright (C) 2011. Dejan Boras

   Started On:    27.10.2013.
}

{$INCLUDE oxdefines.inc}
UNIT oxuPaths;

INTERFACE

   USES
     sysutils, uStd, uFileUtils, uLog, StringUtils,
     {app}
     appuPaths,
     {ox}
     uOX, oxuRunRoutines, oxuGlobalInstances;

CONST
   oxDataPath = 'data' + DirectorySeparator;
   oxTexturesDefaultPath   = oxDataPath + 'textures' + DirectorySeparator;
   oxUIPath = oxDataPath +'ui' + DirectorySeparator;
   oxFontsDefaultPath      = oxDataPath + 'fonts' + DirectorySeparator;
   oxShadersDefaultPath    = oxDataPath + 'shaders' + DirectorySeparator;

   OX_ASSET_PATH_ENV = 'OX_ASSET_PATH';

TYPE
   oxPPaths = ^oxTPaths;

   { oxTPaths }
   oxTPaths = record
      Data,
      Textures,
      UI,
      Fonts,
      Shaders: string;

      {base oX asset paths (should equal WorkingDirectory in standalone mode)}
      BasePath,
      {working directory used as base}
      WorkingDirectory: string;
      {list of asset paths}
      List: TPreallocatedStringArrayList;

      {return a path at which location an asset can be found}
      function Find(const asset: string): string;
      {return a path at which location of an asset directory can be found}
      function FindDirectory(const asset: string): string;
      {add an asset path}
      procedure Add(const assetPath: string);
   end;

VAR
   oxPaths: oxTPaths;

IMPLEMENTATION

{ oxTPaths }

function oxTPaths.Find(const asset: string): string;
var
   i: loopint;
   fn: string;

begin
   if(FileUtils.Exists(WorkingDirectory + asset) > -1) then
      exit(WorkingDirectory + asset);

   for i := 0 to (List.n - 1) do begin
      fn := List.List[i] + asset;

      if(FileUtils.Exists(fn) > -1) then
         exit(fn);
   end;

   Result := asset;
end;

function oxTPaths.FindDirectory(const asset: string): string;
var
   i: loopint;
   path: string;

begin
   if(FileUtils.DirectoryExists(WorkingDirectory + asset)) then
      exit(WorkingDirectory + asset);

   for i := 0 to (List.n - 1) do begin
      path := List.List[i] + asset;

      if(DirectoryExists(path)) then
         exit(path);
   end;

   Result := asset;
end;

procedure oxTPaths.Add(const assetPath: string);
begin
   if(assetPath <> '') then begin
      List.Add(IncludeTrailingPathDelimiter(assetPath));

      if(DirectoryExists(assetPath)) then
         Log.v('ox > Added asset path: ' + assetPath)
      else
        Log.e('ox > Invalid asset path: ' + assetPath)
   end;
end;

function tryDetermineAssetPath(startPath: string): string;
var
   path: String;

begin
   path := IncludeTrailingPathDelimiter(startPath);

   repeat
      if(FileUtils.Exists(path + 'here.oxsource') > 0) then begin
         break;
      end else begin
         if(path = IncludeTrailingPathDelimiterNonEmpty(GetParentDirectory(path))) or (path = '') then begin
            path := '';
            break;
         end;

         path := IncludeTrailingPathDelimiterNonEmpty(GetParentDirectory(path));
      end;
   until (path = '');

   if(path <> '') then
      path := path + 'oX' + DirectorySeparator;

   Result := path;
end;

{$IFDEF OX_LIBRARY}
procedure initLibrary();
var
   i: loopint;
   ext: oxPPaths;

begin
   ext := oxExternalGlobalInstances.FindInstancePtr('oxTPaths');
   if(ext = nil) then
      exit;

   oxPaths.Data         := ext^.Data;
   oxPaths.Textures     := ext^.Textures;
   oxPaths.UI           := ext^.UI;
   oxPaths.Fonts        := ext^.Fonts;
   oxPaths.Shaders      := ext^.Shaders;

   oxPaths.BasePath := ext^.BasePath;
   oxPaths.WorkingDirectory := ext^.WorkingDirectory;

   for i := 0 to ext^.List.n - 1 do begin
      oxPaths.List.Add(ext^.List[i]);
   end;
end;
{$ENDIF}

{$IFNDEF OX_LIBRARY}
procedure init();
{$IFDEF OX_DEBUG}
var
   assetPath: string;
{$ENDIF}

begin
   oxPaths.WorkingDirectory := appPath.GetExecutablePath();

   if(oxPaths.WorkingDirectory <> '') then
      oxPaths.WorkingDirectory := IncludeTrailingPathDelimiter(oxPaths.WorkingDirectory);

   if(oxPaths.WorkingDirectory <> '') then
      log.v('ox > Asset base path: ' + oxPaths.WorkingDirectory);

   {$IFDEF OX_DEBUG}
   assetPath := GetEnvironmentVariable(OX_ASSET_PATH_ENV);

   {we'll try to determine asset path ourselves}
   if(assetPath = '') then
      assetPath := tryDetermineAssetPath(GetCurrentDir());

   if(assetPath <> '') then begin
      log.v('ox > Auto determined asset path: ' + assetPath);
      oxPaths.BasePath := assetPath;
      oxPaths.Add(assetPath);
   end;
   {$ENDIF}
end;
{$ENDIF}

procedure deinit();
begin
   oxPaths.List.Dispose();
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   oxPaths.Data         := oxDataPath;
   oxPaths.Textures     := oxTexturesDefaultPath;
   oxPaths.UI           := oxUIPath;
   oxPaths.Fonts        := oxFontsDefaultPath;
   oxPaths.Shaders      := oxShadersDefaultPath;

   oxPaths.List.Initialize(oxPaths.List);
   {$IFNDEF OX_LIBRARY}
   ox.PreInit.Add(initRoutines, 'ox.paths', @init, @deinit);
   {$ELSE}
   ox.PreInit.Add(initRoutines, 'ox.paths', @initLibrary, @deinit);
   {$ENDIF}

   oxGlobalInstances.Add('oxTPaths', @oxPaths);

END.
