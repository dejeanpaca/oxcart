{
   oxuAudioBase, base oX audio resources
   Copyright (C) 2012. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuMediaBase;

INTERFACE

   USES uStd;

TYPE
   oxTMediaPlayer = class
      public
         ErrorCode: longint;

         leftVolume, 
         rightVolume, 
         rate: single;
         
         loop, 
         loaded: boolean;

      protected
         {set to true if the media can be handled (play, pause, ...)}
         ok: boolean;

      public
         constructor Create();

         procedure Initialize(); virtual;
         procedure Deinitialize(); virtual;

         {loads an audio file and returns a stream ID}
         function load(const {%H-}fn: string): boolean; virtual;
         procedure unload(); virtual;
         procedure play(); virtual;
         procedure pause(); virtual;
         procedure resume(); virtual;
         procedure stop(); virtual;

         procedure setRate(r: single); virtual;
         procedure setVolume(lV, rV: single); virtual;
         procedure setLoop({%H-}lp: boolean); virtual;

         {error handling}
         procedure raiseError(errcode: longint);
   end;

   oxTMediaBase = record
     enabled,
     initialized: boolean;

     onSetHandler: TProcedure;
     pGetPlayer: function(): oxTMediaPlayer;
     onPreInitialize,
     onDeInitialize: TProcedure;
   end;


VAR
   oxMedia: oxTMediaBase;

IMPLEMENTATION

constructor oxTMediaPlayer.Create();
begin
end;

procedure oxTMediaPlayer.Initialize();
begin
   ErrorCode := eNONE;
end;

procedure oxTMediaPlayer.Deinitialize();
begin
   unload();
end;

function oxTMediaPlayer.load(const fn: string): boolean;
begin
   result := false;
end;

procedure oxTMediaPlayer.unload();
begin
end;

procedure oxTMediaPlayer.play();
begin
end;

procedure oxTMediaPlayer.pause();
begin
end;

procedure oxTMediaPlayer.resume();
begin
end;

procedure oxTMediaPlayer.stop();
begin

end;

procedure oxTMediaPlayer.setRate(r: single);
begin
   rate := r;
end;

procedure oxTMediaPlayer.setVolume(lV, rV: single);
begin
   leftVolume  := lV;
   rightVolume := rV;
end;

procedure oxTMediaPlayer.setLoop(lp: boolean);
begin
   loop := loop;
end;

procedure oxTMediaPlayer.raiseError(errcode: longint);
begin
   ErrorCode := errcode;
end;

END.

