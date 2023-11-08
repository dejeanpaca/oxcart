{
   uiuRegisteredWidgets, all registered widgets
   Copyright (C) 2010. Dejan Boras

   Started On:    03.10.2019.
}

{$INCLUDE oxdefines.inc}
UNIT uiuRegisteredWidgets;

INTERFACE

   USES
      uStd, StringUtils,
      {oX}
      oxuRunRoutines,
      {ui}
      uiuTypes, uiuWidget, oxuUI, uiuSkinTypes, uiuSkin;

TYPE

   { uiTRegisteredWidgets }

   uiTRegisteredWidgets = record
      {dummy widget class}
      DummyWidgetClass: uiTWidgetClass;

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

   { uiTWidgetInternal }

   uiTWidgetInternal = record helper for uiTWidgetClass
      {initialize a uiTWidgetClass record}
      class procedure Init(out wc: uiTWidgetClass); static;
      class procedure Init(out wc: uiTWidgetClass; const name: string); static;

      procedure Register(const name: string; initProc: TProcedure);
      procedure Done(widgetClass: uiTWidgetClassType);
      procedure Done();
   end;


VAR
   uiRegisteredWidgets: uiTRegisteredWidgets;

IMPLEMENTATION

procedure InitDummyWidgetClass();
begin
   ZeroOut(uiRegisteredWidgets.DummyWidgetClass, SizeOf(uiTWidgetClass));

   uiRegisteredWidgets.DummyWidgetClass.sName        := 'wdgDUMMY';
   uiRegisteredWidgets.DummyWidgetClass.SelectOnAdd  := true;
   uiRegisteredWidgets.DummyWidgetClass.Instance := uiTWidget;
   uiRegisteredWidgets.DummyWidgetClass.SkinDescriptor := nil;
end;


{ uiTRegisteredWidgets }

procedure uiTRegisteredWidgets.RegisterClass(var wc: uiTWidgetClass);
var
   n: longint;

begin
   assert(ReportedWidgetTypes < nWidgetTypes, 'uiWidgets > More classes registered than reported(' + sf(nWidgetTypes) + '). While registering: ' + wc.sName);

   inc(ReportedWidgetTypes);
   if(ReportedWidgetTypes <= nWidgetTypes) then begin
      n := ReportedWidgetTypes - 1;

      WidgetClasses[n] := @wc;
      WidgetClasses[n]^.cID := n;

      if(WidgetClasses[n]^.SkinDescriptor <> nil) then
         uiSkin.SetupWidget(oxui.DefaultSkin, oxui.DefaultSkin.wdgSkins[n], WidgetClasses[n]^.SkinDescriptor^);
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
end;

procedure uiTRegisteredWidgets.DeInitialize();
begin
   {dispose of widget class and renderer pointer memory}
   SetLength(WidgetClasses, 0);
   WidgetClasses := nil;

   ReportedWidgetTypes := 0;
end;

{ uiTWidgetInternal }

class procedure uiTWidgetInternal.Init(out wc: uiTWidgetClass);
begin
   wc := uiRegisteredWidgets.DummyWidgetClass;
end;

class procedure uiTWidgetInternal.Init(out wc: uiTWidgetClass; const name: string);
begin
   Init(wc);
   wc.sName := name;
end;

procedure uiTWidgetInternal.Register(const name: string; initProc: TProcedure);
begin
   Init(self, CopyAfter(name, '.'));

   if(initProc <> nil) then begin
      oxui.BaseInitializationProcs.iAdd(InitRoutines, name, initProc);
   end;

   inc(uiRegisteredWidgets.nWidgetTypes);
end;

procedure uiTWidgetInternal.Done(widgetClass: uiTWidgetClassType);
begin
   Self.Instance := widgetClass;
   Done();
end;

procedure uiTWidgetInternal.Done();
begin
   uiRegisteredWidgets.RegisterClass(self);
end;

procedure skinInitialize();
begin
   uiRegisteredWidgets.SetupDefaultWidget(oxui.DefaultSkin);
end;

VAR
   skinInitRoutines: oxTRunRoutine;

INITIALIZATION
   oxui.BaseInitializationProcs.Add(skinInitRoutines, 'widget.skin', @skinInitialize);

   InitDummyWidgetClass();


END.
