{
   uAndroidAssets
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uAndroidAssets;

INTERFACE

   USES
      jni, native_activity,
      uAndroid, asset_manager;

TYPE

   { androidTAssetManager }

   androidTAssetManager = record
      GlobalRef: jobject;
      Manager: PAAssetManager;

      {get the asset manager from a given activity}
      procedure Get(activity: PANativeActivity);
      {done with the asset manager}
      procedure Done();
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

begin
   if(activity^.assetManager <> nil) then begin
      Manager := activity^.assetManager;
      GlobalRef := nil;
      exit;
   end;

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

END.
