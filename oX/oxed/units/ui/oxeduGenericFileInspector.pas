{
   oxeduFileInspectors, handles file inspectors
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduGenericFileInspector;

INTERFACE

   USES
      uStd,
      {ui}
      uiWidgets, uiuWidget,
      wdguWorkbar, wdguGroup, wdguInputBox,
      {oxed}
      uOXED, oxeduWindow, oxeduwndInspector,
      oxeduInspectFile;

TYPE

   { oxedTGenericFileInspector }

   oxedTGenericFileInspector = class(oxedTInspectFile)
      wdg: record
         Information: wdgTGroup;
         Name: wdgTInputBox;
      end;

      procedure SetFile(const fn: StdString); override;
      procedure Open(wnd: oxedTWindow); override;
      procedure SizeChanged(wnd: oxedTWindow); override;
   end;

VAR
   oxedGenericFileInspector: oxedTGenericFileInspector;

IMPLEMENTATION

procedure init();
begin
   oxedGenericFileInspector := oxedTGenericFileInspector.Create();
   oxedInspectFile.GenericInspector := oxedGenericFileInspector;
end;

procedure deinit();
begin
   if(oxedInspectFile.GenericInspector = oxedGenericFileInspector) then
      oxedInspectFile.GenericInspector := nil;

   FreeObject(oxedGenericFileInspector);
end;

{ oxedTGenericFileInspector }

procedure oxedTGenericFileInspector.SetFile(const fn: StdString);
var
   inspector: oxedTInspectorWindow;

begin
   inspector := oxedTInspectorWindow(oxedInspector.Instance);

   if(fn <> '') then begin
      wdg.Name.Enable(true);
      wdg.Name.SetText(fn);
   end else begin
      wdg.Name.Enable(false);
   end;

   SizeChanged(inspector);
end;

procedure oxedTGenericFileInspector.Open(wnd: oxedTWindow);
var
   inspector: oxedTInspectorWindow;
   group: oxedTInspectorWindowGroup;

begin
   inspector := oxedTInspectorWindow(wnd);

   { header }
   inspector.wdg.Header := wdgWorkbar.Add(oxedInspector.Instance);

   uiWidget.PushTarget();
   inspector.wdg.Header.SetTarget();

   wdg.Name := wdgInputBox.Add('');
   wdg.Name.ReadOnly := true;

   uiWidget.PopTarget();

   { transform group }
   group := inspector.AddGroup('Information');

   wdg.Information := group.Wdg;
   uiWidget.PushTarget();

   uiWidget.PopTarget();

   SetFile('');
end;

procedure oxedTGenericFileInspector.SizeChanged(wnd: oxedTWindow);
var
   inspector: oxedTInspectorWindow;

begin
   inspector := oxedTInspectorWindow(wnd);
   inspector.wdg.Header.Move(0, wnd.Dimensions.h - 1);
   inspector.wdg.Header.Resize(wnd.Dimensions.w, 32);

   wdg.Name.Resize(wnd.Dimensions.w - wdgDEFAULT_SPACING * 2, inspector.wdg.Header.Dimensions.h - 10);
   wdg.Name.Move(wdg.Name.Position.x, 20);
   wdg.Name.SetPosition(wdgPOSITION_VERTICAL_CENTER);
end;

INITIALIZATION
   oxed.Init.Add('inspector.file.generic', @init, @deinit);

END.
