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

   { TBufferedAndroidAssetFileHandler }

   TBufferedAndroidAssetFileHandler = object(TUnixBufferedFileHandler)
      constructor Create();

      procedure Open(var f: TFile); virtual;
      procedure Close(var f: TFile); virtual;
      procedure OnBufferSet(var f: TFile); virtual;
   end;

VAR
   androidAssetFileHandler: TAndroidAssetFileHandler;
   androidBufferedAssetFileHandler: TBufferedAndroidAssetFileHandler;

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
   {if buffering set}
   if(f.bSize > 0) then
      f.pHandler := @androidBufferedAssetFileHandler
   {if buffering not set}
   else
      f.pHandler := @androidAssetFileHandler;
end;

{ TBufferedAndroidAssetFileHandler }

constructor TBufferedAndroidAssetFileHandler.Create();
begin
   inherited;

   Name := 'android_buffered_asset';
   UseBuffering := true;
end;

procedure TBufferedAndroidAssetFileHandler.Open(var f: TFile);
begin
   f.AutoSetBuffer();
end;

procedure TBufferedAndroidAssetFileHandler.Close(var f: TFile);
begin
   if(f.Handle > 0) then begin
      FpClose(f.Handle);
      unxfIoErr(f);
   end;

   if(f.ExtData <> nil) then
      AAsset_close(PAAsset(f.ExtData));
end;

procedure TBufferedAndroidAssetFileHandler.OnBufferSet(var f: TFile);
begin
   {if buffering set}
   if(f.bSize > 0) then
      f.pHandler := @androidBufferedAssetFileHandler
   {if buffering not set}
   else
      f.pHandler := @androidAssetFileHandler;
end;

INITIALIZATION
   androidAssetFileHandler.Create();
   androidBufferedAssetFileHandler.Create();

END.
