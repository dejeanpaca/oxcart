{
   uThreads, utilities for thread management
   Copyright (C) Dejan Boras 2018.

   Started on:    18.04.2018.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}{$MODESWITCH TYPEHELPERS}
UNIT uThreads;

INTERFACE

   USES uStd;

TYPE
   TThreadInitializerMethod = TProcedure;

   PThreadInitializer = ^TThreadInitializer;
   TThreadInitializer = record
      Method: TThreadInitializerMethod;
   end;

   TThreadInitializers = specialize TSimpleList<TThreadInitializer>;

   { TThreadsGlobal }

   TThreadsGlobal = record
      ThreadHandlers: loopint;

      Initializers: TThreadInitializers;

      function GetHandlerIndex(): loopint;
      function GetHandlerIndex(initializer: TThreadInitializerMethod): loopint;
      function SetInitializer(index: loopint; initializerMethod: TThreadInitializerMethod): PThreadInitializer;

      procedure CallInitializers();
   end;

VAR
   Threads: TThreadsGlobal;

IMPLEMENTATION

{ TThreadsGlobal }

function TThreadsGlobal.GetHandlerIndex(): loopint;
var
   initializer: TThreadInitializer;

begin
   ZeroPtr(@initializer, SizeOf(TThreadInitializer));

   inc(ThreadHandlers);
   Result := ThreadHandlers - 1;

   Initializers.Add(initializer);
end;

function TThreadsGlobal.GetHandlerIndex(initializer: TProcedure): loopint;
begin
   Result := GetHandlerIndex();
   SetInitializer(Result, initializer);
end;

function TThreadsGlobal.SetInitializer(index: loopint; initializerMethod: TThreadInitializerMethod): PThreadInitializer;
begin
   Result := @Initializers.List[index];
   Result^.Method := initializerMethod;
end;

procedure TThreadsGlobal.CallInitializers();
var
   i: loopint;

begin
   for i := 0 to Initializers.n - 1 do begin
      if(Initializers.List[i].Method <> nil) then
         Initializers.List[i].Method();
   end;
end;

INITIALIZATION
   TThreadInitializers.Initialize(Threads.Initializers);

END.
