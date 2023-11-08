{
   oxuAudio, handles audio
   Copyright (C) 2012. Dejan Boras

   Started On:    23.01.2012.
}

{$INCLUDE oxdefines.inc}
UNIT oxuAudio;

INTERFACE

   USES
      uStd, uLog,
      {ox}
      uOX, oxuRunRoutines, oxuAudioBase, oxuGlobalInstances;

TYPE
   oxTAudioGlobal = record helper for oxTAudioBase
      procedure Initialize();
      procedure Deinitialize();
      procedure DestroyHandler();

      {checks the state of oX audio and returns true if Ok}
      function Ok(): boolean;
   end;

IMPLEMENTATION

procedure oxTAudioGlobal.Initialize();
begin
   log.Enter('oxAudio initialization');

   if(Enabled) then begin
      if (onSetHandler) <> nil then
         onSetHandler();
   end else
      oxa := oxTAudioHandler.Create();

   if (onPreInitialize <> nil) then
      onPreInitialize();

   if(oxa <> nil) then begin
      oxa.Initialize();

      if(Enabled) then
         log.i('Done')
      else
         log.w('Audio is disabled');

      Initialized := true;
   end else
      log.w('Failed to initialize audio since no audio handler is set.');

   log.Leave();
end;

procedure oxTAudioGlobal.Deinitialize();
begin
   if(Initialized) then begin
      log.Enter('oxAudio de-initialization');
      if (onDeInitialize <> nil) then
         onDeInitialize();

      oxa.Deinitialize();
      DestroyHandler();
      Initialized := false;

      log.i('Done');
      log.Leave();
   end;
end;

procedure oxTAudioGlobal.DestroyHandler();
begin
   FreeObject(oxa);
end;

function oxTAudioGlobal.Ok(): boolean;
begin
   result := (oxa <> nil) and Initialized and Enabled;
end;

procedure setDefaultHandler();
begin
   oxAudio.DestroyHandler();
   oxa := oxTAudioHandler.Create();
end;

procedure Initialize();
begin
   oxAudio.Initialize();
end;

procedure DeInitialize();
begin
   oxAudio.DeInitialize();
end;

function instanceGlobal(): TObject;
begin
   Result := oxTAudioHandler.Create();
end;

INITIALIZATION
   oxAudio.onSetHandler := @setDefaultHandler;

   oxGlobalInstances.Add(oxTAudioHandler, @oxa, @instanceGlobal)^.Allocate := false;

   ox.Init.Add('audio', @Initialize, @DeInitialize);

END.
