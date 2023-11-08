{
   oxeduMessages, OXED messages
   Copyright (C) 2017. Dejan Boras

   Started On:    13.03.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduMessages;

INTERFACE

   USES
      uLog,
      {ox}
      oxuRunRoutines, oxuConsoleBackend,
      {oxed}
      uOXED;

TYPE
   { oxedTMessages }

   oxedTMessages = record
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
   oxedMessages: oxedTMessages;

IMPLEMENTATION

procedure init();
begin
   console.Init(oxedMessages.con);
   oxedMessages.con.Name := 'messages';
   oxedMessages.con.LogOutput := @stdlog;

   oxedMessages.con.Initialize();
end;

procedure deinit();
begin
   oxedMessages.con.Dispose();
end;

{ oxedTMessages }

procedure oxedTMessages.s(const what: string);
begin
   con.s(what);
end;

procedure oxedTMessages.e(const what: string);
begin
   con.e(what);
end;

procedure oxedTMessages.k(const what: string);
begin
   con.k(what);
end;

procedure oxedTMessages.w(const what: string);
begin
   con.w(what);
end;

procedure oxedTMessages.f(const what: string);
begin
   con.f(what);
end;

procedure oxedTMessages.i(const what: string);
begin
   con.i(what);
end;

procedure oxedTMessages.d(const what: string);
begin
   con.d(what);
end;

procedure oxedTMessages.v(const what: string);
begin
   con.v(what);
end;

procedure oxedTMessages.Clear;
begin
   con.Clear();
end;

INITIALIZATION
   oxed.Init.Add('messages', @init, @deinit);

END.
