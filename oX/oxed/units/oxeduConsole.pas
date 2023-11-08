{
   oxeduConsole, OXED console
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduConsole;

INTERFACE

   USES
      uLog, uStd, udvars,
      {ox}
      oxuRunRoutines, oxuConsoleBackend,
      {oxed}
      uOXED, oxeduSettings;

TYPE
   { oxedTConsole }

   oxedTConsole = record
      con: conTConsole;

      procedure s(const what: string);
      procedure e(const what: string);
      procedure k(const what: string);
      procedure w(const what: string);
      procedure f(const what: string);
      procedure i(const what: string);
      procedure d(const what: string);
      procedure v(const what: string);

      {these methods log without going into the log files (to avoid unnecessary log file output)}

      procedure ns(const what: string);
      procedure ne(const what: string);
      procedure nk(const what: string);
      procedure nw(const what: string);
      procedure nf(const what: string);
      procedure ni(const what: string);
      procedure nd(const what: string);
      procedure nv(const what: string);

      procedure Clear();
   end;

VAR
   oxedConsole: oxedTConsole;

IMPLEMENTATION

VAR
   consoleContentsSize: loopint = 1024;
   dvConsoleContentsSize: TDVar;

procedure init();
begin
   console.Init(oxedConsole.con);
   oxedConsole.con.Name := 'oxed';
   oxedConsole.con.Initialize();
   oxedConsole.con.SetContentsSize(consoleContentsSize);
end;

procedure deinit();
begin
   oxedConsole.con.Dispose();
end;

{ oxedTConsole }

procedure oxedTConsole.s(const what: string);
begin
   con.s(what);
   log.i(what);
end;

procedure oxedTConsole.e(const what: string);
begin
   con.e(what);
   log.e(what);
end;

procedure oxedTConsole.k(const what: string);
begin
   con.k(what);
   log.k(what);
end;

procedure oxedTConsole.w(const what: string);
begin
   con.w(what);
   log.w(what);
end;

procedure oxedTConsole.f(const what: string);
begin
   con.f(what);
   log.f(what);
end;

procedure oxedTConsole.i(const what: string);
begin
   con.i(what);
   log.i(what);
end;

procedure oxedTConsole.d(const what: string);
begin
   con.d(what);
   log.d(what);
end;

procedure oxedTConsole.v(const what: string);
begin
   con.v(what);
   log.v(what);
end;

{ NON LOG FILE VARIANTS }

procedure oxedTConsole.ns(const what: string);
begin
   con.i(what);
   consoleLog.i(what);
end;

procedure oxedTConsole.ne(const what: string);
begin
   con.e(what);
   consoleLog.e(what);
end;

procedure oxedTConsole.nk(const what: string);
begin
   con.k(what);
   consoleLog.k(what);
end;

procedure oxedTConsole.nw(const what: string);
begin
   con.w(what);
   consoleLog.w(what);
end;

procedure oxedTConsole.nf(const what: string);
begin
   con.f(what);
   consoleLog.f(what);
end;

procedure oxedTConsole.ni(const what: string);
begin
   con.i(what);
   consoleLog.i(what);
end;

procedure oxedTConsole.nd(const what: string);
begin
   con.d(what);
   consoleLog.d(what);
end;

procedure oxedTConsole.nv(const what: string);
begin
   con.v(what);
   consoleLog.v(what);
end;

procedure oxedTConsole.Clear();
begin
   con.Clear();
end;

INITIALIZATION
   oxed.Init.Add('console', @init, @deinit);

   dvgOXED.Add(dvConsoleContentsSize, 'console_contents_size', dtcSIZEINT, @consoleContentsSize);

END.
