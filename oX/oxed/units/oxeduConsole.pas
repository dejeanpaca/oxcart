{
   oxeduConsole, OXED console
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduConsole;

INTERFACE

   USES
      uLog,
      {ox}
      oxuRunRoutines, oxuConsoleBackend,
      {oxed}
      uOXED;

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

      procedure Clear();
   end;

VAR
   oxedConsole: oxedTConsole;

IMPLEMENTATION

procedure init();
begin
   console.Init(oxedConsole.con);
   oxedConsole.con.Name := 'oxed';
   oxedConsole.con.LogOutput := @stdlog;

   oxedConsole.con.Initialize();
end;

procedure deinit();
begin
   oxedConsole.con.Dispose();
end;

{ oxedTConsole }

procedure oxedTConsole.s(const what: string);
begin
   con.s(what);
end;

procedure oxedTConsole.e(const what: string);
begin
   con.e(what);
end;

procedure oxedTConsole.k(const what: string);
begin
   con.k(what);
end;

procedure oxedTConsole.w(const what: string);
begin
   con.w(what);
end;

procedure oxedTConsole.f(const what: string);
begin
   con.f(what);
end;

procedure oxedTConsole.i(const what: string);
begin
   con.i(what);
end;

procedure oxedTConsole.d(const what: string);
begin
   con.d(what);
end;

procedure oxedTConsole.v(const what: string);
begin
   con.v(what);
end;

procedure oxedTConsole.Clear();
begin
   con.Clear();
end;

INITIALIZATION
   oxed.Init.Add('console', @init, @deinit);

END.
