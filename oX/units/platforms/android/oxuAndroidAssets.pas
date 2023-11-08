{
   oxuAndroidAssets
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuAndroidAssets;

INTERFACE

   USES
      uStd, uFile,
      {android}
      uAndroidAssets, android_log_helper;

TYPE

   { oxTAndroidAssets }

   oxTAndroidAssets = record
      fData: TFile;

      procedure Initialize();
      procedure DeInitialize();
   end;

VAR
   oxAndroidAssets: oxTAndroidAssets;

IMPLEMENTATION

{ oxTAndroidAssets }

procedure oxTAndroidAssets.Initialize();
var
   fn: StdString;

begin
   fn := 'data.ypk';

   if(androidAssetManager.Open(fn, fData)) then
      logi('Opened assets file')
   else
      loge('Failed to open assets file: ' + fn);
end;

procedure oxTAndroidAssets.DeInitialize();
begin
   if(fData.IsOpened()) then
      fData.Close();
end;

END.
