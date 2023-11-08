{
   uiuInputBoxOverlay,
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uiuInputBoxOverlay;

INTERFACE

   USES
      uStd,
      {ox}
      oxuTypes,
      {ui}
      uiuTypes, uiuWindowTypes, uiuWindow, uiuWidget, uiWidgets, wdguInputBox;

TYPE
   uiPInputBoxOverlay = ^uiTInputBoxOverlay;

   { wdgTInputBoxOverlay }

   wdgTInputBoxOverlay = class(wdgTInputBox)
      Overlay: uiPInputBoxOverlay;
      CalledCallback: boolean;
      Source: uiTWidget;

      function OnConfirm(): boolean; override;
      function OnEscape(): boolean; override;

      procedure OnDeactivate(); override;
      procedure DeInitialize(); override;

      procedure CallCallback(isConfirmed: boolean);

      procedure Confirmed(); virtual;
      procedure Escaped(); virtual;
   end;

   wdgTInputBoxOverlayClass = class of wdgTInputBoxOverlay;

   uiTInputBoxOverlayCallback = procedure(wdg: wdgTInputBoxOverlay; confirmed: boolean);

   { uiTInputBoxOverlay }

   uiTInputBoxOverlay = record
      Wdg: wdgTInputBoxOverlay;
      Callback: uiTInputBoxOverlayCallback;
      Instance: wdgTInputBoxOverlayClass;

      procedure Destroy();
      procedure Show(source: uiTWidget; const p: oxTPoint);
   end;

VAR
   uiInputBoxOverlay: uiTInputBoxOverlay;

IMPLEMENTATION

{ uiTInputBoxOverlay }

procedure uiTInputBoxOverlay.Destroy();
begin
   uiWidget.Dispose(uiTWidget(Wdg));
end;

procedure uiTInputBoxOverlay.Show(source: uiTWidget; const p: oxTPoint);
var
   newP: oxTPoint;

begin
   {dispose if part of another window}
   if(Wdg = nil) or (Wdg.wnd <> source.wnd) then begin
      Destroy();

      uiWidget.SetTarget(uiTWindow(source.wnd));

      if(Instance = nil) then
         uiWidget.Create.Instance := wdgTInputBoxOverlay
      else
         uiWidget.Create.Instance := Instance;

      uiWidget.Create.ZIndex := 100;

      wdg := wdgTInputBoxOverlay(wdgInputBox.Add('', oxNullPoint, oxNullDimensions));
   end;

   Instance := nil;
   wdg.CalledCallback := False;

   newP := p;

   inc(newP.x, source.Position.x);
   newP.y := source.Position.y - source.Dimensions.h + newP.y;

   wdg.Move(newP);
   wdg.Resize(source.Dimensions.w - wdgDEFAULT_SPACING * 2, wdg.Dimensions.h);

   wdg.Source := source;
   wdg.SetVisible();
   wdg.Select();
   wdg.Overlay := @Self;
end;

{ oxedwdgTEntityRename }

function wdgTInputBoxOverlay.OnConfirm(): boolean;
begin
   CallCallback(true);
   Result := true;
end;

function wdgTInputBoxOverlay.OnEscape(): boolean;
begin
   CallCallback(false);

   Result := true;
end;

procedure wdgTInputBoxOverlay.OnDeactivate();
begin
   CallCallback(false);
end;

procedure wdgTInputBoxOverlay.DeInitialize();
begin
   Overlay^.Wdg := nil;

   inherited DeInitialize();
end;

procedure wdgTInputBoxOverlay.CallCallback(isConfirmed: boolean);
begin
   if(not CalledCallback) then begin
      SetInvisible();
      CalledCallback := true;

      if(overlay^.Callback <> nil) then
         overlay^.Callback(Self, isConfirmed);

      overlay^.Callback := nil;

      if(isConfirmed) then
         Confirmed()
      else
         Escaped();
   end;
end;

procedure wdgTInputBoxOverlay.Confirmed();
begin

end;

procedure wdgTInputBoxOverlay.Escaped();
begin

end;

END.
