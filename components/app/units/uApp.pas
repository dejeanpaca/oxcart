{
   uApp, base app unit
   Copyright (C) 2007. Dejan Boras

   Started On:    01.03.2007.
}

{$INCLUDE oxheader.inc}
UNIT uApp;

INTERFACE

   USES
      uStd, sysutils, udvars,
      oxuRunRoutines;

TYPE

   { TApplication }

   TApplication = record
      Active,
      Initialized: boolean;
      IdleTime: longint;
      dvGroup: TDvarGroup;

      InitializationProcs: oxTRunRoutines;

      procedure Initialize();
      procedure DeInitialize();

      {open link in browser}
      function OpenLink(const link: StdString): boolean;
      {open file manager}
      function OpenFileManager(const target: StdString): boolean;
   end;

VAR
   app: TApplication;

IMPLEMENTATION

VAR
   dvIdleTime: TDVar;

procedure TApplication.Initialize();
begin
   if(not Initialized) then begin
      InitializationProcs.iCall();

      Initialized := true;
   end;
end;

procedure TApplication.DeInitialize();
begin
   if(Initialized) then begin
      Initialized := false;

      InitializationProcs.dCall();
   end;
end;

function TApplication.OpenLink(const link: StdString): boolean;
begin
   try
      {$IFDEF WINDOWS}
      ExecuteProcess('explorer', Link);
      {$ENDIF}
      {$IFDEF LINUX}
      ExecuteProcess('/usr/bin/xdg-open', Link);
      {$ENDIF}
      {$IFDEF DARWIN}
      ExecuteProcess('open', Link);
      {$ENDIF}

      exit(true);
   except
   end;

   Result := false;
end;

function TApplication.OpenFileManager(const target: StdString): boolean;
begin
   Result := OpenLink(target);
end;

INITIALIZATION
   app.Active     := true;
   app.IdleTime   := 5;

   dvar.Add('app', app.dvGroup);
   app.dvGroup.Add(dvIdleTime, 'idle_time', dtcLONGINT, @app.IdleTime);

END.
