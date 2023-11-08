{
   wdguLink, link widget for the UI
   Copyright (C) 2016. Dejan Boras
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
      uiuWidget, uiWidgets, uiuRegisteredWidgets,
      wdguLabel, wdguBase;

CONST
  wdgscLINK_TEXT      = 0;
  wdgscLINK_HOVER     = 1;
  wdgscLINK_DISABLED  = 2;
  wdgscLINK_USED      = 3;

  wdgLinkSkinColorDescriptor: array[0..3] of uiTWidgetSkinColorDescriptor = (
      (
         Name: 'text';
         Color: (92, 92, 255, 255)
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

TYPE

   { wdgTLink }

   wdgTLink = class(wdgTLabel)
      {is the link used}
      Used: boolean;
      {the actual link}
      Link: StdString;
      Callback: uiTWidgetCallback;

      procedure Render(); override;
      procedure Point(var e: appTMouseEvent; {%H-}x, {%H-}y: longint); override;

      procedure UseLink();
      procedure SetLink(const newLink: StdString);
   end;

   { wdgTLinkGlobal }

   wdgTLinkGlobal = object(specialize wdgTBase<wdgTLink>)
      DefaultColor: TColor4ub; static;

      function Add(const Caption: StdString; const Link: StdString;
                 const Pos: oxTPoint; const Dim: oxTDimensions): wdgTLink;
      function Add(const Caption: StdString; const Link: StdString): wdgTLink;
      function Add(const link: uiTLink): wdgTLink;
   end;

VAR
   wdgLink: wdgTLinkGlobal;

IMPLEMENTATION

{ wdgTLink }

procedure wdgTLink.Render();
begin
   if(wdgpENABLED in Properties) then begin
      if(not Used) then begin
         if Hovering() then
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

procedure wdgTLink.SetLink(const newLink: StdString);
begin
   Link := newLink;
end;

function wdgTLinkGlobal.Add(const Caption: StdString; const Link: StdString;
            const Pos: oxTPoint; const Dim: oxTDimensions): wdgTLink;
begin
   Result := AddInternal(Pos, Dim);

   if(Result <> nil) then begin
      Result.SetCaption(Caption);
      Result.SetLink(Link);

      AddDone(Result);
   end;
end;

function wdgTLinkGlobal.Add(const Caption: StdString; const Link: StdString): wdgTLink;
begin
   Result := AddInternal();

   if(Result <> nil) then begin
      Result.SetCaption(Caption);
      Result.SetLink(Link);

      AddDone(Result);
   end;
end;

function wdgTLinkGlobal.Add(const link: uiTLink): wdgTLink;
begin
   Result := AddInternal();

   if(Result <> nil) then begin
      Result.SetCaption(link.Caption);
      Result.SetLink(link.Link);

      if(link.Summary <> '') then
         Result.SetHint(link.Summary);

      AddDone(Result);
   end;
end;

procedure init();
begin
   wdgLink.Internal.Done(wdgTLink);
end;

INITIALIZATION
   wdgLink.Create();
   wdgLink.DefaultColor := cBlue4ub;
   wdgLink.Internal.Register('link', @init);
   wdgLink.Internal.SkinDescriptor.UseColors(wdgLinkSkinColorDescriptor);

END.
