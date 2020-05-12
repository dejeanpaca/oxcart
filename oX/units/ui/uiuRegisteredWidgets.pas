{
   uiuRegisteredWidgets, all registered widgets
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuRegisteredWidgets;

INTERFACE

   USES
      uStd, StringUtils,
      {oX}
      oxuRunRoutines,
      {ui}
      uiuBase, uiuTypes, uiuWidget, uiuSkinTypes, uiuSkin, oxuUI;

TYPE
   { uiTWidgetInternal }

   uiTWidgetInternal = record helper for uiTWidgetClass
      {initialize a uiTWidgetClass record}
      class procedure Init(out wc: uiTWidgetClass); static;

      procedure Register(const name: string; classType: uiTWidgetClassType);
      procedure UseInit(initProc: TProcedure; deinitProc: TProcedure = nil);
   end;

   { uiTRegisteredWidgets }

   uiTRegisteredWidgets = record
      {dummy widget class}
      DummyWidgetClass: uiTWidgetClass;

      Internals: record
         s,
         e: uiPWidgetClass;
      end;

      {total number of widget types}
      nWidgetTypes,
      {number of widget types reported}
      ReportedWidgetTypes: longint;
      {widget classes}
      WidgetClasses: uiTWidgetClasses;

      {registers a widget class}
      procedure RegisterClass(var wc: uiTWidgetClass);

      procedure SetupDefaultWidget(skin: uiTSkin);

      procedure Initialize();
      procedure DeInitialize();
   end;

VAR
   uiRegisteredWidgets: uiTRegisteredWidgets;

IMPLEMENTATION

procedure InitDummyWidgetClass();
begin
   ZeroOut(uiRegisteredWidgets.DummyWidgetClass, SizeOf(uiTWidgetClass));

   uiRegisteredWidgets.DummyWidgetClass.Name := 'wdgDUMMY';
   uiRegisteredWidgets.DummyWidgetClass.SelectOnAdd  := true;
   uiRegisteredWidgets.DummyWidgetClass.Instance := uiTWidget;

   uiTWidgetSkinDescriptor.Initialize(uiRegisteredWidgets.DummyWidgetClass.SkinDescriptor);
end;

{ uiTWidgetInternal }

class procedure uiTWidgetInternal.Init(out wc: uiTWidgetClass);
begin
   wc := uiRegisteredWidgets.DummyWidgetClass;
end;

procedure uiTWidgetInternal.Register(const name: string; classType: uiTWidgetClassType);
begin
   Instance := classType;

   Next := nil;

   if(uiRegisteredWidgets.Internals.s = nil) then
      uiRegisteredWidgets.Internals.s := @Self
   else
      uiRegisteredWidgets.Internals.e^.Next := @Self;

   uiRegisteredWidgets.Internals.e := @Self;

   inc(uiRegisteredWidgets.nWidgetTypes);

   uiTWidgetSkinDescriptor.Initialize(SkinDescriptor, name);
end;

procedure uiTWidgetInternal.UseInit(initProc: TProcedure; deinitProc: TProcedure);
begin
   if(initProc <> nil) or (deinitProc <> nil) then
      ui.WidgetInitializationProcs.Add(InitRoutines, Name, initProc, deinitProc);
end;

{ uiTRegisteredWidgets }

procedure uiTRegisteredWidgets.RegisterClass(var wc: uiTWidgetClass);
var
   n: longint;
   skin: uiTSkin;

begin
   assert(ReportedWidgetTypes < nWidgetTypes, 'uiWidgets > More classes registered than reported(' +
      sf(nWidgetTypes) + '). While registering: ' + wc.Name);

   inc(ReportedWidgetTypes);
   if(ReportedWidgetTypes <= nWidgetTypes) then begin
      n := ReportedWidgetTypes - 1;

      WidgetClasses[n] := @wc;
      WidgetClasses[n]^.cID := n;

      skin := oxui.GetDefaultSkin();

      if(WidgetClasses[n]^.SkinDescriptor.Name <> '') then
         uiSkin.SetupWidget(skin, skin.wdgSkins[n], WidgetClasses[n]^.SkinDescriptor);
   end;
end;

procedure uiTRegisteredWidgets.SetupDefaultWidget(skin: uiTSkin);
begin
   if(nWidgetTypes > 0) then begin
      SetLength(skin.wdgSkins, nWidgetTypes);

      ZeroOut(skin.wdgSkins[0], int64(SizeOf(uiTWidgetSkin)) * int64(nWidgetTypes));
   end;
end;

procedure uiTRegisteredWidgets.Initialize();
var
   cur: uiPWidgetClass;

begin
   if(nWidgetTypes > 0) then begin
      {allocate memory for widget classes}
      try
         SetLength(WidgetClasses, nWidgetTypes);
      except
         {eNO_MEMORY}
         exit;
      end;

      ZeroOut(WidgetClasses[0], int64(nWidgetTypes) * int64(SizeOf(uiPWidgetClass)));
   end;

   cur := Internals.s;

   if(cur <> nil) then repeat
      RegisterClass(cur^);
      cur := cur^.Next;
   until cur = nil;
end;

procedure uiTRegisteredWidgets.DeInitialize();
begin
   {dispose of widget class and renderer pointer memory}
   SetLength(WidgetClasses, 0);
   WidgetClasses := nil;

   ReportedWidgetTypes := 0;
end;

procedure skinInitialize();
begin
   uiRegisteredWidgets.SetupDefaultWidget(oxui.GetDefaultSkin());
end;

INITIALIZATION
   ui.BaseInitializationProcs.Add('widget.skin', @skinInitialize);

   InitDummyWidgetClass();

END.
