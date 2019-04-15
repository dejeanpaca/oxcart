{
   oxeduProblems, OXED problems list
   Copyright (C) 2017. Dejan Boras

   Started On:    13.03.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProblems;

INTERFACE

   USES
      uLog,
      {ox}
      oxuRunRoutines, oxuConsoleBackend,
      {oxed}
      uOXED;

TYPE
   { oxedTProblems }

   oxedTProblems = record
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
   oxedProblems: oxedTProblems;

IMPLEMENTATION

procedure init();
begin
   console.Init(oxedProblems.con);
   oxedProblems.con.Name := 'problems';
   oxedProblems.con.LogOutput := @stdlog;

   oxedProblems.con.Initialize();
end;

procedure deinit();
begin
   oxedProblems.con.Dispose();
end;

{ oxedTProblems }

procedure oxedTProblems.s(const what: string);
begin
   con.s(what);
end;

procedure oxedTProblems.e(const what: string);
begin
   con.e(what);
end;

procedure oxedTProblems.k(const what: string);
begin
   con.k(what);
end;

procedure oxedTProblems.w(const what: string);
begin
   con.w(what);
end;

procedure oxedTProblems.f(const what: string);
begin
   con.f(what);
end;

procedure oxedTProblems.i(const what: string);
begin
   con.i(what);
end;

procedure oxedTProblems.d(const what: string);
begin
   con.d(what);
end;

procedure oxedTProblems.v(const what: string);
begin
   con.v(what);
end;

procedure oxedTProblems.Clear;
begin
   con.Clear();
end;

VAR
   oxedInitRoutines: oxTRunRoutine;

INITIALIZATION
   oxed.Init.Add(oxedInitRoutines, 'problems', @init, @deinit);

END.
