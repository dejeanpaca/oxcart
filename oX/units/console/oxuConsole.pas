{
   oxuConsole, command console front-end
   Copyright (c) 2011. Dejan Boras

   Started On:    30.07.2012.
}

{$INCLUDE oxdefines.inc}
UNIT oxuConsole;

INTERFACE

   USES
     sysutils, uStd, uLog, uColors, StringUtils, udvars, dvaruFile, vmVector, ConsoleUtils,
     {app}
     uAppInfo, appuKeys, appuEvents, appuKeyEvents, appuPaths, appuActionEvents,
     {oX}
     uOX, oxuTypes, oxuGlobalKeys, oxuFont, oxuWindow, oxuRun, oxuRunRoutines,
     oxuConsoleBackend, oxuWindowTypes, oxuWindows, oxuRenderUtilities,
     {ui}
     oxuUI, uiuDraw, uiuTypes, uiuWindowTypes, uiuWindow, uiuControl, uiuSkinTypes,
     uiuWidget, uiWidgets, uiuSkin, wdguInputBox;

TYPE

   { oxTConsoleWindow }

   oxTConsoleWindow = class(uiTWindow)
      procedure DeInitialize(); override;
   end;

   { oxTConsoleGlobal }

   oxTConsoleGlobal = record
      DoLog,
      Alpha,
      Fullscreen,
      WriteTime: boolean;
      Height: single;
      IbHeight,
      StatusHeight,
      WindowZ: longint;

      Console: conTConsole;
      Font: oxTFont;
      Window,
      { used to specify a window in which the console window should reside }
      ParentWindow: uiTWindow;
      { console window ID }
      WindowId: uiTControlID;
      {console input widget}
      wdgInput: wdgTInputBox;

      Colors: record
         Background,
         StatusBackground,
         InputBackground,
         InputText,
         InputCursor,
         InputStatus: TColor4ub;
      end;

      DrawInputStatus: boolean;
      InputStatus: StdString;

      procedure SetFont(newFont: oxTFont);
      procedure Activate();
      procedure DeActivate();

      function GetIBStatusWidth(): loopint;
      function GetIBLeftOffset(): loopint;
   end;

VAR
   oxConsole: oxTConsoleGlobal;

IMPLEMENTATION

CONST
   cidCON            = 00;
   cidQUIT           = 01;
   cidABOUT          = 02;
   cidCLEAR_CONSOLE  = 03;
   cidRESTART        = 04;
   cidHELP           = 05;

   conCommands: array[0..5] of conTCommand = (
      (sID: 'con'; sHelp: 'console setup'; nID: cidCON),
      (sID: 'quit'; sHelp: 'quit the program'; nID: cidQUIT),
      (sID: 'about'; sHelp: 'show the about text'; nID: cidABOUT),
      (sID: 'clear_console'; sHelp: 'clears the attached console (terminal) output'; nID: cidCLEAR_CONSOLE),
      (sID: 'restart'; sHelp: 'Restarts the program'; nID: cidRESTART),
      (sID: 'help'; sHelp: 'show help'; nID: cidHELP)
   );

TYPE
   oxTConsoleData = record
      MaxLines,
      MaxVisibleChars,
      fh,
      OutputStartY: longint;
   end;

   { oxTConsoleInputBox }

   oxTConsoleInputBox = class(wdgTInputBox)
      function Key(var keyEvent: appTKeyEvent): boolean; override;
   end;

VAR
   data: oxTConsoleData;

   WDGID_CONSOLE_IB: uiTControlID;

   consoleInputSkin: uiTWidgetSkin;
   conHandler: conTHandler;

   dvgConsoleHistory,
   dvgConsole: TDVarGroup;

   dvHistory,
   dvWriteTime,
   dvFullscreen,
   dvHeight: TDVar;
   currentHistory: StdString;

procedure consoleReconfigure();
var
   clientTotal: longint = 0;

begin
   if(oxConsole.Font <> nil) then begin
      data.fh              := oxConsole.Font.GetHeight() + 2;

      data.OutputStartY    := oxConsole.Font.GetHeight() + 4 + oxConsole.StatusHeight;
      clientTotal          := (oxConsole.Window.Dimensions.h - (oxConsole.wdgInput.Dimensions.h + 4 + oxConsole.StatusHeight));

      data.MaxLines        := (clientTotal div data.fh);
      data.MaxVisibleChars := oxConsole.Window.Dimensions.w div oxConsole.Font.GetWidth() - 4;
   end;
end;

procedure adjustSize();
var
   h: loopint;

begin
   h := 0;

   if(oxConsole.Window = nil) then
      exit;

   {calculate window height}
   if(not oxConsole.Fullscreen) then
      h := round(oxConsole.Height * oxConsole.Window.Parent.Dimensions.h)
   else
      h := oxConsole.Window.Parent.Dimensions.h;

   oxConsole.Window.Move(0, uiTWindow(oxConsole.Window.Parent).Dimensions.h - 1);
   oxConsole.Window.Resize(oxConsole.Window.Parent.Dimensions.w, h);

   oxConsole.wdgInput.Resize(oxConsole.Window.Dimensions.w - oxConsole.GetIBLeftOffset(), oxConsole.IbHeight);
end;

{ oxTConsoleInputBox }

VAR
   currentEntry: StdString;
   historyIndex: longint = 0;

{ oxTConsoleWindow }

procedure oxTConsoleWindow.DeInitialize();
begin
   oxConsole.Window := nil;
end;

function oxTConsoleInputBox.Key(var keyEvent: appTKeyEvent): boolean;
begin
   if(keyEvent.Key.Equal(kcUP)) then begin
      if(not keyEvent.Key.Released()) and (historyIndex < oxConsole.Console.History.Entries.n) then begin
         if(historyIndex = 0) then
            currentEntry := oxConsole.wdgInput.GetText();

         inc(historyIndex);

         SetText(oxConsole.Console.History.Entries.List[(oxConsole.Console.History.Entries.n - historyIndex)]);
      end;

      exit(true);
   end else if(keyEvent.Key.Equal(kcDOWN)) then begin
      if(not keyEvent.Key.Released()) and (historyIndex > 0) then begin
         dec(historyIndex);

         if(historyIndex = 0) then
             SetText(currentEntry)
         else
            SetText(oxConsole.Console.History.Entries.List[(oxConsole.Console.History.Entries.n - historyIndex)])
      end;

      exit(true);
   end else if(keyEvent.Key.Equal(kcESC)) then
      exit(false);

   Result := inherited Key(keyEvent);
end;

{ INTERFACE }

procedure oxTConsoleGlobal.SetFont(newFont: oxTFont);
begin
   if(newFont <> nil) then begin
      oxConsole.Font := newFont;
      consoleReconfigure();
   end;
end;

procedure oxTConsoleGlobal.Activate();
begin
   oxConsole.Console.Activate();
   adjustSize();
end;

procedure oxTConsoleGlobal.DeActivate();
begin
   oxConsole.Console.DeActivate();
end;

function oxTConsoleGlobal.GetIBStatusWidth(): loopint;
begin
   Result := oxConsole.Font.GetLength(oxConsole.InputStatus) + 4;
end;

function oxTConsoleGlobal.GetIBLeftOffset(): loopint;
var
   width: loopint;

begin
   Result := 0;

   if(DrawInputStatus) then begin
      width := GetIBStatusWidth();

      Result := width + ibHeight div 2 + 1;
   end;
end;

{ CONSOLE CONTROL }

function parentResize({%H-}wnd: uiTControl; const e: appTEvent): longint;
begin
   Result := -1;

   if(uiWindow.GetNotification(e) = uiWINDOW_RESIZE) then
      adjustSize();
end;

{ CONSOLE COMMAND HANDLER }

VAR
   firstAboutWrite: boolean = true;

procedure oxconWriteAbout();
var
   color: TColor4ub;
   previousLog: PLog;
   s: StdString;

begin
   previousLog := oxConsole.Console.LogOutput;

   if(firstAboutWrite) then begin
      oxConsole.Console.LogOutput := nil;
      firstAboutWrite := false;
   end;

   color := oxConsole.Console.Colors.Current;

   console.Color4ub(192, 192, 255, 255);

   oxConsole.Console.i();

   s := appInfo.GetVersionString();
   oxConsole.Console.i(s);

   oxConsole.Console.i(oxEngineName + ' Engine v' + oxsVersion);
   oxConsole.Console.i();
   oxConsole.Console.i('Copyright (c) 2007. Dejan Boras');
   oxConsole.Console.i();

   oxConsole.Console.Colors.Current := color;
   oxConsole.Console.LogOutput := previousLog;
end;

procedure consoleWriteSettings();
begin
   oxConsole.Console.i('   Alpha enabled : ' + sf(oxConsole.Alpha) + '.');
   oxConsole.Console.i('   Alpha value   : ' + sf(oxConsole.Colors.Background[3]));
   oxConsole.Console.i('   Fullscreen    : ' + sf(oxConsole.Fullscreen) + '.');
end;

procedure conWriteInvalidArgument();
begin
   oxConsole.Console.w('The specified argument or value is not valid.');
end;

procedure conWriteInsufficientArguments();
begin
   oxConsole.Console.w('Insufficient arguments.');
end;

procedure consoleCommand(var con: conTConsole);
var
   i: loopint;
   cmd: StdString;

begin
   if(con.arguments.n > 1) then begin
      cmd := LowerCase(con.arguments.list[1]);
      con.SkipHistoryCurrent := true;

      if(cmd = 'info') then begin
         con.i('Console information: ');
         consoleWriteSettings();
         oxConsole.Console.i();
      end else if(cmd = 'history') then begin
         for i := 0 to (con.History.Entries.n - 1) do
            con.s(con.History.Entries.List[i]);
      end else if(cmd = 'fullscreen') then begin
         oxConsole.Fullscreen := not oxConsole.Fullscreen;
         log.i('Console fullscreen set to: ' + sf(oxConsole.Fullscreen));
         adjustSize();
      end else
         con.w('Unknown or unsupported console command.');
   end else
      con.w('No console command arguments specified.');
end;

procedure consoleHelp(var con: conTConsole);
var
   i: loopint;
   handler: conPHandler;

begin
   handler := con.CommandHandlers.s;

   while(handler <> nil) do begin
      for i := 0 to handler^.nCommands -1 do begin
         if(handler^.Commands^[i].sHelp <> '') then
            log.i(handler^.Commands^[i].sID + ' > `' + handler^.Commands^[i].sHelp)
         else
            log.i(handler^.Commands^[i].sID);
      end;

      handler := handler^.Next;
   end;

   for i := 0 to con.Commands.n - 1 do begin
      log.i(con.Commands.List[i].sID);
   end;

   log.i();
end;

procedure oxconCommandNotify(var con: conTConsole; nID: longint);
begin
   case nID of
      cidCON:
         consoleCommand(con);
      cidQUIT:
         appActionEvents.QueueQuitEvent();
      cidABOUT:
         oxconWriteAbout();
      cidRESTART:
         oxRun.Restart();
      cidCLEAR_CONSOLE:
         ConsoleUtils.console.Clear();
      cidHELP:
         consoleHelp(con);
      else
         con.e('Error: Unknown console command.');
   end;
end;


{ RENDERING }

procedure consoleRender(var wnd: uiTWindow);
var
   i,
   clipSize: longint;
   pStr: StdString;
   width,
   x,
   y,
   y2,
   start,
   repEnd,
   w,
   cPos: loopint;
   t: array[0..2] of TVector3f;
   f: oxTFont;
   r: oxTRect;

begin
   y := 0;

   if(data.MaxLines > 0) and (oxConsole.Font <> nil) then begin
      y := wnd.RPosition.y;
      x := wnd.RPosition.x;

      wnd.SetColor(oxConsole.Colors.background);
      uiDraw.Box(x, y - (wnd.Dimensions.h - oxConsole.wdgInput.Dimensions.h), x + wnd.Dimensions.w, y);

      {status background}
      if(oxConsole.StatusHeight > 0) then begin
         wnd.SetColor(oxConsole.Colors.StatusBackground);
         uiDraw.Box(x, y - oxConsole.StatusHeight, x + wnd.Dimensions.w, y);
      end;

      {input background}
      wnd.SetColor(oxConsole.Colors.InputBackground);
      uiDraw.Box(x, y - (wnd.Dimensions.h),
         x + wnd.Dimensions.w, y - (wnd.Dimensions.h - oxConsole.wdgInput.Dimensions.h));

      {input triangle}
      if(oxConsole.DrawInputStatus) then begin
         w := oxConsole.IbHeight div 2;

         width := oxConsole.GetIBStatusWidth();
         y := wnd.RPosition.y - wnd.Dimensions.h + 3;
         y2 := y + oxConsole.IbHeight - 3;

         r.x := x;
         r.y := y2;
         r.w := width;
         r.h := oxConsole.IbHeight - 2;

         wnd.SetColor(oxConsole.Colors.InputStatus.ToColor4f());

         uiDraw.Box(r);

         t[0] := vmvZero3f;

         x := wnd.RPosition.x + width;

         t[2].Assign(x, y2, 0);
         t[1].Assign(x + w, y + w, 0);
         t[0].Assign(x, y, 0);

         oxRenderingUtilities.Triangle(t[0], t[1], t[2]);
      end;

      {text}
      f := oxConsole.Font;
      if(f = nil) then
         f := oxui.GetDefaultFont();

      f.Start();
      wnd.SetColorBlended(225, 255, 255, 255);

      if(oxConsole.DrawInputStatus) and (oxConsole.InputStatus <> '') then begin
         f.WriteCentered(oxConsole.InputStatus, r);
      end;

      if(oxConsole.StatusHeight > 0) then
         f.Write(wnd.RPosition.x + 2, wnd.RPosition.y -  2 - (data.fh), appInfo.GetVersionString());

      if(oxConsole.Console.Contents.n > 0) then begin
         start := oxConsole.Console.Contents.n - data.MaxLines;
         if(start < 0) then
            start := 0;

         repEnd := oxConsole.Console.Contents.n - 1;

         for i := start to repEnd do begin
            cPos := i - start;

            pStr := oxConsole.Console.Contents.List[i].txt;
            if(pStr <> '') then begin
               {set the appropriate color}
               wnd.SetColorBlended(oxConsole.Console.Contents.List[i].Color);

               {make the string shorter if it is too long to be viewed entirely in the console}
               clipSize := Length(pStr);

               if(clipSize > data.MaxVisibleChars) then
                  SetLength(pStr, data.MaxVisibleChars);

               {write the string}
               if(oxConsole.WriteTime) then
                  f.Write(2, (wnd.RPosition.y - data.OutputStartY) - (data.fh * cPos),
                     TimeToStr(oxConsole.Console.Contents.List[i].Time) + ' ' + pStr)
               else
                  f.Write(2, (wnd.RPosition.y - data.OutputStartY) - (data.fh * cPos), pStr);

               {return the string size back to normal}
               SetLength(pStr, clipSize);
            end;
         end;
      end;

      oxf.Stop();
   end;
end;

{ CONSOLE WINDOW HANDLER }
function oxConsoleWndHandler(wnd: uiTControl; const event: appTEvent): longint;
var
   key: appTKey;

begin
   Result := -1;

   {window events}
   if(event.hID = uievhpWINDOW) then begin
      {render the console}
      if(uiTWindowEvents(event.evID) = uiWINDOW_RENDER_SURFACE) then
         consoleRender(uiTWindow(wnd))
      {console window resized}
      else if(uiTWindowEvents(event.evID) = uiWINDOW_RESIZE) then
         consoleReconfigure()
      else if(uiTWindowEvents(event.evID) = uiWINDOW_ACTIVATE) then
         oxConsole.wdgInput.Select();
   {handle [ESC, TILDE] keys}
   end else if(event.hID = @appKeyEvents.evh) then begin
      key := appPKeyEvent(event.GetData())^.Key;

      if(key.Equal(kcESC)) or (key.Equal(kcTILDE)) then begin
         if(key.Released()) then
            oxConsole.DeActivate();

         exit(0);
      end;
   end;
end;

{ GLOBAL KEY HANDLER }

procedure gkHandler(wnd: oxTWindow);
begin
   if(wnd <> nil) then begin
      if(not oxConsole.Console.Active) then
         oxConsole.Activate()
      else
         oxConsole.DeActivate();
   end;
end;

CONST
   congkHandler: oxTGlobalKeyHandler = (
      Key: (
         Code: kcTILDE;
         State: 0;
      );
      Pressed: nil;
      Released: @gkHandler;
      Name: 'oxConsole'
   );

VAR
   congkHandlerAlt: oxTGlobalKeyHandler;

{ WIDGET CONTROL }
function consoleWidgetControl(wdg: uiTWidget; what: longword): longint;
var
   s: StdString;

begin
   Result := -1;

   if(wdg = WDGID_CONSOLE_IB) then begin
      if(what = wdghINPUTBOX_CONFIRM_PRESSED) then
         Result := 0
      else if(what = wdghINPUTBOX_CONFIRM) then begin
         s := oxConsole.wdgInput.GetText();

         oxConsole.Console.ProcessEntry(s);
         Result := 0;
      end;
   end;
end;

{ CONSOLE ACTIONS }

function oxconInit(): boolean;
var
   ParentWindow: uiTWindow;

begin
   Result := false;

   oxui.GetNilDefault(oxConsole.Font);

   if(oxConsole.DoLog) then
       log.i('oxCon > Initializing...');

   {determine console window parent}
   if(oxConsole.ParentWindow = nil) then
      ParentWindow := oxWindow.Current
   else
      ParentWindow := oxConsole.ParentWindow;

   {create window}
   uiWindow.Create.Frame := uiwFRAME_STYLE_NONE;
   uiWindow.Create.ZIndex := oxConsole.windowZ;

   uiWindow.Create.Instance := oxTConsoleWindow;
   oxConsole.Window := uiWindow.MakeChild(ParentWindow, 'oxConsole',
      oxPoint(0, ParentWindow.Dimensions.h - 1), oxNullDimensions).
      SetID(oxConsole.WindowId);

   ParentWindow.AddListener(@parentResize);

   if(oxConsole.Window <> nil) then begin
      Include(oxConsole.Window.Properties, uiwndpNO_ESCAPE_KEY);
      oxConsole.Window.Properties.Immovable();
      oxConsole.Window.wHandler := @oxConsoleWndHandler;

      {set background to none and close the window}
      oxConsole.Window.SetBackgroundType(uiwBACKGROUND_NONE);
      oxConsole.Window.Close();

      {add console input box}
      uiWidget.SetTargetCP(uiTWidgetControlProc(@consoleWidgetControl));

      uiWidget.Create.Instance := oxTConsoleInputBox;
      oxConsole.wdgInput := wdgTInputBox(wdgInputBox.Add('', oxPoint(oxConsole.GetIBLeftOffset() + 1, oxConsole.ibHeight),
         oxDimensions(oxConsole.Window.Dimensions.w, oxConsole.ibHeight)).SetID(WDGID_CONSOLE_IB));

      oxConsole.wdgInput.CustomDrawnContainer := true;
      oxConsole.wdgInput.InputCursorType := wdgINPUT_BOX_CURSOR_BLOCK;
      oxConsole.wdgInput.Skin := @consoleInputSkin;

      uiWidget.ClearTarget();
      adjustSize();

      {prepare console for input and display}
      oxConsole.Console.Select();
      consoleReconfigure();
      oxconWriteAbout();

      { done }
      if(oxConsole.DoLog) then
         log.i('oxCon > Initialized');

      Result := true;
   end;
end;


{ CONSOLE HANDLER }
function oxconAction(a: longint): longint;
var
   rslt: boolean = true;

begin
   Result := CON_RESULT_IGNORE;

   case a of
      CON_ACTION_ACTIVATE: begin
         if(oxConsole.Window <> nil) then begin
            oxConsole.Window.Open();
            {focus input when open}
            oxConsole.wdgInput.Select();
         end else
            rslt := false;
      end;

      CON_ACTION_DEACTIVATE: begin
         if(oxConsole.Window <> nil) then
            oxConsole.Window.Close();
      end;

      CON_ACTION_INITIALIZE:
         rslt := oxconInit();

      CON_ACTION_PROCESS_ENTRY_END: begin
         oxConsole.wdgInput.Clear();

         {return history index to current entry}
         historyIndex := 0;
         {some commands change the ui focus, so return it to the console input}
         oxConsole.wdgInput.Select()
      end else
        exit;
   end;

   case rslt of
      false: Result := CON_RESULT_FALSE;
      true:  Result := CON_RESULT_TRUE;
   end;
end;

{ INITIALIZATION / DEINITIALIZATION }

procedure Initialize();
begin
   console.Init(oxConsole.console);
   oxConsole.Console.Name := 'console';

   {setup the console handler}
   oxConsole.Console.ActionHandler := @oxconAction;

   {initialize the console}
   oxConsole.Console.Initialize();

   {add the command handler}
   oxConsole.Console.AddHandler(conHandler, conTCommandNotifyProc(@oxconCommandNotify), conCommands);

   {hook the console global key handler}
   oxGlobalKeys.Hook(congkHandler);
   congkHandlerAlt := congkHandler;
   {$IFNDEF OX_LIBRARY}
   congkHandlerAlt.Key.Assign(kcTILDE, kmCONTROL);
   {$ELSE}
   congkHandler.Key.Assign(kcTILDE, kmSHIFT);
   congkHandlerAlt.Key.Assign(kcTILDE, kmCONTROL or kmSHIFT);
   {$ENDIF}
   oxGlobalKeys.Hook(congkHandlerAlt);

   {prepare skin for input widget}
   uiSkin.SetupWidget(oxui.DefaultSkin, consoleInputSkin, wdgInputSkinDescriptor);
   consoleInputSkin.SetColor(wdgscINPUT_TEXT, oxConsole.Colors.InputText);
   consoleInputSkin.SetColor(wdgscINPUT_CURSOR, oxConsole.Colors.InputCursor);

   dvarf.ReadText(dvgConsoleHistory, appPath.Configuration.path + 'console.history');
end;

procedure DeInitialize();
begin
   dvarf.WriteText(dvgConsoleHistory, appPath.Configuration.path + 'console.history');

   oxConsole.Console.DeInitialize();
   oxConsole.wdgInput := nil;
   oxConsole.ParentWindow := nil;
   oxConsole.Font := nil;
   oxConsole.Window := nil;

   uiSkin.DisposeWidget(consoleInputSkin);
end;

{ DVAR HANDLER }

procedure dvSaveHandler(var context: TDVarNotificationContext);
begin
   if(context.What = DVAR_NOTIFICATION_WRITE) then begin
      context.Result := 0;

      dvarPFileData(context.f)^.Write(context.Parent, dvHistory, oxConsole.Console.History.Entries.List, oxConsole.Console.History.Entries.n);
   end;
end;

procedure dvHistoryNotify(var {%H-}context: TDVarNotificationContext);
begin
   if(not StringUtils.IsWhitespace(currentHistory)) then
      oxConsole.Console.AddHistory(currentHistory);
end;

procedure uiInitialize();
begin
   oxConsole.SetFont(oxui.GetDefaultFont());
end;

VAR
   initRoutines,
   uiInitRoutines: oxTRunRoutine;

INITIALIZATION
   ox.Init.Add(initRoutines, 'console', @Initialize, @DeInitialize);
   oxui.InitializationProcs.iAdd(uiInitRoutines, 'console', @uiInitialize);

   oxConsole.Height        := 0.6;
   oxConsole.IbHeight      := 20;
   oxConsole.StatusHeight  := 0;
   oxConsole.WindowZ       := 1000;

   oxConsole.Colors.Background.Assign(32, 32, 32, 232);
   oxConsole.Colors.StatusBackground.Assign(21, 21, 64, 255);
   oxConsole.Colors.InputBackground.Assign(5, 5, 13, 232);
   oxConsole.Colors.InputText.Assign(255, 255, 255, 255);
   oxConsole.Colors.InputCursor.Assign(232, 232, 255, 255);
   oxConsole.Colors.InputStatus.Assign(63, 63, 127, 255);
   oxConsole.Console.Colors.Statement.Assign(192, 192, 255, 255);

   oxConsole.DrawInputStatus := true;
   oxConsole.InputStatus := 'console';
   oxConsole.WriteTime := true;

   oxConsole.WindowId := uiControl.GetID('ox.console');
   WDGID_CONSOLE_IB := uiControl.GetID('ox.console.inputbox');

   {console dvar}
   dvar.Init(dvgConsoleHistory);
   dvgConsoleHistory.Name := 'console';
   dvgConsoleHistory.Add(dvHistory, 'history', dtcSTRING, @currentHistory);

   ox.dvar.Add('console', dvgConsole);
   dvgConsole.Add(dvWriteTime, 'write_time', dtcBOOL, @oxConsole.WriteTime);
   dvgConsole.Add(dvFullscreen, 'fullscreen', dtcBOOL, @oxConsole.Fullscreen);
   dvgConsole.Add(dvHeight, 'height', dtcSINGLE, @oxConsole.Height);

   dvHistory.pNotify := @dvHistoryNotify;

   dvgConsoleHistory.pNotify := @dvSaveHandler;
END.
