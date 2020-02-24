{
   oxuALTypes, audio types
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuALTypes;

INTERFACE

   USES
     uStd, uLog,
     {dal}
     OpenAL,
     {ox}
     oxuAudioBase, oxuAudio;

TYPE
   oxalTSource = type ALuint;

   { oxalTSourceHelper }

   oxalTSourceHelper = type helper for oxalTSource
      function Create(): boolean;
      function Destroy(): boolean;
   end;

   oxalTBuffer = type ALuint;

   { oxalTBufferHelper }

   oxalTBufferHelper = type helper for oxalTBuffer
      function Create(): boolean;
      function Destroy(): boolean;
      function Data(format: ALuint; var dataSource; size: loopint; freq: loopint): boolean;
   end;


IMPLEMENTATION

{ oxalTBufferHelper }

function oxalTBufferHelper.Create: boolean;
begin
   alGenBuffers(1, @Self);

   Result := alGetError() = AL_NO_ERROR;
end;

function oxalTBufferHelper.Destroy: boolean;
begin
   if(Self <> 0) then begin
      alDeleteBuffers(1, @Self);
      Result := alGetError() = AL_NO_ERROR;
   end else
      Result := true;
end;

function oxalTBufferHelper.Data(format: ALuint; var dataSource; size: loopint; freq: loopint): boolean;
begin
   alBufferData(Self, format, @dataSource, size, freq);

   result := alGetError() = AL_NO_ERROR;
end;

{ oxalTSourceHelper }

function oxalTSourceHelper.Create: boolean;
begin
   alGenSources(1, @Self);

   Result := alGetError() = AL_NO_ERROR;
end;

function oxalTSourceHelper.Destroy: boolean;
begin
   if(Self <> 0) then begin
      alDeleteSources(1, @Self);

      Result := alGetError() = AL_NO_ERROR;
   end else
      Result := true;
end;

END.

