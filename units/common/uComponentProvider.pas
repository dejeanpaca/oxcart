{
   uComponentProvider
   Copyright (C) 2014. Dejan Boras

   Started On:    01.08.2014.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT uComponentProvider;

INTERFACE

   USES uStd;

TYPE
   {a single component return function}
   TComponentReturn = function(): TObject;

   {holds description of the provider of a single component}
   PSingleComponent = ^TSingleComponent;
   TSingleComponent = record
      Name: string;
      Return: function(): TObject;
   end;

   { TComponentProvider }
   TComponentProviderList = specialize TPreallocatedArrayList<TSingleComponent>;

   TComponentProvider = record
      Components: TComponentProviderList;

      {registers a component with the specified name}
      procedure RegisterComponent(const name: string; return: TComponentReturn);
      {finds a component and returns its descriptor}
      function FindComponent(const componentName: string): PSingleComponent;
      {returns a component with the given name}
      function GetComponent(const componentName: string): TObject;
   end;

   { TComponentProviderGlobal }

   TComponentProviderGlobal = record
      AllocationStep: longint;

      procedure Initialize(var cp: TComponentProvider);
   end;

VAR
   ComponentProvider: TComponentProviderGlobal;

IMPLEMENTATION

{ TComponentProviderGlobal }

procedure TComponentProviderGlobal.Initialize(var cp: TComponentProvider);
begin
   ZeroOut(cp, SizeOf(cp));
   cp.Components.Initialize(cp.Components, AllocationStep);
end;

{ TComponentProvider }

procedure TComponentProvider.RegisterComponent(const name: string; return: TComponentReturn);
var
   component: TSingleComponent;

begin
   if(return = nil) or (name = '') then
      exit;

   component.Name := name;
   component.Return := return;

   Components.Add(component);
end;

function TComponentProvider.FindComponent(const componentName: string): PSingleComponent;
var
   i: longint;

begin
   for i := 0 to (components.n - 1) do begin
      if(components.List[i].Name = componentName) then
         exit(@components.List[i]);
   end;

   result := nil;
end;

function TComponentProvider.GetComponent(const componentName: string): TObject;
var
   p: PSingleComponent;

begin
   p := FindComponent(componentName);
   if(p <> nil) then
      exit(p^.return());

   result := nil;
end;

INITIALIZATION
   ComponentProvider.AllocationStep := 32;

END.
