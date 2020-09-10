{
   oxuScreenshot, captures a screenshot
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuScreenshot;

INTERFACE

   USES
      sysutils,
      uStd, uError, uLog, StringUtils, uFileUtils,
      {app}
      appuKeys, appuPaths,
      {oX}
      uOX, oxuRunRoutines, oxuRenderer, oxuRendererScreenshot,
      oxuWindowTypes, oxuWindow, oxuGlobalKeys,
      {dImage}
      uImage, imguRW, imguOperations;

TYPE
   oxTScreenshotNameRoutine = function(): StdString;

   { oxTScreenshot }

   oxTScreenshot = record
      CaptureKey: appTKey;
      Path: StdString;

      GetScreenshotName: oxTScreenshotNameRoutine;

      {makes a screenshot}
      function Make(var image: imgTImage; wnd: oxTWindow = nil): loopint;
      function Make(var image: imgTImage; wnd: oxTWindow; x, y, w, h: loopint): loopint;
      function CallRenderer(var image: imgTImage; wnd: oxTWindow; x, y, w, h: loopint): loopint;

      {saves the captures screenshot}
      function Save(const fn: string; var img: imgTImage): loopint;

      {captures and saves the screenshot}
      function Get(const fn: string; wnd: oxTWindow = nil): loopint;
      function Get(wnd: oxTWindow = nil): loopint;
   end;

VAR
   oxScreenshot: oxTScreenshot;

IMPLEMENTATION

function oxTScreenshot.Make(var image: imgTImage; wnd: oxTWindow = nil): loopint;
begin
   Result := Make(image, wnd, 0, 0, wnd.Dimensions.w, wnd.Dimensions.h);
end;

function oxTScreenshot.Make(var image: imgTImage; wnd: oxTWindow; x, y, w, h: loopint): loopint;
begin
   Result := CallRenderer(image, wnd, x, y, w, h);

   if(Result <> eNONE) then
      log.w('Failed to take screenshot: ' + GetErrorCodeString(Result));
end;

function oxTScreenshot.CallRenderer(var image: imgTImage; wnd: oxTWindow; x, y, w, h: loopint): loopint;
var
   errorCode: loopint;
   screenshotComponent: oxTRendererScreenshotComponent;

begin
   Result := eNONE;

   screenshotComponent := oxTRendererScreenshotComponent(oxRenderer.GetComponent('screenshot'));

   if(screenshotComponent = nil) then
      exit(eUNSUPPORTED);

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

      screenshotComponent.Grab(wnd, image, x, y, w, h);

      {get the image to TGA pixel format}
      errorCode := imgOperations.Transform(image, PIXF_BGR);

      if(errorCode <> 0) then
         Result := oxeIMAGE;
   end else
      Result := oxeIMAGE;
end;

function oxTScreenshot.Save(const fn: string; var img: imgTImage): loopint;
var
   imgError: loopint;

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

function oxTScreenshot.Get(const fn: string; wnd: oxTWindow = nil): loopint;
var
   image: imgTImage = nil;
   errorCode: loopint;

begin
   errorCode := Make(image, wnd);

   if(errorCode <> 0) then begin
      log.e('Failed to create a screenshot: ' + sf(errorCode));
      img.Dispose(image);
      exit(errorCode);
   end;

   Result := Save(fn, image);
   img.Dispose(image);
end;

function oxTScreenshot.Get(wnd: oxTWindow = nil): loopint;
var
   fn,
   name: string;

begin
   name := GetScreenshotName();
   fn := appPath.Configuration.Path + 'screenshots' + DirectorySeparator + name + '.tga';

   Result := Get(fn, wnd);
end;

function getScreenshotName(): StdString;
begin
   Result := FormatDateTime('yyyymmdd"T"hhmmss', Now);
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
   oxScreenshot.GetScreenshotName := @getScreenshotName;

   ox.Init.Add('screenshot', @initialize);

END.
