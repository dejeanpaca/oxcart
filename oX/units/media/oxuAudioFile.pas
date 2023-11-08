{
   oxuAudioBase, base oX audio resources
   Copyright (C) 2012. Dejan Boras

   Started On:    23.01.2012.
}

{$INCLUDE oxdefines.inc}
UNIT oxuAudioFile;

INTERFACE

   USES
     uStd, uFile, uLog,
     {ox}
     uOX, oxuRunRoutines, oxuAudioBase, oxuFile;

TYPE
   { oxTAudioFileOptions }
   oxPAudioFileOptions = ^oxTAudioFileOptions;
   oxTAudioFileOptions = record
      Buffer: oxTAudioBuffer;
      Handler: oxTAudioHandler;
   end;

   { oxTAudioFile }

   oxTAudioFile = class(oxTFileRW)
      procedure Init(out options: oxTAudioFileOptions);

      function Read(const fn: string; var options: oxTAudioFileOptions): oxTAudioBuffer;
      function Read(const fn: string; var f: TFile; var options: oxTAudioFileOptions): oxTAudioBuffer;
      function Read(const fn: string; var f: TFile): oxTAudioBuffer;
      function Read(const fn: string): oxTAudioBuffer;

      function ReadSimple(const fn: string): oxTAudioSource;

      function OnRead(var data: oxTFileRWData): loopint; override;
   end;

VAR
   oxfAudio: oxTAudioFile = nil;

IMPLEMENTATION

procedure init();
begin
   oxfAudio := oxTAudioFile.Create();
end;

procedure deinit();
begin
   FreeObject(oxfAudio);
end;

{ oxTAudioFile }

procedure oxTAudioFile.Init(out options: oxTAudioFileOptions);
begin
   ZeroOut(options, SizeOf(options));
   options.Handler := oxa;
end;

function oxTAudioFile.Read(const fn: string; var options: oxTAudioFileOptions): oxTAudioBuffer;
begin
   if(inherited Read(fn, @options) = 0) then
      Result := options.Buffer
   else
      Result := nil;
end;

function oxTAudioFile.Read(const fn: string; var f: TFile; var options: oxTAudioFileOptions): oxTAudioBuffer;
begin
   if(inherited Read(f, fn, @options) = 0) then
      Result := options.Buffer
   else
      Result := nil;
end;

function oxTAudioFile.Read(const fn: string; var f: TFile): oxTAudioBuffer;
var
   options: oxTAudioFileOptions;

begin
   Init(options);

   Result := Read(fn, f, options);
end;

function oxTAudioFile.Read(const fn: string): oxTAudioBuffer;
var
   options: oxTAudioFileOptions;

begin
   Init(options);

   Result := Read(fn, options);
end;

function oxTAudioFile.ReadSimple(const fn: string): oxTAudioSource;
var
   buffer: oxTAudioBuffer;

begin
   buffer := Read(fn);

   if(buffer <> nil) then begin
      Result := oxa.InstanceSource();
      Result.SetBuffer(buffer);
   end else
      Result := nil;
end;

procedure generateAudio(var data: oxTFileRWData; var audioData: oxTAudioBufferData; var options: oxTAudioFileOptions);
var
   buffer: oxTAudioBuffer;

begin
   buffer := options.Handler.InstanceBuffer();

   buffer.Frequency := audioData.SampleRate;
   buffer.Size := audioData.DataSize;

   data.Error := options.Handler.GenerateBuffer(buffer, audioData);

   options.Buffer := buffer;
end;

function oxTAudioFile.OnRead(var data: oxTFileRWData): loopint;
var
   audioData: oxTAudioBufferData;
   options: oxTAudioFileOptions;

begin
   ZeroOut(audioData, SizeOf(audioData));
   data.External := @audioData;

   {set default options if none were specified}
   if(data.Options = nil) then begin
      Init(options);
      data.Options := @options;
   end;

   data.Handler^.CallHandler(@data);

   {if loaded ok, then we'll create a audio buffer}
   if(data.Ok()) then begin
      if(audioData.DataSize > 0) then
         generateAudio(data, audioData, oxPAudioFileOptions(data.Options)^)
      else begin
         log.e('No audio data loaded for ' + data.f^.fn);
      end;
   end;

   result := data.Error;

   {done}
   audioData.Destroy();
end;

INITIALIZATION
   ox.Init.Add('audio_file', @init, @deinit);

END.
