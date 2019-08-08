{
   oxeduWindow, oxed base window
   Copyright (C) 2016. Dejan Boras

   Started On:    31.12.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduWindow;

INTERFACE

   USES
      uStd,
      {oX}
      oxuTypes, oxuRunRoutines,
      {ui}
      uiuWindowTypes, uiuWindow, uiuDockableWindow, uiuContextMenu, uiuWidget,
      {oxed}
      uOXED, oxeduMenubar;

CONST
   OXED_WINDOW_DEFAULT_WIDTH = 640;
   OXED_WINDOW_DEFAULT_HEIGHT = 480;

TYPE
   { oxedTWindow }

   oxedTWindow = class(uiTDockableWindow)
      {shows if the window is listed in the windows list}
      WindowListed: boolean;
      WindowClass: TObject;

      procedure ListWindow();
      procedure RebuildWindowsList();

      procedure Initialize(); override;
      procedure DeInitialize(); override;

      procedure OnActivate(); override;
   end;

   oxedTUIWindowClass = class of oxedTWindow;

   oxedTWindows = specialize TSimpleList<uiTWindow>;

   { oxedTWindowClass }

   oxedTWindowClass = class
      Name: StdString;
      {should there only be one instance of this window}
      SingleInstance: boolean;
      WindowType: oxedTUIWindowClass;
      {last selected window of this type}
      LastSelected,
      {last (or only) instance of this window}
      Instance: oxedTWindow;

      constructor Create(const sName: StdString; wndType: oxedTUIWindowClass); virtual;

      function CreateWindow(): oxedTWindow;
      {called when a window is created}
      procedure WindowCreated({%H-}wnd: oxedTWindow); virtual;
   end;

   { oxedTWindowGlobal }

   oxedTWindowGlobal = record
      LastSelectedWindow: oxedTWindow;

      function Find(c: oxedTUIWindowClass): oxedTWindow;
   end;

VAR
   oxedWindow: oxedTWindowGlobal;
   oxedWindows: oxedTWindows;

IMPLEMENTATION

{ oxedTWindowGlobal }

function oxedTWindowGlobal.Find(c: oxedTUIWindowClass): oxedTWindow;
begin
   if(oxed.DockableArea <> nil) then
      result := oxedTWindow(oxed.DockableArea.Find(c, true))
   else
      result := nil;
end;

{ oxedTWindowClass }

constructor oxedTWindowClass.Create(const sName: StdString; wndType: oxedTUIWindowClass);
begin
   Name := sName;
   WindowType := wndType;
end;

function oxedTWindowClass.CreateWindow: oxedTWindow;
var
   parent: uiTWindow;

begin
   if(SingleInstance and (Instance <> nil)) then
      exit(nil);

   parent := oxed.DockableArea;

   uiWindow.Create.Instance := WindowType;

   result := oxedTWindow(uiWindow.MakeChild(parent, Name,
      oxPoint(5, 5 + OXED_WINDOW_DEFAULT_HEIGHT),
      oxDimensions(OXED_WINDOW_DEFAULT_WIDTH, OXED_WINDOW_DEFAULT_HEIGHT)));
   result.WindowClass := Self;

   Instance := Result;

   WindowCreated(result);
end;

procedure oxedTWindowClass.WindowCreated(wnd: oxedTWindow);
begin

end;

{ oxedTWindow }

procedure oxedTWindow.ListWindow();
begin
   oxedWindows.Add(Self);

   RebuildWindowsList();
end;

procedure windowContextCallback({%H-}wdg: uiTWidget; {%H-}menu: TObject; item: uiPContextMenuItem);
var
   w: uiTWindow;
   inFront: boolean;

begin
   w := oxedWindows.List[item^.Index];

   inFront := w.InFront();

   w.Open();

   if(inFront) and (uiwndpMAXIMIZED in w.Properties) then
      w.Restore();
end;

procedure oxedTWindow.RebuildWindowsList();
var
   context: uiTContextMenu;
   i: loopint;

begin
  if(oxedMenubar.Windows <> nil) and (oxedMenubar.Bar <> nil) then begin
     context := oxedMenubar.Windows;

     context.RemoveAll();
     oxedMenubar.SetupWindowsMenu();

     // TODO: Maybe just remove the window items by implementing a RemoveFrom() method

     if(oxedWindows.n > 0) then begin
        context.AddSeparator();

        for i := 0 to (oxedWindows.n - 1) do
            context.AddItem(oxedWindows.list[i].Title, 0, @windowContextCallback)^.Index := i;
     end;
  end;
end;

procedure oxedTWindow.Initialize();
begin
   inherited Initialize;

   ListWindow();

  if(WindowClass <> nil) then
     oxedTWindowClass(WindowClass).LastSelected := Self;
end;

procedure oxedTWindow.DeInitialize();
var
   idx: loopint;

begin
   inherited DeInitialize;

   idx := oxedWindows.Find(Self);
   if(idx > -1) then begin
      oxedWindows.Remove(idx);

      RebuildWindowsList();
   end;

   if(oxedWindow.LastSelectedWindow = Self) then
      oxedWindow.LastSelectedWindow := nil;

   if(WindowClass <> nil) then begin
      if(oxedTWindowClass(WindowClass).Instance = Self) then
         oxedTWindowClass(WindowClass).LastSelected := nil;

      if(oxedTWindowClass(WindowClass).Instance = Self) then
         oxedTWindowClass(WindowClass).Instance := nil;
   end;
end;

procedure oxedTWindow.OnActivate();
begin
   inherited OnActivate;

   oxedWindow.LastSelectedWindow := Self;

   if(WindowClass <> nil) then
      oxedTWindowClass(WindowClass).LastSelected := Self;
end;

procedure deinit();
var
   windows: uiTPreallocatedWindowListArray;
   i: loopint;

begin
   windows.Initialize(windows);

   if(oxed.DockableArea <> nil) then begin
     oxed.DockableArea.FindTypeRecursive(oxedTWindow, windows);

     {remove all WindowClass references as they're destroyed before the windows are destroyed}
     for i := 0 to windows.n - 1 do
        oxedTWindow(windows.List[i]).WindowClass := nil;
   end;
end;

VAR
   oxedInitRoutines: oxTRunRoutine;

INITIALIZATION
   oxed.Init.dAdd(oxedInitRoutines, 'oxed.window', @deinit);

   oxedWindows.InitializeValues(oxedWindows);

END.

