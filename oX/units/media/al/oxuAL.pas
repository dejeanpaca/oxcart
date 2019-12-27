{
   oxuAL, al utilities
   Copyright (C) 2017. Dejan Boras

   TODO: Implement more detailed al error checking, in a similar manner the gl renderer does it

   Started On:    11.09.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuAL;

INTERFACE

   USES
     uStd, uLog, StringUtils,
     {dal}
     OpenAL;

TYPE
   oxPALGlobal = ^oxTALGlobal;

   { oxTALGlobal }

   oxTALGlobal = record
      ErrorCode: ALenum;

      Info: record
         Renderer,
         Vendor,
         Version: string;
      end;

      function GetErrorDescription(code: ALenum): string;
      {get error code}
      function GetError(const description: string = ''): ALenum;
      {get error code}
      function cGetError(device: PALCdevice = nil): ALenum;
      {Get a OpenAL string}
      function GetString(which: ALuint): string;
      function cGetString(device: PALCDevice; which: ALuint): string;

      procedure GetInformation();
   end;

VAR
   oxal: oxTALGlobal;

IMPLEMENTATION

{ oxTALGlobal }

function oxTALGlobal.GetErrorDescription(code: ALenum): string;
begin
   if(code = AL_NO_ERROR) then
      Result := 'no error'
   else if(code = AL_INVALID_NAME) then
      Result := 'invalid name'
   else if(code = AL_INVALID_ENUM) then
      Result := 'invalid enum'
   else if(code = AL_INVALID_VALUE) then
      Result := 'invalid value'
   else if(code = AL_INVALID_OPERATION) then
      Result := 'invalid operation'
   else if(code = AL_OUT_OF_MEMORY) then
      Result := 'out of memory'
   else
      Result := 'unknown';
end;

function oxTALGlobal.GetError(const description: string): ALenum;
begin
   ErrorCode := alGetError();

   Result := ErrorCode;
   if(Result <> AL_NO_ERROR) then begin
      if(description <> '') then
         log.w('al > Error (' + sf(Result) +') ' + GetErrorDescription(ErrorCode) + ' | ' + description)
      else
         log.w('al > Error (' + sf(Result) +') ' + GetErrorDescription(ErrorCode));
   end;
end;

function oxTALGlobal.cGetError(device: PALCdevice): ALenum;
begin
   ErrorCode := alcGetError(device);

   Result := ErrorCode;
   if(Result <> AL_NO_ERROR) then
      log.w('alc > Error (' + sf(Result) +') ' + GetErrorDescription(ErrorCode));
end;

function oxTALGlobal.GetString(which: ALuint): string;
var
   pc: pchar = nil;

begin
   pc := pChar(alGetString(which));

   if(pc <> nil) then
      Result := pc
   else
      Result := '';
end;

function oxTALGlobal.cGetString(device: PALCdevice; which: ALuint): string;
var
   pc: pchar = nil;

begin
   pc := pChar(alcGetString(device, which));

   if(pc <> nil) then
      Result := pc
   else
      Result := '';
end;

procedure oxTALGlobal.GetInformation;
begin
   Info.Renderer := oxal.GetString(AL_RENDERER);
   oxal.GetError();
   Info.Vendor := oxal.GetString(AL_VENDOR);
   oxal.GetError();
   Info.Version := oxal.GetString(AL_VERSION);
   oxal.GetError();

   log.Enter('Audio Device Information');
   log.i('Renderer: ' + Info.Renderer);
   log.i('Vendor: ' + Info.Vendor);
   log.i('OpenAL Version: ' + Info.Version);
   log.Leave();
end;

END.

