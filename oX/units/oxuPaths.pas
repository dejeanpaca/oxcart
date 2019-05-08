{
   oxuPaths, common oX paths
   Copyright (C) 2011. Dejan Boras

   Started On:    27.10.2013.
}

{$INCLUDE oxdefines.inc}
UNIT oxuPaths;

INTERFACE

   USES
     sysutils, uStd, uFileUtils, uLog, appuPaths, oxuRunRoutines,
     {ox}
     uOX;

CONST
   oxDataPath = 'data' + DirectorySeparator;
   oxTexturesDefaultPath   = oxDataPath + 'textures' + DirectorySeparator;
   oxUIPath = oxDataPath +'ui' + DirectorySeparator;
   oxFontsDefaultPath      = oxDataPath + 'fonts' + DirectorySeparator;
   oxShadersDefaultPath    = oxDataPath + 'shaders' + DirectorySeparator;

   OX_ASSET_PATH_ENV = 'OX_ASSET_PATH';

TYPE
   { oxTAssetPathsGlobal }

   oxTAssetPathsGlobal = record
      {working directory used as base}
      WorkingDirectory: string;
      {list of asset paths}
      List: TPreallocatedStringArrayList;

      {return a path at which location an asset can be found}
      function Find(const asset: string): string;
      {add an asset path}
      procedure Add(const assetPath: string);
   end;


   { oxTPaths }
   oxTPaths = record
      Data,
      Textures,
      UI,
      Fonts,
      Shaders: string;
   end;

VAR
   oxPaths: oxTPaths;
   oxAssetPaths: oxTAssetPathsGlobal;

IMPLEMENTATION

{ oxTAssetPathsGlobal }

function oxTAssetPathsGlobal.Find(const asset: string): string;
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

   result := asset;
end;

procedure oxTAssetPathsGlobal.Add(const assetPath: string);
begin
   if(assetPath <> '') then begin
      List.Add(IncludeTrailingPathDelimiter(assetPath));

      if(DirectoryExists(assetPath)) then
         Log.v('ox > added asset path: ' + assetPath)
      else
        Log.e('ox > invalid asset path: ' + assetPath)
   end;
end;


procedure init();
{$IFDEF OX_DEBUG}
var
   assetPath: string;
{$ENDIF}

begin
   oxAssetPaths.WorkingDirectory := appPath.GetExecutablePath();

   if(oxAssetPaths.WorkingDirectory <> '') then
      oxAssetPaths.WorkingDirectory := IncludeTrailingPathDelimiter(oxAssetPaths.WorkingDirectory);

   if(oxAssetPaths.WorkingDirectory <> '') then
      log.v('Asset base path: ' + oxAssetPaths.WorkingDirectory);

   {$IFDEF OX_DEBUG}
   assetPath := GetEnvironmentVariable(OX_ASSET_PATH_ENV);
   oxAssetPaths.Add(assetPath);
   {$ENDIF}
end;

procedure deinit();
begin
   oxAssetPaths.List.Dispose();
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   oxPaths.Data         := oxDataPath;
   oxPaths.Textures     := oxTexturesDefaultPath;
   oxPaths.UI           := oxUIPath;
   oxPaths.Fonts        := oxFontsDefaultPath;
   oxPaths.Shaders      := oxShadersDefaultPath;

   oxAssetPaths.List.Initialize(oxAssetPaths.List);
   ox.PreInit.Add(initRoutines, 'ox.assetpaths', @init, @deinit);

END.

