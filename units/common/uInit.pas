{
   uInit, initialization/deinitialization
   Copyright (C) 2009. Dejan Boras

   Started On:    18.05.2009.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT uInit;

INTERFACE

   USES
      uStd, uLog, ParamUtils;

CONST
   initcLogProcs: boolean = false;
   initcAllocationStep: longint = 8;

TYPE
   PInitializationProc = ^TInitializationProc;
   TInitializationProc = record
      Name: string;
      {the procedure to be executed}
      Exec: TProcedure;
      {priority list}
      Priority: longint;
      {the next procedure}
      Next: PInitializationProc;

      procedure Init();
   end;

   { TInitializationProcsList }

   TInitializationProcsList = specialize TPreallocatedArrayList<TInitializationproc>;

   PInitializationProcs = ^TInitializationProcs;
   TInitializationProcs = record
      sName: string;

      {linked list of initialization/deinitialization procedures}
      iList,
      dList: TInitializationProcsList;

      procedure Init();
      procedure Init(const ipName: string);

      procedure iAdd(const name: string; exec: TProcedure; priority: longint = 0);
      procedure dAdd(const name: string; exec: TProcedure; priority: longint = 0);
      procedure Add(const name: string; iexec, dexec: TProcedure; priority: longint = 0);

      procedure iCall();
      procedure dCall();
   end;

IMPLEMENTATION

procedure TInitializationProc.Init();
begin
   ZeroOut(self, SizeOf(self));
end;

{ TInitializationProcs }

procedure TInitializationProcs.Init();
begin
   ZeroOut(self, SizeOf(self));
   iList.InitializeValues(iList);
   dList.InitializeValues(dList);
end;

procedure TInitializationProcs.Init(const ipName: string);
begin
   Init();
   sName := ipName;
end;

procedure AddToList(var list: TInitializationProcsList; var ip: TInitializationProc);
var
   where, i: longint;

begin
   assert(ip.exec <> nil, 'No execution procedure for ' + ip.name);

   if(list.n >= list.a) then begin
      inc(list.a, initcAllocationStep);

      SetLength(list.list, list.a);
   end;

   {move out existing elements to fit this one into sorted position}
   where := list.n;
   if(list.n > 0) then begin
      {find position}
      for i := 0 to list.n do begin
         if((i = list.n) or (list.list[i].priority < ip.priority)) then begin
            where := i;
            break;
         end;
      end;

      {move elements}
      if(where < list.n) then
         for i := list.n downto (where + 1) do
            list.list[i] := list.list[i - 1];
   end;

   list.list[where] := ip;
   inc(list.n);
end;

procedure TInitializationProcs.iAdd(const name: string; exec: TProcedure; priority: longint = 0);
var
   ip: TInitializationProc;
   i: loopint;

begin
   for i := 0 to iList.n - 1 do begin
      if(iList.List[i].Exec = exec) then
         exit;
   end;

   ip.Name := name;
   ip.Exec := exec;
   ip.Next := nil;
   ip.Priority := priority;

   AddToList(iList, ip);
end;

procedure TInitializationProcs.dAdd(const name: string; exec: TProcedure; priority: longint = 0);
var
   ip: TInitializationProc;
   i: loopint;

begin
   for i := 0 to dList.n - 1 do begin
      if(dList.List[i].Exec = exec) then
         exit;
   end;

   ip.Name := name;
   ip.Exec := exec;
   ip.Next := nil;
   ip.Priority := priority;

   AddToList(dList, ip);
end;

procedure TInitializationProcs.Add(const name: string; iexec, dexec: TProcedure; priority: longint = 0);
begin
   iAdd(name, iexec, priority);
   dAdd(name, dexec, priority);
end;

procedure TInitializationProcs.iCall();
var
   i: longint;

begin
   if(ilist.n > 0) then begin
      if(initcLogProcs) then
         log.Enter('Initializing Group > '+ sName);

      for i := 0 to ilist.n - 1 do begin
         if(initcLogProcs) then
            log.i('Initializing: ' + ilist.list[i].Name);

         ilist.list[i].exec();
      end;

      if(initcLogProcs) then
         log.Leave();
   end;
end;

procedure TInitializationProcs.dCall();
var
   i: longint;

begin
   if(initcLogProcs) then
      log.Enter('De-initializing Group > ' + sName);

   if(dList.n > 0) then begin
      for i := dList.n - 1 downto 0 do begin
         if(initcLogProcs) then
            log.i('De-initializing: ' + dList.List[i].Name);

         dList.List[i].exec();
      end;
   end;

   if(initcLogProcs) then
      log.Leave();
end;

INITIALIZATION
   if(parameters.FindFlag('--log-init')) then
      initcLogProcs := true;

END.

