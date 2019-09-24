{
   appuCtrlBreak, ctrl-break functionality
   Copyright (C) 2018. Dejan Boras

   Started On:    26.03.2018.
}

{$INCLUDE oxdefines.inc}
UNIT appuCtrlBreak;

INTERFACE

   USES
      sysutils, uLog,
      uApp
      {$IFDEF UNIX}, BaseUnix{$ENDIF};

IMPLEMENTATION

VAR
   previousCtrlBreakHandler: TCtrlBreakHandler = nil;
   alreadyReceived: boolean = false;

procedure signalReceived();
begin
   if(not alreadyReceived) then
      log.w('Interrupt signal received')
   else begin
      log.w('Interrupt signal received again. Halt.');
      halt(1);
   end;

   alreadyReceived := true;
end;

(* CtrlBreak set to true signalizes Ctrl-Break signal, otherwise Ctrl-C. *)
(* Return value of true means that the signal has been processed, false  *)
(* means that default handling should be used. *)

function ctrlBreakHandler(ctrlBreak: boolean): boolean;
begin
   signalReceived();

   if(Assigned(previousCtrlBreakHandler)) then begin
      if(previousCtrlBreakHandler(ctrlBreak)) then
         exit(true);
   end;

   app.Active := false;
   Result := true;
end;

{$IFDEF UNIX}
VAR
   previousSigIntHandler: signalhandler;

procedure sigintHandler({%H-}signal: longint); cdecl;
begin
   signalReceived();

   if(Assigned(previousSigIntHandler)) then
       previousSigIntHandler(signal);

   app.Active := false;
end;
{$ENDIF}

INITIALIZATION
   previousCtrlBreakHandler := SysSetCtrlBreakHandler(@ctrlBreakHandler);

   {$IFDEF UNIX}
   previousSigIntHandler := FpSignal(SIGINT, @sigintHandler);
   fpgeterrno();
   {$ENDIF}

end.

