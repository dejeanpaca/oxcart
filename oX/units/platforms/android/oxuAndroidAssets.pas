{
   oxuAndroidAssets
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuAndroidAssets;

INTERFACE

   USES
      uStd, uFile, ypkuFS,
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

   if(androidAssetManager.Open(fn, fData)) then begin
      logi('Opened assets file');

      if(ypkfs.Add(fData) = nil) then
         loge('Failed to add file to ypkfs: ' + fn);
   end else
      loge('Failed to open assets file: ' + fn);
end;

procedure oxTAndroidAssets.DeInitialize();
begin
   if(fData.IsOpened()) then
      fData.CloseAndDestroy();
end;

END.
