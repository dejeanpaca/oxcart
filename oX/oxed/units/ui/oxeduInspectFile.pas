{
   oxeduInspectFile, file inspector
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduInspectFile;

INTERFACE

   USES
      uStd,
      {ui}
      uiWidgets,
      wdguLabel,
      {oxed}
      uOXED,
      oxeduWindow, oxeduwndInspector;

TYPE
   { oxedTInspectFile }

   oxedTInspectFile = class(oxedTInspector)
      wdg: record

      end;

      procedure SetFile(const fn: StdString);

      procedure Open(wnd: oxedTWindow); override;
      procedure SizeChanged(wnd: oxedTWindow); override;
   end;

VAR
   oxedInspectFile: oxedTInspectFile;

IMPLEMENTATION

{ oxedTInspectFile }

procedure oxedTInspectFile.Open(wnd: oxedTWindow);
var
   inspector: oxedTInspectorWindow;

begin
   inspector := oxedTInspectorWindow(wnd);
end;

procedure oxedTInspectFile.SetFile(const fn: StdString);
begin
end;

procedure oxedTInspectFile.SizeChanged(wnd: oxedTWindow);
var
   inspector: oxedTInspectorWindow;

begin
   inspector := oxedTInspectorWindow(wnd);
end;

procedure init();
begin
   oxedInspectFile := oxedTInspectFile.Create();
end;

procedure deinit();
begin
   FreeObject(oxedInspectFile);
end;

INITIALIZATION
   oxed.Init.Add('inspector.file', @init, @deinit);

END.
