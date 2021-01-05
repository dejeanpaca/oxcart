{
   uAndroidAssetFile
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uAndroidAssetFile;

INTERFACE

   USES
      BaseUnix,
      asset_manager,
      uUnix, uFile, ufhUnix;

TYPE

   { TAndroidAssetFileHandler }

   TAndroidAssetFileHandler = object(TUnixFileHandler)
      constructor Create();

      procedure Open(var f: TFile); virtual;
      procedure Close(var f: TFile); virtual;
      procedure OnBufferSet(var f: TFile); virtual;
   end;

VAR
   androidAssetFileHandler: TAndroidAssetFileHandler;

IMPLEMENTATION

{ TAndroidAssetFileHandler }

constructor TAndroidAssetFileHandler.Create();
begin
   Name := 'android_asset';
   UseBuffering := false;
end;

procedure TAndroidAssetFileHandler.Open(var f: TFile);
begin
   f.AutoSetBuffer();
end;

procedure TAndroidAssetFileHandler.Close(var f: TFile);
begin
   if(f.Handle > 0) then begin
      FpClose(f.Handle);
      unxfIoErr(f);
   end;

   if(f.ExtData <> nil) then
      AAsset_close(PAAsset(f.ExtData));
end;

procedure TAndroidAssetFileHandler.OnBufferSet(var f: TFile);
begin
   {NOTE: We don't support buffered handler swapping here}
end;

INITIALIZATION
   androidAssetFileHandler.Create();

END.
