{
   oxeduStatusbar, status bar
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduStatusbar;

INTERFACE

   USES
      uStd, uColors, uAppInfo,
      {ui}
      uiWidgets, wdguWorkbar, wdguToolbar, wdguStatusbar,
      {oxed}
      oxeduProjectRunner;

TYPE
   { oxedTStatusbarGlobal }

   oxedTStatusbarGlobal = record
      Status: wdgTToolbar;
      Caption: wdgPToolbarItem;

      procedure Initialize();
      procedure SetCaption(const what: string);
   end;

VAR
   oxedStatusbar: oxedTStatusbarGlobal;

IMPLEMENTATION

{ oxedTStatusbarGlobal }

procedure oxedTStatusbarGlobal.Initialize;
begin
   Status := wdgToolbar.Add();
   Status.AutoPositionTarget := wdgWORKBAR_POSITION_BOTTOM;
   Status.AutoPosition();

   Status.Color := wdgStatusbar.Color;
   Caption := Status.AddCaption(appInfo.GetVersionString());
   Caption^.SetHighlightable(false);
end;

procedure oxedTStatusbarGlobal.SetCaption(const what: string);
begin
   if(Caption <> nil) and (Status <> nil) then begin
      Caption^.Caption := what;
      Status.ItemChanged();
   end;
end;

VAR
   previousColor: TColor4ub;

procedure projectStart();
begin
   previousColor := oxedStatusbar.Status.Color;
   oxedStatusbar.Status.Color.Assign(96, 96, 192, 255);
end;

procedure projectStop();
begin
   oxedStatusbar.Status.Color := previousColor;
end;

INITIALIZATION
   oxedProjectRunner.OnStart.Add(@projectStart);
   oxedProjectRunner.OnStop.Add(@projectStop);

END.
