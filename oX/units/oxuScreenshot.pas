{
   oxuScreenshot, captures a screenshot
   Copyright (C) 2016. Dejan Boras

   Started On:    20.09.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxuScreenshot;

INTERFACE

   USES
      sysutils,
      uStd, uLog, StringUtils, uFileUtils,
      {app}
      appuKeys, appuPaths,
      {oX}
      uOX, oxuRunRoutines, oxuRenderer, oxuWindowTypes, oxuWindow, oxuGlobalKeys,
      {dImage}
      uImage, imguRW, imguOperations;

TYPE

   { oxTScreenshot }

   oxTScreenshot = record
      CaptureKey: appTKey;
      Path: string;

      {makes a screenshot}
      function Make(var image: imgTImage; wnd: oxTWindow = nil): longint;
      function Make(var image: imgTImage; wnd: oxTWindow; x, y, w, h: loopint): longint;
      function CallRenderer(var image: imgTImage; wnd: oxTWindow; x, y, w, h: loopint): longint;

      {saves the captures screenshot}
      function Save(const fn: string; var img: imgTImage): longint;

      {captures and saves the screenshot}
      function Get(const fn: string; wnd: oxTWindow = nil): longint;
      function Get(wnd: oxTWindow = nil): longint;
   end;

VAR
   oxScreenshot: oxTScreenshot;

IMPLEMENTATION

function oxTScreenshot.Make(var image: imgTImage; wnd: oxTWindow = nil): longint;
begin
   Result := Make(image, wnd, 0, 0, wnd.Dimensions.w, wnd.Dimensions.h);
end;

function oxTScreenshot.Make(var image: imgTImage; wnd: oxTWindow; x, y, w, h: loopint): longint;
begin
   Result := CallRenderer(image, wnd, x, y, w, h);

   if(Result <> eNONE) then
      log.w('Failed to take screenshot: ' + GetErrorCodeString(Result));
end;

function oxTScreenshot.CallRenderer(var image: imgTImage; wnd: oxTWindow; x, y, w, h: loopint): longint;
var
   errcode: longint;

begin
   result := eNONE;

   {free the previous image}
   img.Dispose(image);

   {prepare the image}
   image := imgTImage.Create();

   if(x < 0) or (y < 0) or (x >= wnd.Dimensions.w) or (y >= wnd.Dimensions.h) then
      exit(eINVALID_ARG);

   if(w > wnd.Dimensions.w - x) then
      w := wnd.Dimensions.w - x;

   if(h > wnd.Dimensions.h - y) then
      h := wnd.Dimensions.h - y;

   image.Width      := w;
   image.Height     := h;
   image.PixF       := PIXF_RGB;
   image.Origin     := imgcORIGIN_BL;

   image.Calculate();
   if(image.Allocate() = 0) then begin
      if(wnd = nil) then
         wnd := oxWindow.Current;

      oxRenderer.Screenshot(wnd, image, x, y, w, h);

      {get the image to TGA pixel format}
      errcode := imgOperations.Transform(image, PIXF_BGR);

      if(errcode <> 0) then
         result := oxeIMAGE;
   end else
      result := oxeIMAGE;
end;

function oxTScreenshot.Save(const fn: string; var img: imgTImage): longint;
var
   imgError: longint;

begin
   Result := eNONE;

   if(fn <> '') and (img <> nil) then begin
      imgError := imgFile.Write(img, fn);

      if(imgError <> 0) then begin
         log.e('Failed to save screenshot (uImage: ' + GetErrorCodeString(imgError) + '): ' + fn);

         Result := oxeIMAGE;
      end else
         log.i('Screenshot: ' + fn);
   end;
end;

function oxTScreenshot.Get(const fn: string; wnd: oxTWindow = nil): longint;
var
   image: imgTImage = nil;
   errCode: longint;

begin
   errCode := Make(image, wnd);
   if(errCode <> 0) then begin
      log.e('Failed to create a screenshot: ' + sf(errCode));
      img.Dispose(image);
      exit(errCode);
   end;

   Result := Save(fn, image);
   img.Dispose(image);
end;

function oxTScreenshot.Get(wnd: oxTWindow = nil): longint;
var
   fn,
   name: string;

begin
   name := DateTimeToStr(Now);
   fn := appPath.Configuration.Path + 'screenshots' + DirectorySeparator + name + '.tga';

   Result := Get(fn, wnd);
end;

procedure gkHandler(wnd: oxTWindow);
begin
   oxScreenshot.Get(wnd);
end;

CONST
   {global key to capture screenshots}
   gkHandlerKey: oxTGlobalKeyHandler = (
      Key: (
         Code: kcF12;
         State: 0;
      );
      Pressed: nil;
      Released: @gkHandler;
      Name: 'ox.screenshot'
   );

procedure initialize();
begin
   oxScreenshot.Path := appPath.Configuration.Path + 'screenshots';
   {create a screenshot directory}
   FileUtils.CreateDirectory(oxScreenshot.Path);

   gkHandlerKey.Key := oxScreenshot.CaptureKey;
   oxGlobalKeys.Hook(gkHandlerKey);
end;

INITIALIZATION
   oxScreenshot.CaptureKey := gkHandlerKey.Key;

   ox.Init.Add('screenshot', @initialize);

END.
