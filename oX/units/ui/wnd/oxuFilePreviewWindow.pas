{
   oxuFilePreviewWindow, file preview window
   Copyright (C) 2018. Dejan Boras

   Started On:    22.04.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxuFilePreviewWindow;

INTERFACE

USES
   uStd, uImage, StringUtils,
   {oX}
   uOX, oxuRunRoutines, oxuTypes, oxuWindows,
   {ui}
   uiuControl, uiuWindowTypes, uiuWindow, uiuTypes, uiWidgets, oxuwndBase;

TYPE

   { oxuiTFilePreviewWindow }

   oxuiTFilePreviewWindow = class(oxuiTWindowBase)
      public
         CurrentFile: string;

      procedure OnWindowCreated(); virtual;
      procedure OnCreateWidgets(); virtual;
   end;

   oxuiTFilePreviewWindowClass = class of oxuiTFilePreviewWindow;

   { oxTFilePreviewHandler }

   oxTFilePreviewHandler = record
      public
      {the window instance}
      InstanceClass: oxuiTFilePreviewWindowClass;
      {file extension we can handle}
      Extension: String;
   end;

   oxTFilePreviewHandlers = specialize TPreallocatedArrayList<oxTFilePreviewHandler>;

   { oxTFilePreviewWindow }

   oxTFilePreviewWindow = class(oxTWindowBase)
      public
         Handlers: oxTFilePreviewHandlers; static;

      class procedure AddHandler(handler: oxTFilePreviewHandler); static;
      class procedure AddHandler(const extension: string; InstanceClass: oxuiTFilePreviewWindowClass); static;
      class function FindHandler(const extension: String): oxTFilePreviewHandler; static;

      constructor Create; override;
      procedure CreateWindow; override;
      procedure AddWidgets; override;

      {opens a file preview window}
      procedure Show(const fn: string);
   end;

VAR
   oxFilePreviewWindow: oxTFilePreviewWindow;

IMPLEMENTATION

{ oxuiTFilePreviewWindow }

procedure oxuiTFilePreviewWindow.OnWindowCreated();
begin

end;

procedure oxuiTFilePreviewWindow.OnCreateWidgets();
begin

end;

{ oxTFilePreviewHandler }

class procedure oxTFilePreviewWindow.AddHandler(handler: oxTFilePreviewHandler);
begin
   Handlers.Add(handler);
end;

class procedure oxTFilePreviewWindow.AddHandler(const extension: string; InstanceClass: oxuiTFilePreviewWindowClass);
var
   handler: oxTFilePreviewHandler;

begin
   ZeroPtr(@handler, SizeOf(handler));

   handler.Extension := extension;
   handler.InstanceClass := InstanceClass;

   Handlers.Add(handler);
end;

class function oxTFilePreviewWindow.FindHandler(const extension: String): oxTFilePreviewHandler;
var
   i: loopint;

begin
   for i := 0 to Handlers.n - 1 do begin
      if(Handlers.List[i].Extension = extension) then
         exit(Handlers.List[i]);
   end;

   ZeroPtr(@Result, SizeOf(Result));
end;

constructor oxTFilePreviewWindow.Create;
begin
   Width := 320;
   Height := 70;
   ID  := uiControl.GetID('file_preview');

   inherited Create;
end;

procedure oxTFilePreviewWindow.CreateWindow;
begin
   {create the window}
   uiWindow.Create.Frame := uiwFRAME_STYLE_NONE;
   Include(uiWindow.Create.Properties, uiwndpNO_ESCAPE_KEY);
   uiWindow.Create.Properties := uiWindow.Create.Properties - [uiwndpSELECTABLE, uiwndpMOVE_BY_SURFACE, uiwndpMOVABLE];

   inherited CreateWindow;
end;

procedure oxTFilePreviewWindow.AddWidgets;
begin
   inherited;
end;

procedure oxTFilePreviewWindow.Show(const fn: string);
var
   handler: oxTFilePreviewHandler;
   w: oxuiTFilePreviewWindow;
   d: oxTDimensions;

begin
   if(fn <> '') then begin
      handler := FindHandler(ExtractFileExt(fn));

      if(handler.InstanceClass <> nil) then begin
         Instance := handler.InstanceClass;

         CreateWindow();

         w := oxuiTFilePreviewWindow(Window);

         d.w := (w.oxwParent.Dimensions.w div 3) * 2;
         d.h := (w.oxwParent.Dimensions.h div 3) * 2;

         w.Resize(d);
         w.AutoCenter();

         w.CurrentFile := fn;
         w.OnWindowCreated();
         w.OnCreateWidgets();
      end;
   end;
end;

procedure init();
begin
   oxFilePreviewWindow := oxTFilePreviewWindow.Create();
end;

procedure deinit();
begin
   FreeObject(oxFilePreviewWindow);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   ox.Init.Add(initRoutines, 'toast', @init, @deinit);

   oxTFilePreviewHandlers.Initialize(oxFilePreviewWindow.Handlers);

END.
