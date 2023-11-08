{
   uAndroidAssets
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uAndroidAssets;

INTERFACE

   USES
      ctypes, jni, native_activity, asset_manager, android_log_helper,
      uStd, StringUtils, uFile, uAndroid, uAndroidAssetFile;

TYPE

   { androidTAssetManager }

   androidTAssetManager = record
      GlobalRef: jobject;
      Manager: PAAssetManager;

      {get the asset manager from a given activity}
      procedure Get(activity: PANativeActivity);
      {done with the asset manager}
      procedure Done();

      {open a file from the assets}
      function Open(const path: StdString; out f: TFile): boolean;
   end;

VAR
   androidAssetManager: androidTAssetManager;

IMPLEMENTATION

procedure androidTAssetManager.Get(activity: PANativeActivity);
var
   env: PJNIEnv;
   activity_class: jclass;
   asset_manager: jobject;
   getAssetsId: jmethodID;

   mainDir: PAAssetDir;
   assetPath: PChar;

begin
   if(activity^.assetManager <> nil) then begin
      Manager := activity^.assetManager;
      GlobalRef := nil;
   end;

   mainDir := AAssetManager_openDir(Manager, '');

   if(mainDir <> nil) then begin
      repeat
         assetPath := AAssetDir_getNextFileName(mainDir);

         if(assetPath <> nil) then
            logi('Asset: ' + assetPath);
      until assetPath = nil;
   end else
      logi('No asset files found');

   AAssetDir_close(mainDir);

   if(Manager <> nil) then
      exit;

   env := mainThreadEnv;

   activity_class := env^^.GetObjectClass(env, activity);
   getAssetsId := env^^.GetMethodID(env, activity_class, 'getAssets', '()Landroid/content/res/AssetManager;');
   asset_manager := env^^.CallObjectMethod(env, activity, getAssetsId);

   GlobalRef := env^^.NewGlobalRef(env, asset_manager);

   Manager := AAssetManager_fromJava(env, GlobalRef);
end;

procedure androidTAssetManager.Done();
begin
   if(GlobalRef <> nil) then
      mainThreadEnv^^.DeleteGlobalRef(mainThreadEnv, GlobalRef);
end;

function androidTAssetManager.Open(const path: StdString; out f: TFile): boolean;
var
   start,
   length: cint64;
   asset: PAAsset;
   handle: fTHandle;

begin
   Result := false;
   fFile.Init(f);

   {assign a standard file handler}
   f.AssignHandler(androidAssetFileHandler);

   if(f.Error = 0) then begin
      {open the actual asset}
      asset := AAssetManager_open(Manager, pchar(path), AASSET_MODE_RANDOM);

      if(asset = nil) then begin
         loge('Asset manager failed to open: ' + path);
         f.RaiseError(eIO);
         exit(false);
      end;

      {get a file handle for the asset}
      handle := AAsset_openFileDescriptor64(asset, @start, @length);

      if(handle > 0) then begin
         {set defaults}
         f.SetDefaults(fcfREAD, path);

         f.Handle       := handle;
         f.ExtData      := asset;
         f.fSize        := length;
         f.fSizeLimit   := length;
         f.fOffset      := start;

         exit(True);
      end else
         loge('Failed to open asset file descriptor: ' + path + ' (returned: ' + sf(handle) + ')');
   end;

   f.CloseAndDestroy();
   f.fMode := fcfNONE;
end;

END.
