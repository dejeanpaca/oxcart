{
   wdguLink, link widget for the UI
   Copyright (C) 2016. Dejan Boras

   Started On:    03.10.2016.
}

{$INCLUDE oxdefines.inc}
UNIT wdguLink;

INTERFACE

   USES
      uStd, uColors, sysutils,
      appuMouse, uLog, uApp,
      {oX}
      oxuTypes,
      {ui}
      uiuTypes, uiuSkinTypes,
      uiuWidget, uiWidgets, wdguLabel;

CONST
  wdgscLINK_TEXT      = 0;
  wdgscLINK_HOVER     = 1;
  wdgscLINK_DISABLED  = 2;
  wdgscLINK_USED      = 3;

  wdgLinkSkinColorDescriptor: array[0..3] of uiTWidgetSkinColorDescriptor = (
      (
         Name: 'text';
         Color: (32, 32, 255, 255)
      ),
      (
         Name: 'hover';
         Color: (192, 192, 255, 255)
      ),
      (
         Name: 'disabled';
         Color: (127, 127, 192, 255)
      ),
      (
         Name: 'used';
         Color: (160, 64, 160, 255)
      )
   );

  wdgLinkSkinDescriptor: uiTWidgetSkinDescriptor = (
     Name: 'link';

     nColors: Length(wdgLinkSkinColorDescriptor);
     nImages: 0;
     nBools: 0;
     nStrings: 0;

     Colors: @wdgLinkSkinColorDescriptor;
     Images: nil;
     Bools: nil;
     Strings: nil;
     Setup: nil
  );


TYPE

   { wdgTLink }

   wdgTLink = class(wdgTLabel)
      {is the link used}
      Used: boolean;
      {the actual link}
      Link: string;
      Callback: uiTWidgetCallback;

      procedure Render(); override;
      procedure Point(var e: appTMouseEvent; {%H-}x, {%H-}y: longint); override;

      procedure UseLink();
      procedure SetLink(const newLink: string);
   end;

   { wdgTLinkGlobal }

   wdgTLinkGlobal = record
      DefaultColor: TColor4ub;

      function Add(const Caption: string; const Link: string;
                 const Pos: oxTPoint; const Dim: oxTDimensions): wdgTLink;
   end;

VAR
   wdgLink: wdgTLinkGlobal;

IMPLEMENTATION

VAR
   internal: uiTWidgetClass;

procedure InitWidget();
begin
   internal.Instance := wdgTLink;
   internal.skinDescriptor := @wdgLinkSkinDescriptor;
   internal.Done();
end;

{ wdgTLink }

procedure wdgTLink.Render();
begin
   if(wdgpENABLED in Properties) then begin
      if(not Used) then begin
         if(wdgpHOVERING in Properties) then
            inherited Render(GetColor(wdgscLINK_HOVER))
         else
            inherited Render(GetColor(wdgscLINK_TEXT));
      end else
         inherited Render(GetColor(wdgscLINK_USED));
   end else
      inherited Render(GetColor(wdgscLINK_DISABLED));
end;

procedure wdgTLink.Point(var e: appTMouseEvent; x, y: longint);
begin
   if(e.IsReleased()) then begin
      Used := true;

      UseLink();
   end;
end;

procedure wdgTLink.UseLink();
begin
   if((Link <> '')) then begin
      if(not app.OpenLink(Link)) then
         log.e('Failed opening link: ' + Link);
   end;

   Callback.Call();
end;

procedure wdgTLink.SetLink(const newLink: string);
begin
   Link := newLink;
end;

function wdgTLinkGlobal.Add(const Caption: string; const Link: string;
            const Pos: oxTPoint; const Dim: oxTDimensions): wdgTLink;
begin
   result := wdgTLink(uiWidget.Add(internal, Pos, Dim));

   if(result <> nil) then begin
      result.SetCaption(Caption);
      result.SetLink(Link);

      result.AutoSize();
   end;
end;

INITIALIZATION
   wdgLink.DefaultColor := cBlue4ub;
   internal.Register('widget.link', @InitWidget);
END.
