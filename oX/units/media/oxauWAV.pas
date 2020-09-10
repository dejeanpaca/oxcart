{
   oxauWAV, handles wav files
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxauWAV;

INTERFACE

   USES
     uStd, uFileHandlers, uFile, StringUtils,
     {ox}
     oxuRunRoutines, oxuAudioBase, oxuAudioFile, oxuFile, oxauRIFF;

CONST
   {supported wave sound formats}
   WAVE_FORMAT_PCM = $0001;

TYPE
   {wave FMT chunk data}
   wavTFMTChunk = packed record
      wFormatTag: SmallInt;
      wChannels: Word;
      dwSamplesPerSec,
      dwAvgBytesPerSec: LongWord;
      wBlockAlign,
      wBitsPerSample: Word;
   end;

VAR
   {IDs for chunks and the wave file}
   wavFMTChunkID: riffTID = ('f', 'm', 't', #32);
   wavDataChunkID: riffTID = ('d', 'a', 't', 'a');
   wavWAVEID: riffTID = ('W','A','V','E');

IMPLEMENTATION

VAR
   ext: fhTExtension;
   handler: fhTHandler;

procedure readFMT(var chunkHeader: riffTChunk; var f: TFile; var data: oxTFileRWData; var audioData: oxTAudioBufferData);
var
   positionBefore: fileint;
   chunk: wavTFMTChunk;

begin
   positionBefore := f.fPosition;
   f.Read(chunk, SizeOf(chunk));

   if(chunk.wFormatTag <> WAVE_FORMAT_PCM) then begin
      data.SetError(eUNSUPPORTED, 'Unsupported WAVE format ' + sf(chunk.wFormatTag));
      exit;
   end;

   f.Seek(positionBefore + chunkHeader.Size);

   audioData.nChannels := chunk.wChannels;
   audioData.SampleRate := chunk.dwSamplesPerSec;
   audioData.BitsPerSample := chunk.wBitsPerSample;

   audioData.BlockAlign := audioData.nChannels * (audioData.BitsPerSample div 8);
   audioData.BytesPerSec := audioData.SampleRate * audioData.BlockAlign;
end;

procedure readData(var chunkHeader: riffTChunk; var f: TFile; var data: oxTFileRWData; var audioData: oxTAudioBufferData);
begin
   if(chunkHeader.Size > 0) then begin
      audioData.DataSize := chunkHeader.Size;
      GetMem(audioData.Data, audioData.DataSize);

      f.Read(audioData.Data^, audioData.DataSize);
   end else
      data.SetError(eINVALID, 'no wave data');
end;

procedure handleFile(var f: TFile; var data: oxTFileRWData; var audioData: oxTAudioBufferData);
var
   riffHeader: riffTHeader;
   dataRead,
   headerRead: boolean;
   chunkHeader: riffTChunk;

begin
   f.Read(riffHeader, sizeOf(riffHeader));
   if(f.Error = 0) then begin
      {check riff header}
      if(riffHeader.ID <> riffID) then begin
         data.SetError(eINVALID, 'invalid riff ID');
         exit;
      end;

      {check wave file type}
      if(riffHeader.TypeID <> wavWAVEID) then begin
         data.SetError(eINVALID, 'invalid riff type ID (not wave)');
         exit;
      end;

      dataRead := false;
      headerRead := false;

      repeat
         f.Read(chunkHeader, SizeOf(riffTChunk));

         if(f.Error = 0) then begin
            if(chunkHeader.ID = wavFMTChunkID) then begin {FMT Chunk}
               readFMT(chunkHeader, f, data, audioData);
               headerRead := true;
            end else if (chunkHeader.ID = wavDataChunkID) then begin {Data Chunk}
               readData(chunkHeader, f, data, audioData);
               dataRead := true;
            end else begin
               {skip unkown or unsupported chunks}
               f.Seek(chunkHeader.Size, fSEEK_CUR);
            end;
         end;
      until f.EOF() or (f.Error <> 0) or (data.Error <> 0) or (dataRead and headerRead);
   end;
end;

procedure handle(data: pointer);
begin
   handleFile(oxTFileRWData(data^).f^, oxTFileRWData(data^), oxPAudioBufferData(oxTFileRWData(data^).External)^);
end;

INITIALIZATION
   oxfAudio.Readers.RegisterHandler(handler, 'wav', @handle);
   oxfAudio.Readers.RegisterExt(ext, '.wav', @handler);

END.
