{
   oxuMedia, handles media
   Copyright (C) 2012. Dejan Boras

   Started On:    30.01.2012.
}

{$INCLUDE oxdefines.inc}
UNIT oxuMedia;

INTERFACE

   USES uLog,
      oxuMediaBase;

TYPE
   oxTMediaGlobal = record helper for oxTMediaBase
      procedure Initialize();
      procedure DeInitialize();

      function GetPlayer(): oxTMediaPlayer;
   end;

IMPLEMENTATION

procedure oxTMediaGlobal.Initialize();
begin
   if(enabled) then begin
      log.Enter('oxMedia initialization');

      if (onSetHandler) <> nil then
         onSetHandler();

      if (onPreInitialize <> nil) then
         onPreInitialize();

      initialized := true;
      log.i('Done');
      log.Leave();
   end;
end;

procedure oxTMediaGlobal.Deinitialize();
begin
   if(initialized) then begin
      log.Enter('oxMedia de-initialization');

      if (onDeInitialize <> nil) then
         onDeInitialize();

      log.i('Done');
      log.Leave();
   end;
end;

function oxTMediaGlobal.GetPlayer(): oxTMediaPlayer;
begin
   if(enabled) then begin
      if(pGetPlayer <> nil) then
         result := pGetPlayer()
      else
         result := oxTMediaPlayer.Create();
   end else
      result := nil;
end;

procedure Initialize();
begin
   oxMedia.Initialize();
end;

procedure DeInitialize();
begin
   oxMedia.DeInitialize();
end;

INITIALIZATION
  oxiProcs.Add('media', @Initialize, @DeInitialize);

  oxMedia.enabled := true;

END.

