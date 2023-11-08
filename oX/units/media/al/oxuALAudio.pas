{
   oxuALAudio, OpenAL audio backend
   Copyright (C) 2017. Dejan Boras

   Started On:    30.08.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuALAudio;

INTERFACE

   USES
     uStd, uLog, vmVector, StringUtils,
     {dal}
     openal,
     {ox}
     oxuAudioBase, oxuAudio, oxuGlobalInstances,
     {AL}
     oxuALTypes, oxuAL, oxuALDevices, oxuALContext, oxuALExtensions
     {$IFDEF OX_FEATURE_CONSOLE}
     , oxuALConsole
     {$ENDIF};

TYPE

   { oxTALBuffer }

   oxTALBuffer = class(oxTAudioBuffer)
      alBuffer: oxalTBuffer;
      alFormat: ALenum;

      constructor Create; override;
      destructor Destroy; override;
   end;

   { oxTALSource }

   oxTALSource = class(oxTAudioSource)
      Source: oxalTSource;

      constructor Create; override;
      destructor Destroy; override;

      procedure SetBuffer(newBuffer: oxTAudioBuffer); override;
      procedure SetLooping(newLooping: boolean); override;
      procedure SetPitch(newPitch: single); override;
      procedure SetVolume(left, right: single); override;

      function Play: boolean; override;
      function Stop: boolean; override;
      function Pause: boolean; override;
      function Rewind: boolean; override;
   end;

   { oxTALListener}
   oxTALListener = class(oxTAudioListener)
      constructor Create; override;
      destructor Destroy; override;
   end;

   { oxTALAudioHandler }
   oxTALAudioHandler = class(oxTAudioHandler)
      pExtensions: oxPALExtensions;
      pDevices: oxPALDevicesGlobal;
      pContext: oxalTContext;
      pGlobal: oxPALGlobal;

      constructor Create(); override;
      destructor Destroy(); override;

      function GenerateBuffer(var buffer: oxTAudioBuffer; var data: oxTAudioBufferData): loopint; override;

      protected
         procedure OnInitialize; override;
         procedure OnDeinitialize; override;
   end;

IMPLEMENTATION

{ oxTALListener }

constructor oxTALListener.Create;
begin

end;

destructor oxTALListener.Destroy;
begin
   inherited Destroy;
end;

{ oxTALBuffer }

constructor oxTALBuffer.Create;
begin
   inherited Create;

   alBuffer.Create();
end;

destructor oxTALBuffer.Destroy;
begin
   inherited Destroy;

   alBuffer.Destroy();
end;

{ oxTALSource }

constructor oxTALSource.Create;
begin
   inherited;
   Source.Create;

   if(Source <> 0) then begin
      alSourcef(Source, AL_PITCH, 1.0);
      alSourcef (Source, AL_GAIN, 1.0);
      alSourcefv(Source, AL_POSITION, vmvZero3f);
      alSourcefv(Source, AL_VELOCITY, vmvZero3f);
      alSourcei (Source, AL_LOOPING,  AL_FALSE);
   end;
end;

destructor oxTALSource.Destroy;
begin
   inherited Destroy;

   Source.Destroy();
end;

procedure oxTALSource.SetBuffer(newBuffer: oxTAudioBuffer);
begin
   inherited SetBuffer(newBuffer);

   alSourcei(Source, AL_BUFFER, oxTALBuffer(newBuffer).alBuffer);
end;

procedure oxTALSource.SetLooping(newLooping: boolean);
begin
   Looping := newLooping;

   if(newLooping) then
      alSourcei(Source, AL_LOOPING, AL_TRUE)
   else
      alSourcei(Source, AL_LOOPING, AL_FALSE);
end;

procedure oxTALSource.SetPitch(newPitch: single);
begin
   Pitch := newPitch;

   alSourcef(Source, AL_PITCH, newPitch);
end;

procedure oxTALSource.SetVolume(left, right: single);
begin
   LeftVolume := left;
   RightVolume := right;

   alSourcef(Source, AL_GAIN, LeftVolume);
end;

function oxTALSource.Play: boolean;
begin
   Playing := true;
   Paused := false;

   if(Source <> 0) then begin
      alSourcePlay(Source);
      result := oxal.GetError('failed playing source ' + sf(Source)) = AL_NO_ERROR;
   end else
      Result := true;
end;

function oxTALSource.Stop: boolean;
begin
   Playing := false;
   Paused := false;

   if(Source <> 0) then begin
      alSourceStop(Source);
      result := oxal.GetError('failed stopping source ' + sf(Source)) = AL_NO_ERROR;
   end else
      Result := true;
end;

function oxTALSource.Pause: boolean;
begin
   Playing := false;
   Paused := true;

   if(Source <> 0) then begin
      alSourceStop(Source);
      result := oxal.GetError('failed stopping source ' + sf(Source)) = AL_NO_ERROR;
   end else
      Result := true;
end;

function oxTALSource.Rewind: boolean;
begin
   Playing := false;
   Paused := false;

   if(Source <> 0) then begin
      alSourceRewind(Source);
      Result := oxal.GetError('failed stopping source ' + sf(Source)) = AL_NO_ERROR;
   end else
      Result := true;
end;

{ AUDIO HANDLER }

constructor oxTALAudioHandler.Create();
begin
   inherited;

   SeparateVolumesSupported := false;

   Types.Buffer := oxTALBuffer;
   Types.Source := oxTALSource;
   Types.Listener := oxTALListener;

   pExtensions := @oxalExtensions;
   pDevices := @oxalDevices;
   pGlobal := @oxal;
end;

destructor oxTALAudioHandler.Destroy;
begin
   inherited Destroy;
end;

function oxTALAudioHandler.GenerateBuffer(var buffer: oxTAudioBuffer; var data: oxTAudioBufferData): loopint;
var
   buf: oxTALBuffer;

begin
   buf := oxTALBuffer(buffer);
   buffer := buf;

   buf.alFormat := AL_NONE;

   case data.nChannels of
      1: begin
         if(data.BitsPerSample = 8) then
            buf.alFormat := AL_FORMAT_MONO8
         else if (data.BitsPerSample = 16) then
            buf.alFormat := AL_FORMAT_MONO16
      end;
      2: begin
         if(data.BitsPerSample = 8) then
            buf.alFormat := AL_FORMAT_STEREO8
         else if (data.BitsPerSample = 16) then
            buf.alFormat := AL_FORMAT_STEREO16
      end;
   end;

   if(buf.alFormat = AL_NONE) then
      exit(eUNSUPPORTED);

   {load wave data into a bufer}
   if(buf.alBuffer.Create()) then begin
      if(not buf.alBuffer.Data(buf.alFormat, data.Data^, buf.Size, buf.Frequency)) then
         exit(eFAIL);
   end else
      exit(eFAIL);

   Result := eNONE;
end;

procedure oxTALAudioHandler.OnInitialize;
{$IFDEF OX_LIBRARY}
var
   extHandler: oxTALAudioHandler;
{$ENDIF}

begin
   {$IFNDEF OX_LIBRARY}
   oxalContext := oxalTContext.Create();
   pContext := oxalContext;

   oxalDevices.OpenDefault();

   oxalDevices.GetDevices();

   {if we need to create a context and the device creating caused no error}
   if(oxal.ErrorCode = AL_NO_ERROR) then begin
      if(not oxalDevices.OpenPreferred()) then begin
         {failed to open preferred, so fallback to default}
         oxalDevices.Close();
         oxalDevices.OpenDefault();

         log.w('al > Reverted back to default device');
      end;

      if(oxalTContext.CreateDefault(oxalDevices.Device)) then begin
         oxal.GetInformation();

         {device extensions}
         oxalDevices.DeviceExtensions.GetExtensions(oxalDevices.Device);
         oxalExtensions.LogExtensions('Device');

         {get extensions}
         oxalExtensions.GetExtensions(nil);
         oxalExtensions.LogExtensions('Extensions');
     end else
        log.i('Failed to create default context.');
   end else
      log.i('Failed to open default device.');

   {initialized oxAL}
   log.Leave();
   {$ELSE}
   extHandler := oxTALAudioHandler(ExternalHandler);

   oxalExtensions := oxTALExtensions(extHandler.pExtensions^);
   oxalDevices := oxTALDevicesGlobal(extHandler.pDevices^);
   oxalContext := extHandler.pContext;
   oxalCurrentContext := extHandler.pContext;
   oxal := extHandler.pGlobal^;
   {$ENDIF}

   Initialized := true;
end;

procedure oxTALAudioHandler.OnDeinitialize;
begin
   {$IFNDEF OX_LIBRARY}
   {destroy the default context}
   if(oxalContext <> nil) then begin
      if(not oxalContext.Dispose()) then
         log.i('Failed destroying the context.');

     FreeObject(oxalContext);
   end;

   oxalDevices.Close();

   {dispose}
   oxalExtensions.DisposeExtensions();
   oxalDevices.DeInitialize();
   {$ENDIF}

   Initialized := false;
end;

procedure setHandler();
begin
   oxAudio.DestroyHandler();

   oxa := oxTALAudioHandler.Create();
end;

INITIALIZATION
   oxAudio.onSetHandler := @setHandler;

END.

