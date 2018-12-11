{
   oxuAudioBase, base oX audio resources
   Copyright (C) 2012. Dejan Boras

   Started On:    23.01.2012.
}

{$INCLUDE oxdefines.inc}
UNIT oxuAudioBase;

INTERFACE

   USES
     uStd, uLog,
     {ox}
     oxuTypes
     {$IFDEF OX_LIBRARY}
     , oxuGlobalInstances
     {$ENDIF};

CONST
   oxaDEFAULT_SOURCE_POINTER_INCREASE  = 256;

TYPE
   oxPAudioBufferData = ^oxTAudioBufferData;

   { oxTAudioBufferData }

   oxTAudioBufferData = record
      {raw audio information}
      nChannels,
      BitsPerSample,
      SampleRate,
      BytesPerSec,
      BlockAlign: loopint;

      {audio data is stored here before it's buffered with OpenAL}
      DataSize: loopint;
      Data: pointer;

      procedure Destroy();
   end;

   { oxTAudioBuffer }

   oxTAudioBuffer = class(oxTResource)
      {buffer frequency}
      Frequency,
      {buffer size}
      Size: loopint;
   end;

   { oxTAudioSource }

   oxTAudioSource = class
      {associated buffer}
      Buffer: oxTAudioBuffer;

      Priority: longint;
      Rate,
      Pitch: single;

      Playing,
      Looping,
      Paused: boolean;

      LeftVolume,
      RightVolume: single;

      constructor Create; virtual;

      function Play(): boolean; virtual;
      function Pause(): boolean; virtual;
      function Resume(): boolean; virtual;
      function Stop(): boolean; virtual;
      function Rewind(): boolean; virtual;

      procedure SetPriority(newPriority: longint); virtual;
      procedure SetRate(newRate: single); virtual;
      procedure SetLooping(newLooping: boolean); virtual;
      procedure SetPitch(newPitch: single); virtual;

      procedure SetBuffer(newBuffer: oxTAudioBuffer); virtual;
      procedure SetVolume(left, right: single); virtual;
      procedure SetVolume(volume: single); virtual;
   end;

   { oxTAudioListener }

   oxTAudioListener = class
      constructor Create; virtual;
   end;

   { types }

   oxTAudioBufferClass = class of oxTAudioBuffer;
   oxTAudioSourceClass = class of oxTAudioSource;
   oxTAudioListenerClass = class of oxTAudioListener;

   { oxTAudioHandler }

   oxTAudioHandler = class
      public
         Initialized: boolean;
         Listener: oxTAudioListener;

         nSourceIncrease,
         nSourcesTotal,
         nSourcesAvailable,

         SourceMax: longint;
         Sources: array of oxTAudioSource;
         {$IFDEF OX_LIBRARY_SUPPORT}
         ExternalHandler: oxTAudioHandler;
         {$ENDIF}

         {indicates whether separate volumes are supported}
         SeparateVolumesSupported: boolean;

         Types: record
            Buffer: oxTAudioBufferClass;
            Source: oxTAudioSourceClass;
            Listener: oxTAudioListenerClass;
         end;

         ErrorCode: longint;

         constructor Create(); virtual;

         procedure Initialize();
         procedure Deinitialize();

         function Play(sID: longint): boolean;
         function Pause(sID: longint): boolean;
         function Resume(sID: longint): boolean;
         function Stop(sID: longint): boolean;
         function Rewind(sID: longint): boolean;

         procedure PauseAll(); virtual;
         procedure ResumeAll(); virtual;
         procedure StopAll(); virtual;
         procedure PlayAll(); virtual;

         procedure SetPriority({%H-}sID: longint; priority: longint);
         procedure SetRate({%H-}sID: longint; rate: single);
         procedure SetVolume({%H-}sID: longint; volume: single);
         procedure SetVolume({%H-}sID: longint; lV, rV: single);
         procedure SetLoop({%H-}sID: longint; loop: boolean);
         procedure SetPitch({%H-}sID: loopint; pitch: single);

         function GetNewSource(): longint;
         procedure AllocateMoreSourcePointers();
         procedure DestroySource(sID: longint);
         procedure DestroyAllSources();

         {generate a buffer from buffer data}
         function GenerateBuffer(var {%H-}buffer: oxTAudioBuffer; var {%H-}data: oxTAudioBufferData): loopint; virtual;

         {error handling}
         procedure RaiseError(errcode: longint);

         function ValidSourceID(sID: longint): boolean;

         function InstanceSource(): oxTAudioSource;
         function InstanceBuffer(): oxTAudioBuffer;
         function InstanceListener(): oxTAudioListener;

         {setup the default listener}
         procedure SetupListener();

         protected
            procedure OnInitialize(); virtual;
            procedure OnDeinitialize(); virtual;
   end;

   oxTAudioBase = record
      Enabled,
      Initialized: boolean;

      onSetHandler: TProcedure;
      onPreInitialize,
      onDeInitialize: TProcedure;
   end;

VAR
   oxa: oxTAudioHandler = nil;
   oxAudio: oxTAudioBase;

IMPLEMENTATION

{ oxTAudioListener }

constructor oxTAudioListener.Create;
begin

end;

{ oxTAudioBufferData }

procedure oxTAudioBufferData.Destroy;
begin
   XFreeMem(Data);
   DataSize := 0;
end;

{ oxTAudioSource }

constructor oxTAudioSource.Create;
begin
   inherited;

   Priority      := 10;
   Rate          := 1.0;
   LeftVolume    := 1.0;
   RightVolume   := 1.0;
end;

function oxTAudioSource.Play: boolean;
begin
   Result := false;
end;

function oxTAudioSource.Pause: boolean;
begin
   Result := false;
end;

function oxTAudioSource.Resume: boolean;
begin
   Result := false;
end;

function oxTAudioSource.Stop: boolean;
begin
   Result := false;
end;

function oxTAudioSource.Rewind: boolean;
begin
   Result := false;
end;

procedure oxTAudioSource.SetPriority(newPriority: longint);
begin
   Priority := newPriority;
end;

procedure oxTAudioSource.SetRate(newRate: single);
begin
   Rate := newRate;
end;

procedure oxTAudioSource.SetLooping(newLooping: boolean);
begin
   Looping := newLooping;
end;

procedure oxTAudioSource.SetPitch(newPitch: single);
begin
   Pitch := newPitch;
end;

procedure oxTAudioSource.SetBuffer(newBuffer: oxTAudioBuffer);
begin
   Buffer := newBuffer;
end;

procedure oxTAudioSource.SetVolume(left, right: single);
begin
   LeftVolume := left;
   RightVolume := right;
end;

procedure oxTAudioSource.SetVolume(volume: single);
begin
   LeftVolume := volume;
   RightVolume := volume;
end;

{ oxTAudioHandler }

constructor oxTAudioHandler.Create();
begin
   SourceMax := -1;
   SeparateVolumesSupported := true;

   Types.Buffer := oxTAudioBuffer;
   Types.Source := oxTAudioSource;
   Types.Listener := oxTAudioListener;
end;

procedure oxTAudioHandler.Initialize();
begin
   nSourceIncrease := oxaDEFAULT_SOURCE_POINTER_INCREASE;
   ErrorCode := eNONE;

   {$IFDEF OX_LIBRARY}
   ExternalHandler := oxTAudioHandler(oxGlobalInstances.FindInstance('oxTAudioHandler'));
   {$ENDIF}

   AllocateMoreSourcePointers();

   OnInitialize();

   SetupListener();
end;

procedure oxTAudioHandler.Deinitialize();
begin
   DestroyAllSources();
   OnDeInitialize();

   FreeObject(Listener);
end;

function oxTAudioHandler.Play(sID: longint): boolean;
begin
   if(ValidSourceID(sID)) then
      Result := Sources[sID].Play()
   else
      Result := false;
end;

function oxTAudioHandler.Pause(sID: longint): boolean;
begin
   if(ValidSourceID(sID)) then
      Result := Sources[sID].Pause()
   else
      Result := false;
end;

function oxTAudioHandler.Resume(sID: longint): boolean;
begin
   if(ValidSourceID(sID)) then
      Result := Sources[sID].Resume()
   else
      Result := false;
end;

function oxTAudioHandler.Stop(sID: longint): boolean;
begin
   if(ValidSourceID(sID)) then
      Result := Sources[sID].Stop()
   else
      Result := false;
end;

function oxTAudioHandler.Rewind(sID: longint): boolean;
begin
   if(ValidSourceID(sID)) then
      Result := Sources[sID].Rewind()
   else
      Result := false;
end;

procedure oxTAudioHandler.SetPriority(sID: longint; priority: longint);
begin
   if(ValidSourceID(sID)) then
      Sources[sID].SetPriority(priority);
end;

procedure oxTAudioHandler.SetRate(sID: longint; rate: single);
begin
   if(ValidSourceID(sID)) then
      Sources[sID].SetRate(rate);
end;

procedure oxTAudioHandler.SetVolume(sID: longint; volume: single);
begin
   if(ValidSourceID(sID)) then
      Sources[sID].SetVolume(volume);
end;

procedure oxTAudioHandler.SetVolume(sID: longint; lV, rV: single);
begin
   if(ValidSourceID(sID)) then begin
      Sources[sID].LeftVolume := lV;
      Sources[sID].RightVolume := rV;
   end;
end;

procedure oxTAudioHandler.SetLoop(sID: longint; loop: boolean);
begin
   if(ValidSourceID(sID)) then
      Sources[sID].SetLooping(loop);
end;

procedure oxTAudioHandler.SetPitch(sID: loopint; pitch: single);
begin
   if(ValidSourceID(sID)) then
      Sources[sID].SetPitch(pitch);
end;

procedure oxTAudioHandler.PauseAll();
var
   i: longint;

begin
   for i := 0 to (SourceMax) do begin
      if(Sources[i] <> nil) then
         Pause(i);
   end;
end;

procedure oxTAudioHandler.ResumeAll();
var
   i: longint;

begin
   for i := 0 to (SourceMax) do begin
      if(Sources[i] <> nil) then
         Resume(i);
   end;
end;

procedure oxTAudioHandler.StopAll();
var
   i: longint;

begin
   for i := 0 to (SourceMax) do begin
      if(Sources[i] <> nil) then
         Stop(i);
   end;
end;

procedure oxTAudioHandler.PlayAll();
begin

end;

function oxTAudioHandler.GetNewSource(): longint;
var
   i: longint;

begin
   {initialize}
   Result      := -1;
   ErrorCode   := 0;

   {allocate more IDs if required}
   if(nSourcesAvailable <= 0) then begin
      AllocateMoreSourcePointers();

      if(ErrorCode <> 0) then
         exit;
   end;

   {find an unused Source pointer}
   for i := 0 to (nSourcesAvailable - 1) do begin
      if(Sources[i] = nil) then begin
         {create resource}
         Sources[i] := InstanceSource();

         if(Sources[i] <> nil) then begin
            dec(nSourcesAvailable);

            if(SourceMax < i) then
               SourceMax := i;

            Result := i;
         end;

         exit();
      end;
   end;
end;

procedure oxTAudioHandler.AllocateMoreSourcePointers();
var
   i,
   p: longint;

begin
   try
      p := nSourcesTotal;

      {allocate}
      inc(nSourcesTotal, nSourceIncrease);
      SetLength(Sources, nSourcesTotal);

      {initialize}
      for i := p to (nSourcesTotal - 1) do
         Sources[i] := nil;

      inc(nSourcesAvailable, nSourceIncrease);
   except
      RaiseError(eNO_MEMORY);
   end;
end;

procedure oxTAudioHandler.DestroySource(sID: longint);
begin
   if(ValidSourceID(sID)) then begin
      FreeObject(Sources[sID]);
      inc(nSourcesAvailable);
   end;
end;

procedure oxTAudioHandler.DestroyAllSources();
var
   i: longint;

begin
   for i := 0 to (nSourcesTotal - 1) do begin
      if(Sources[i] <> nil) then
         DestroySource(i);
   end;
end;

function oxTAudioHandler.GenerateBuffer(var buffer: oxTAudioBuffer; var data: oxTAudioBufferData): loopint;
begin
   result := eNONE;
end;

procedure oxTAudioHandler.RaiseError(errcode: longint);
begin
   ErrorCode := errcode;
end;

function oxTAudioHandler.ValidSourceID(sID: longint): boolean;
begin
   result := false;

   if(sID > -1) and (sID <= SourceMax) and (Sources[sID] <> nil) then
      result := true;
end;


function oxTAudioHandler.InstanceSource(): oxTAudioSource;
begin
   Result := Types.Source.Create();

   if(Result = nil) then
      RaiseError(eNO_MEMORY);
end;

function oxTAudioHandler.InstanceBuffer: oxTAudioBuffer;
begin
   Result := Types.Buffer.Create();

   if(Result = nil) then
      RaiseError(eNO_MEMORY);
end;

function oxTAudioHandler.InstanceListener: oxTAudioListener;
begin
   Result := Types.Listener.Create();

   if(Result = nil) then
      RaiseError(eNO_MEMORY);
end;

procedure oxTAudioHandler.SetupListener;
begin
   Listener := InstanceListener();

   if(Listener <> nil) then
      log.i('Instanced default listener');
end;

procedure oxTAudioHandler.OnInitialize;
begin

end;

procedure oxTAudioHandler.OnDeinitialize;
begin

end;

INITIALIZATION
   oxAudio.Enabled := true;

END.
