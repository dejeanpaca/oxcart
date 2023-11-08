{
   uTVideo, advanced text video manipulation and operations
   Copyright (C) 2006. Dejan Boras
}

{$MODE OBJFPC}{$H+}{$I-}{$MODESWITCH TYPEHELPERS}{$MODESWITCH ADVANCEDRECORDS}
UNIT uTVideo;

{Note that characters CR(carriage return), LF(Line Feed) in these combinations:
 CRLF, CR or LF represent a new line(enter) start. LFCR may cause errors.}

INTERFACE

   USES uStd, uLog, Video, StringUtils;

CONST
   {error constants}
   tveINIT_FAIL                     = $100;{initialization failed}
   tveDEINIT_FAIL                   = $101;{deinitialization failed}
   tveINIT                          = $102;{already initialized}
   tveNOT_INIT                      = $103;{not initialized}
   tveMODE_SET_FAIL                 = $104;{if mode set failed}
   tveMODE_RETR_FAIL                = $105;{in case mode retrieval failed}
   tveUNSUPPORTED                   = $106;{if the operation is not supported by the driver}
   tveINADEQUATE                    = $107;{in case the driver does not meet the required criteria}
   tveOUT_OF_BOUNDS                 = $108;{if there was an attempt to plot out of bounds}
   tveNO_BUFFER                     = $109;{if there is no buffer or the buffer pointer is nil}
   tveUNSUPPORTED_ENDIAN            = $10A;{unsupported endian}
   tveINVALID_DIMENSIONS            = $10B;{invalid dimensions}
   tveNOT_TV_IMAGE                  = $10C;{object is not a tv image}
   tveUNSUPPORTED_VERSION           = $10D;{unsupported version}
   tveCORRUPTED                     = $10E;{corrupted}

   {styles}
   tvcSINGLE_LINE                   = $00;
   tvcDOUBLE_LINE                   = $01;
   tvcCHARACTER                     = $02;

   tvcDLEFT_RIGHT                   = $00;
   tvcDRIGHT_LEFT                   = $01;
   tvcDUP_DOWN                      = $02;
   tvcDDOWN_UP                      = $03;

   {some standard text video mode constants; mostly used and mostly working}
   {monochrome modes | rarely used}
   tvcM80x25F: TVideoMode           = (col: 80; row: 25; color: false);
   {color modes}
   tvcM40x25T: TVideoMode           = (col: 40; row: 25; color: true);
   tvcM80x25T: TVideoMode           = (col: 80; row: 25; color: true);
   tvcM80x30T: TVideoMode           = (col: 80; row: 30; color: true);
   tvcM80x33T: TVideoMode           = (col: 80; row: 33; color: true);
   tvcM80x43T: TVideoMode           = (col: 80; row: 43; color: true);
   tvcM80x50T: TVideoMode           = (col: 80; row: 50; color: true);

VAR
   tvSettings: record
      {perform operations that are not supported either by the driver or the current conditions }
      ForceUnsupportedOps,
      {log certain information}
      Log,
      {determines whether the unit should change modes on request}
      ChangeModes,

      {consider tab characters as actual tab characters which will be replaced with spaces on the screen}
      Tab: boolean;
      {the tab size}
      TabSize: byte;

      {clip output at screen end, otherwise the output will start at a new line}
      Clip,
      {do not write spaces}
      SpaceTransparent,
      {write transparent text}
      WriteTransparent,

      {start new line at screen x coordinate start x = 0}
      NewLineAt0,
      {the CRLF, CR, LF will make a new line when writting to the screen}
      EnterNewLine,
      {clear part of the screen left after moving}
      ClearAfterMove,
      {moves the screen when writing reaches it's end}
      MoveScreenWhenReachedEnd,
      {if true the cursor respects the limitiation dimensions}
      LDCursor: boolean;
      {the direction in which to write}
      WriteDirection,
      {the direction in which to make new lines. For updown or downup writing directions you cannot have
      updown or downup new line directions, the same goes for leftright and rightleft diRections}
      NewLineDirection,
      {how many spaces will be moved for a new line}
      LineSpacing: longint;
   end;

TYPE
   TVideoAttribute = type byte;
   TVideoColor = type byte;

   {the capabilities of the driver}
   tvPDriverCapabilities = ^tvTDriverCapabilities;

   { tvTDriverCapabilities }

   tvTDriverCapabilities = record
      Underline,
      Blink,
      Color,
      ChangeFont,
      ChangeMode,
      ChangeCursor: boolean;

      procedure GetDriverCapabilities();
   end;

   {attributes}
   tvTAttributes = record
      Color,
      BkColor,
      ClearColor,
      ClearBkColor: byte;

      ClearChar,
      RectChar,
      FillChar: char;

      Underline,
      Blink,
      ClearBlink,
      FillBlink,
      RectFill: boolean;

      RectStyle: byte;
   end;

   {the cursor}
   tvTCursor = record
      x,
      y: longint;
   end;

   { tvTDimensions }

   tvTDimensions = record
      x1,
      y1,
      x2,
      y2: longint;

      {limit to inside this rect}
      procedure Limit(var lx1, ly1, lx2, ly2: longint);
      procedure Assign(newX1, newY1, newX2, newY2: longint);
      procedure Assign(mode: TVideoMode);

      procedure Offset(var x, y: longint); inline;

      function Inside(px1, py1: loopint): boolean; inline;
      function Covers(px1, py1, px2, py2: loopint): boolean; inline;
   end;

   { tvTPhysicalDimensions }

   tvTPhysicalDimensions = record
      x,
      y: longint;

      procedure Limit(var lx1, ly1, lx2, ly2: longint);
      procedure Assign(newX, newY: longint);
      procedure Assign(mode: TVideoMode);
   end;

   {first eleven are single line drawing character codes, the second eleven are
    double line drawing character codes, and the last two are ds line}

   {the line drawing constants need to be used to get an effect on these}
   tvTLineDrawingCharacterSet = array[0..23] of char;

CONST
   tvDefaultAttributes: tvTAttributes = (
      Color:         15;
      BkColor:       0;
      ClearColor:    15;

      ClearBkColor:  0;
      ClearChar:     #32;
      RectChar:      #178;
      FillChar:      #32;

      Underline:     false;
      Blink:         false;
      ClearBlink:    false;
      FillBlink:     false;
      RectFill:      false;
      RectStyle:     tvcSINGLE_LINE
   );

   tvDefaultCursor: tvTCursor       = (x: 0; y:0);
   {line drawing constants}
   {single line drawing constants}
   tvcldSUpperLeftCorner             = $00;
   tvcldSUpperRightCorner            = $01;
   tvcldSLowerLeftCorner             = $02;
   tvcldSLowerRightCorner            = $03;
   tvcldSLRCenter                    = $04;
   tvcldSUDCenter                    = $05;
   tvcldSLRCenterDown                = $06;
   tvcldSLRCenterUp                  = $07;
   tvcldSUDCenterRight               = $08;
   tvcldSUDCenterLeft                = $09;
   tvcldSCross                       = $0A;
   {double line drawing constant | needs to be added to the single line
   drawing constant to get a double line}
   tvcldD                            = $0B;
   {double line drawing constants}
   tvcldDUpperLeftCorner             = $00 + tvcLDD;
   tvcldDUpperRightCorner            = $01 + tvcLDD;
   tvcldDLowerLeftCorner             = $02 + tvcLDD;
   tvcldDLowerRightCorner            = $03 + tvcLDD;
   tvcldDLRCenter                    = $04 + tvcLDD;
   tvcldDUDCenter                    = $05 + tvcLDD;
   tvcldDLRCenterDown                = $06 + tvcLDD;
   tvcldDLRCenterUp                  = $07 + tvcLDD;
   tvcldDUDCenterRight               = $08 + tvcLDD;
   tvcldDUDCenterLeft                = $09 + tvcLDD;
   tvcldDCross                       = $0A;
   {special drawing characters | these two are mostly unavailable + tvcLDD on
   the windows platform}
   tvcldDUDCenterSRight              = $16;
   tvcldDUDCenterSLeft               = $17;

   {multiple line drawing character sets | all in hex}
   tvldcS0: tvTLineDrawingCharacterSet = (
      {singleline}  #$DA, #$BF, #$C0, #$D9, #$C4, #$B3, #$C2, #$C1, #$C3, #$B4, #$C5,
      {double line} #$C9, #$BB, #$C8, #$BC, #$CD, #$BA, #$CB, #$CA, #$CC, #$B9, #$CE,
      {special LD}  #$C7, #$C6);

TYPE

   { TVideoModeHelper }

   TVideoModeHelper = record helper for TVideoMode
      function ToString(): string;
   end;

   TVideoCellHelper = type helper for TVideoCell
      procedure Break(out ch: char; out color: byte; out bkcolor: byte; out blink: boolean);
      procedure Break(out ch: char; out color: byte; out bkcolor: byte);
      procedure Break(out ch: char; out color: byte);
      procedure Break(out ch: char);

      function GetChar(): char;
      function GetColor(): byte;
      function GetBkColor(): byte;
      function GetBlink(): boolean;
   end;

   TVideoAttributeHelper = type helper for TVideoAttribute
      {break attribute}
      procedure Break(out color: byte; out bkcolor: byte; out blink: boolean);
      procedure Break(out color: byte; out bkcolor: byte);
      procedure Break(out color: byte);
   end;

   TVideoColorHelper = type helper for TVideoColor
      {return a high color; ignore if already high color}
      function High(): TVideoColor;
      {return a low color; ignore if already low color}
      function Low(): TVideoColor;

      {reduces the shade of a color}
      function ShadeDown(): TVideoColor;
      {increases the shade of a color}
      function ShadeUp(): TVideoColor;
      {inverts a color}
      function Invert(): TVideoColor;
   end;

   { TVideoGlobal }

   TVideoGlobal = record
      Initialized: boolean;

      Error,
      ErrorDetail: longint;

      DC: tvTDriverCapabilities;
      ModeCount: longint; {the number of video modes}
      Modes: array of TVideoMode; {stores all the video modes}
      Mode: TVideoMode;

      {raise an error condition}
      procedure eRaise(err: longint);
      {reset the error state}
      procedure ErrorReset();

      procedure InitDefaults();

      procedure Initialize(rvm: TVideoMode);
      procedure Initialize();
      procedure Deinitialize();

      {mode set}
      procedure SetMode(tvm: TVideoMode);
      procedure SetMode(col, row: word; color: boolean);
      {set buffer for the current mode}
      procedure SetModeBuffer();
      {current mode get | places current mode data into tvMode}
      procedure GetCurMode();
      {obtaines the mode data into tvGlobal.Modes | does not get any modes if
      insufficient memory for all modes}
      procedure GetModes();
      {disposes the mode data}
      procedure DisposeModes();

      {DRIVER CAPABILITIES}

      {LOGGING}
      procedure LogDC();
      procedure LogMode();
      procedure LogModes();
      procedure LogAttributes();
   end;

   { TVideoWindow }

   TVideoWindow = record
      Mode: TVideoMode;             {the current mode}
      Attr: tvTAttributes;          {the current attributes}
      Buf: PVideoBuf;               {the current buffer}
      Cursor: tvTCursor;            {the current cursor}
      Dimensions: tvTPhysicalDimensions; {the current physical dimensions}
      Limits: tvTDimensions;        {limitation dimensions | aka window}
      BufSize: Word;               {the size of the current buffer}
      LDCharSet: tvTLineDrawingCharacterSet;

      procedure Initialize();

      function MakeAttribute(clr, bkclr: byte): TVideoAttribute;
      function MakeAttribute(clr: byte): TVideoAttribute;

      function MakeCell(ch: char; clr, bkclr: byte): TVideoCell;
      function MakeCell(ch: char): TVideoCell;

      {attribute setting procedures}

      {sets foreground color}
      procedure SetColor(clr: byte);
      {sets background color}
      procedure SetBkColor(bkclr: byte);
      {set foreground and background color}
      procedure SetColors(clr, bkclr: byte);
      {sets blink attribute state}
      procedure SetBlink(blnk: boolean);
      {sets underline attribute state}
      procedure SetUnderline(underline: boolean);
      {toggles the blink attribute state from true to false and vice versa}
      procedure ToggleBlink();
      {toggles the underline attribute state from true to false and vice versa}
      procedure ToggleUnderline();

      {fill character}
      procedure SetFillChar(fc: char);
      function GetFillChar(): char;
      {rectangle fill boolean}
      procedure SetRectFill(rf: boolean);
      function GetRectFill(): boolean;
      {rectangle style}
      procedure SetRectStyle(style: byte);
      function GetRectStyle(): byte;
      {rectangle character}
      procedure SetRectChar(rc: char);
      function GetRectChar(): char;

      {clear color}
      procedure SetClearColor(clr: byte);
      function GetClearColor(): byte;
      {clear background color}
      procedure SetClearBkColor(bkclr: byte);
      function GetClearBkColor(): byte;
      {clear character}
      procedure SetClearChar(ch: char);
      function GetClearChar(): char;
      {clear blink}
      procedure SetClearBlink(blink: boolean);
      function GetClearBlink(): boolean;

      {clears the entire screen}
      procedure ClearScreen();
      {clears the area set by limitation dimensions}
      procedure Clear();

      procedure Update(force: boolean = false);

      {plotting functions | various overloaded versions to ensure useability in any occasion}
      procedure Plot(x, y: longint; ch: char);
      procedure Plot(x: longint; ch: char);
      procedure Plot(ch: char);

      {writting functions(directional)}
      procedure Write(px, py: longint; const str: string);
      procedure Write(const str: string);
      procedure Writeln(px, py: longint; const str: string);
      procedure Writeln(const str: string);

      {move cursor}
      procedure GotoXY(x, y: longint);
      procedure GotoX(x: longint);
      procedure GotoY(y: longint);
      procedure GotoXY();

      {get cursor position}
      {cursor x position}
      function GetCursorX(): longint;
      {cursor y position}
      function GetCursorY(): longint;

      {Rect drawing}
      procedure DrawRect(px1, py1, px2, py2: longint);
      procedure DrawRect();

      {BOXES}
      {box drawing}
      procedure DrawBox(px1, py1, px2, py2: longint);
      procedure DrawBox();

      {LINES}
      {draw a horisontal line}
      procedure HLine(px1, py1, px2: longint; ch: char);
      {draw a vertical line}
      procedure VLine(px1, py1, py2: longint; ch: char);

      {same as the two above, except these accept line drawing indexes}
      procedure HLine(px1, py1, px2: longint; ldchar: byte);
      procedure VLine(px1, py1, py2: longint; ldchar: byte);

      {IMAGES}
      {get image dimensions}
      procedure GetImageDim(var w, h: word; img: pointer);
      function GetImageWidth(img: pointer): word;
      function GetImageHeigth(img: pointer): word;

      {get an image from the given coordinates}
      procedure GetImage(px1, py1, px2, py2: longint; var img: pointer);
      {get an image of the entire screen}
      procedure GetScreen(var img: pointer);
      {get an image of the part of the screen as indicated by the limitation dimensions}
      procedure GetScreenLtd(var img: pointer);

      {set a image to specified coordinates}
      procedure PlotImage(px1, py1: longint; img: pointer);
      procedure PlotImage(px1, py1: longint; wid, hgt: word; img: pointer);
      {set image to the entire screen}
      procedure PlotScreen(img: pointer);
      procedure PlotScreenLtd(img: pointer);

      {disposing of an image}
      procedure DisposeImage(var img: pointer);

      {MOVING}
      {move region up, down, left and right}
      procedure MoveUp(px1, py1, px2, py2: longint; n: word);
      procedure MoveDown(px1, py1, px2, py2: longint; n: word);
      procedure MoveLeft(px1, py1, px2, py2: longint; n: word);
      procedure MoveRight(px1, py1, px2, py2: longint; n: word);

      {inserts a line at a specific position}
      procedure InsertLine(y: longint);

      {moves a line left or right}
      procedure MoveRowLeft(y: longint; n: word);
      procedure MoveRowRight(y: longint; n: word);
      procedure MoveColUp(x: longint; n: word);
      procedure MoveColDown(x: longint; n: word);

      {CLIPPING}
      {clip a image to new width and height}
      procedure ClipImage(wid, hgt: word; var img: pointer);
      {clip a buffer to new width and height}
      procedure ClipBuf(wid, hgt: word; var pbuf: PVideoBuf; var pdim: tvTPhysicalDimensions);
   end;

VAR
   {these are global}
   tvGlobal: TVideoGlobal;

   {pointers to current elements}
   tvCurrent: TVideoWindow;

{ATTRIBUTE AND CELL ROUTINES}

{create an attribute attributes}
function tvMakeAttribute(clr, bkclr: byte; blink: boolean): TVideoAttribute;

{cells}
function tvMakeCell(ch: char; clr, bkclr: byte; blink: boolean): TVideoCell;
function tvMakeCell(ch: char; attr: byte): TVideoCell;

IMPLEMENTATION

{ TVideoModeHelper }

function TVideoModeHelper.ToString(): string;
begin
   if(Self.Color) then
      Result := sf(Col) + 'x' + sf(Row)
   else
      Result := sf(Col) + 'x' + sf(Row) + ' monochrome';
end;

procedure TVideoGlobal.eRaise(err: longint);
begin
   tvGlobal.Error := err;
end;

procedure TVideoGlobal.ErrorReset();
begin
   tvGlobal.Error       := eNONE;
   tvGlobal.ErrorDetail := eNONE;
end;

procedure TVideoGlobal.SetMode(tvm: TVideoMode);
begin
   ErrorReset();

   if(not tvSettings.ChangeModes) and (not tvSettings.ForceUnsupportedOps) then begin
      log.e('tv > Tried to set unsupported mode: ' + tvm.ToString());
      eRaise(tveUNSUPPORTED);
      exit;
   end;

   if(not DC.ChangeMode) then
      exit;

   if(not SetVideoMode(tvm)) then begin
      log.e('tv > Failed to set mode: ' + tvm.ToString());
      eRaise(tveMODE_SET_FAIL);
      exit;
   end;

   {some interface management}
   GetCurMode();
   SetModeBuffer();
end;

procedure TVideoGlobal.SetMode(col, row: word; color: boolean);
var
   tvm: TVideoMode;

begin
   tvm.Col     := col;
   tvm.Row     := row;
   tvm.Color   := color;

   SetMode(tvm);
end;

procedure TVideoGlobal.SetModeBuffer();
begin
   tvCurrent.Buf := VideoBuf;
   tvCurrent.BufSize := VideoBufSize;

   tvCurrent.Dimensions.Assign(tvCurrent.Mode);
   tvCurrent.Limits.Assign(tvCurrent.Mode);

   tvCurrent.GotoXY();
end;

procedure TVideoGlobal.GetCurMode();
begin
   video.GetVideoMode(tvCurrent.Mode);
end;

procedure TVideoGlobal.GetModes();
var
   count: word;

begin
   ErrorReset();

   {get space for the modes and check for errors}
   tvGlobal.ModeCount := GetVideoModeCount;

   if(tvGlobal.ModeCount = 1) then
      tvSettings.ChangeModes := false;

   SetLength(tvGlobal.Modes, tvGlobal.ModeCount);

   if(high(tvGlobal.Modes) < tvGlobal.ModeCount - 1) then begin
      DisposeModes();
      eRaise(eNO_MEMORY);
      exit;
   end;

   {now get the modes data}
   for count := 0 to tvGlobal.ModeCount - 1 do begin
      if(not GetVideoModeData(count, tvGlobal.Modes[count])) then
         eRaise(tveMODE_RETR_FAIL);
   end;
end;

procedure TVideoGlobal.DisposeModes();
begin
   tvGlobal.Error := 0;
   SetLength(tvGlobal.Modes, 0);
end;

procedure TVideoGlobal.LogDC();
begin
   if (tvSettings.Log) then begin
      log.Collapsed('tv > Driver Capabilities');
      log.i('Underline: ' + sf(tvGlobal.DC.underline));
      log.i('Blink: ' + sf(tvGlobal.DC.blink));
      log.i('Color: ' + sf(tvGlobal.DC.color));
      log.i('Change Font: ' + sf(tvGlobal.DC.ChangeFont));
      log.i('ChangeMode: ' + sf(tvGlobal.DC.ChangeMode));
      log.i('Change Cursor: ' + sf(tvGlobal.DC.ChangeCursor));
      log.Leave();
   end;
end;

procedure TVideoGlobal.LogMode();
begin
   if(tvSettings.Log) then
      log.i('tv > Current mode = Col: ' + sf(tvCurrent.Mode.Col) + ' | Row: ' +
         sf(tvCurrent.Mode.Row) + ' | Color: ' + sf(tvCurrent.Mode.Color));
end;


procedure TVideoGlobal.LogModes();
var
   count: word;

begin
   if(tvSettings.Log) and (tvGlobal.ModeCount > 0) then begin
      log.Collapsed('tv > Modes');

      for count := 0 to (tvGlobal.ModeCount - 1) do begin
         log.i(sf(count) + ': ' + tvGlobal.Modes[count].ToString());
      end;

      log.Leave();
   end;
end;

procedure TVideoGlobal.LogAttributes();
begin
   if(tvSettings.Log) then begin
      log.i('tv Attributes > Color: ' + sf(tvCurrent.Attr.Color) +
         ' | Background Color: ' + sf(tvCurrent.Attr.BkColor) +
         ' | Blink: ' + sf(tvCurrent.Attr.Blink) +
         ' | Underline: ' + sf(tvCurrent.Attr.Underline));
   end;
end;

{Attributes}

procedure TVideoWindow.SetColor(clr: byte);
begin
   Attr.Color := clr;
end;

procedure TVideoWindow.SetBkColor(bkclr: byte);
begin
   Attr.BkColor := bkclr;
end;

procedure TVideoWindow.SetColors(clr, bkclr: byte);
begin
   Attr.Color     := clr;
   Attr.BkColor   := bkclr;
end;

procedure TVideoWindow.SetBlink(blnk: boolean);
begin
   Attr.Blink := blnk;
end;

procedure TVideoWindow.SetUnderline(underline: boolean);
begin
   Attr.Underline := underline;
end;

procedure TVideoWindow.ToggleBlink();
begin
   Attr.Blink := Attr.Blink xor true;
end;

procedure TVideoWindow.ToggleUnderline();
begin
   Attr.Underline := Attr.Underline xor true;
end;

{FILL CHARACTER}

procedure TVideoWindow.SetFillChar(fc: char);
begin
   Attr.FillChar := fc;
end;

function TVideoWindow.GetFillChar(): char;
begin
   Result := Attr.FillChar;
end;

procedure TVideoWindow.SetRectFill(rf: boolean);
begin
   Attr.RectFill := rf;
end;

function TVideoWindow.GetRectFill(): boolean;
begin
   Result := Attr.RectFill
end;

procedure TVideoWindow.SetRectStyle(style: byte);
begin
   Attr.RectStyle := style;
end;

function TVideoWindow.GetRectStyle(): byte;
begin
   Result := Attr.RectStyle;
end;

procedure TVideoWindow.SetRectChar(rc: char);
begin
   Attr.RectChar := rc;
end;

function TVideoWindow.GetRectChar(): char;
begin
   Result := Attr.RectChar
end;

function TVideoColorHelper.High(): TVideoColor;
begin
   if Self < 8 then
      Result := Self + 8
   else
      Result := Self;
end;

function TVideoColorHelper.Low(): TVideoColor;
begin
   if Self > 7 then
      Result := self - 8
   else
      Result := Self;
end;

function TVideoColorHelper.ShadeDown(): TVideoColor;
begin
   if Self > 7 then
      Result := Self - 8
   else
      Result := 0;
end;

function TVideoColorHelper.ShadeUp(): TVideoColor;
begin
   if Self < 8 then
      Result := Self + 8
   else
      Result := 15;
end;

function TVideoColorHelper.Invert(): TVideoColor;
begin
   Result := Self xor $0F;
end;

{ATTRIBUTE MANAGEMENT}
function tvMakeAttribute(clr, bkclr: byte; blink: boolean): TVideoAttribute;
begin
   {make the atrribute}
   {$ifdef ENDIAN_LITTLE}
      Result := clr + (bkclr shl 4);
   {$else}
      Result := bkclr + (clr shl 4);
   {$endif}

   if(blink) and (tvGlobal.DC.Blink) then
      Result := Result or video.Blink;
end;

procedure TVideoWindow.Initialize();
begin
   LDCharSet := tvldcS0;
end;

function TVideoWindow.MakeAttribute(clr, bkclr: byte): TVideoAttribute;
begin
   Result := tvMakeAttribute(clr, bkclr, Attr.blink);
end;

function TVideoWindow.MakeAttribute(clr: byte): TVideoAttribute;
begin
   Result := tvMakeAttribute(clr, Attr.bkcolor, Attr.blink);
end;

function tvMakeCell(ch: char; clr, bkclr: byte; blink: boolean): TVideoCell;
var
   {the color and blink attributes}
   attr: byte;
   cell: TVideoCell;

begin
   {$ifdef ENDIAN_LITTLE}
      attr := clr + (bkclr shl 4);

      if(blink) and (tvGlobal.DC.Blink) then
         attr := attr or video.Blink;

      cell := byte(ch) + (attr shl 8);
   {$else}
      attr := bkclr + (clr shl 4);

      if(blink) and (tvGlobal.DC.Blink) then
         attr := attr or video.Blink;

      cell := attr + (byte(ch) shl 8);
   {$endif}

   Result := cell;
end;

function tvMakeCell(ch: char; attr: byte): TVideoCell; inline;
begin
   {$ifdef ENDIAN_LITTLE}
      Result := byte(ch) + (attr shl 8);
   {$else}
      Result := attr + (byte(ch) shl 8);
   {$endif}
end;

function TVideoWindow.MakeCell(ch: char; clr, bkclr: byte): TVideoCell;
begin
   Result := tvMakeCell(ch, clr, bkclr, Attr.Blink);
end;

function TVideoWindow.MakeCell(ch: char): TVideoCell;
begin
   Result := tvMakeCell(ch, Attr.Color, Attr.BkColor, Attr.Blink);
end;

{ATTR BREAKING}
procedure TVideoAttributeHelper.Break(out color: byte; out bkcolor: byte; out blink: boolean);
begin
   {$ifdef ENDIAN_LITTLE}
   color := (Self shl 4) shr 4;
   bkcolor := (Self shr 4) shl 4;
   {$else}
   color := (Self shr 4) shl 4;
   bkcolor := (Self shl 4) shr 4;
   {$endif}

   blink := Self and video.Blink > 0;
end;

procedure TVideoAttributeHelper.Break(out color: byte; out bkcolor: byte);
var
   blink: boolean;

begin
   Self.Break(color, bkcolor, blink);
end;

procedure TVideoAttributeHelper.Break(out color: byte);
var
   blink: boolean;
   bkcolor: byte;

begin
   Self.Break(color, bkcolor, blink);
end;

{ TVideoGlobal }

procedure TVideoGlobal.InitDefaults();
begin
   GetCurMode();

   tvCurrent.Attr  := tvDefaultAttributes;
   tvCurrent.Cursor := tvDefaultCursor;

   SetModeBuffer();
end;

procedure TVideoGlobal.Initialize(rvm: TVideoMode);
begin
   Initialize();

   if(Error = 0) then
      {set mode}
      SetMode(rvm)
end;

procedure TVideoGlobal.Initialize();
begin
   ErrorReset();

   if(not Initialized) then begin
      {we can't have output into the terminal}
      consoleLog.Close();

      InitVideo();
      log.i('tv > init video');

      if(video.ErrorCode <> vioOk) then begin
         eRaise(tveINIT_FAIL);
         exit;
      end;

      tvGlobal.DC.GetDriverCapabilities();
      tvGlobal.LogDC();

      GetModes();
      InitDefaults();

      if(Error <> 0) then
         exit;

      Initialized := true;
      log.i('tv > initialized: ' + tvCurrent.Mode.ToString());

      tvCurrent.GotoXY();

      video.SetCursorType(crHidden);
   end;
end;

procedure TVideoGlobal.Deinitialize();
begin
   ErrorReset();

   if(Initialized) then begin
      DoneVideo;
      Initialized := false;
   end;
end;

{ tvTDriverCapabilities }

procedure tvTDriverCapabilities.GetDriverCapabilities();
var
   _dc: word;{to temporarily store the dc word}

begin
   _dc := GetCapabilities();

   {set the booleans accordingly}
   Underline      := _dc and cpUnderline > 0;
   Blink          := _dc and cpBlink > 0;
   Color          := _dc and cpColor > 0;
   ChangeFont     := _dc and cpChangeFont > 0;
   ChangeMode     := _dc and cpChangeMode > 0;
   ChangeCursor   := _dc and cpChangeCursor > 0;
end;

{ tvTPhysicalDimensions }

procedure tvTPhysicalDimensions.Limit(var lx1, ly1, lx2, ly2: longint);
begin
   {check if in bounds and fix if not}
   if(lx1 < 0) then
      lx1 := 0;

   if(lx2 > x - 1) then
      lx2 := x - 1;

   if(ly1 < 0) then
      ly1 := 0;

   if(ly2 > y - 1) then
      ly2 := y - 1;
end;

procedure tvTPhysicalDimensions.Assign(newX, newY: longint);
begin
   Self.x := newX;
   Self.y := newY;
end;

procedure tvTPhysicalDimensions.Assign(mode: TVideoMode);
begin
   Self.x := mode.Col;
   Self.y := mode.Row;
end;

{ tvTDimensions }

procedure tvTDimensions.Limit(var lx1, ly1, lx2, ly2: longint);
begin
   {check if in bounds and fix if not}
   if(lx1 < x1) then
      lx1 := x1;

   if(lx2 > x2) then
      lx2 := x2;

   if(ly1 < y1) then
      ly1 := y1;

   if(ly2 > y2) then
      ly2 := y2;
end;

procedure tvTDimensions.Assign(newX1, newY1, newX2, newY2: longint);
begin
   x1 := newX1;
   y1 := newY1;
   x2 := newX2;
   y2 := newY2;
end;

procedure tvTDimensions.Assign(mode: TVideoMode);
begin
   Self.x1 := 0;
   Self.y1 := 0;
   Self.x2 := mode.Col - 1;
   Self.y2 := mode.Row - 1;
end;

procedure tvTDimensions.Offset(var x, y: longint);
begin
   x := x + x1;
   y := y + y1;
end;

function tvTDimensions.Inside(px1, py1: loopint): boolean;
begin
   Result := (px1 >= x1) and (px1 <= x2) and (py1 >= y1) and (py1 <= y2);
end;

function tvTDimensions.Covers(px1, py1, px2, py2: loopint): boolean;
begin
   Result := (px2 >= x2) and (px1 <= x2) and
      (py2 >= y1) and (py1 <= y2);
end;

{CELL BREAKING}
procedure TVideoCellHelper.Break(out ch: char; out color: byte; out bkcolor: byte; out blink: boolean);
var
   attr: byte;

begin
   {make the cell}
   {$ifdef ENDIAN_LITTLE}
      ch       := char(lo(Self));
      attr     := hi(Self);
      color    := (attr shl 4) shr 4;
      bkcolor  := (attr shr 4) shl 4;
   {$else}
      ch       := char(hi(Self))s;
      attr     := lo(Self);
      color    := (attr shr 4) shl 4;
      bkcolor  := (attr shl 4) shr 4;
   {$endif}

   blink := attr and video.Blink > 0;
end;

procedure TVideoCellHelper.Break(out ch: char; out color: byte; out bkcolor: byte);
var
   blink: boolean;

begin
   Break(ch, color, bkcolor, blink);
end;

procedure TVideoCellHelper.Break(out ch: char; out color: byte);
var
   blink: boolean;
   bkcolor: byte;

begin
   Break(ch, color, bkcolor, blink);
end;

procedure TVideoCellHelper.Break(out ch: char);
var
   blink: boolean;
   color,
   bkcolor: byte;

begin
   Break(ch, color, bkcolor, blink);
end;

function TVideoCellHelper.GetChar(): char;
begin
   result := char(low(Self));
end;

function TVideoCellHelper.GetColor(): byte;
begin
   TVideoAttribute(hi(Self)).Break(result);
end;

function TVideoCellHelper.GetBkColor(): byte;
var
  color: byte = 0;

begin
   TVideoAttribute(hi(Self)).Break(color, result);
end;

function TVideoCellHelper.GetBlink(): boolean;
begin
   Result := hi(Self) and Video.Blink <> 0;
end;

{CHARACTER PLOTTING}
procedure TVideoWindow.Plot(x, y: longint; ch: char);
var
   curAttr: TVideoAttribute;{the color and blink attributes}
   cell: TVideoCell;

begin
   {check arguments and environment}
   if(Buf <> nil) then begin
      if(tvSettings.LDCursor) then
         Limits.Offset(x, y);

      {if out of bounds then exit}
      if(not Limits.Inside(x, y)) then
         exit;

      {make attributes and cell}
      curAttr := tvMakeAttribute(Attr.Color, Attr.BkColor, Attr.Blink and tvGlobal.DC.Blink);
      cell := tvMakeCell(ch, curAttr);

      {now place the cell}
      Buf^[(y * Dimensions.x) + x] := cell;
   end;
end;

procedure TVideoWindow.Plot(x: longint; ch: char);
begin
   Plot(x, CursorY, ch);
end;

procedure TVideoWindow.Plot(ch: char);
begin
   Plot(CursorX, CursorY, ch);
end;

{MOVING}
procedure TVideoWindow.MoveUp(px1, py1, px2, py2: longint; n: word);
var
   position,
   offset,
   posinc,
   count: word;
   y,
   x1,
   y1,
   x2,
   y2,
   start: longint;

   cell: TVideoCell;

begin
   if(Buf <> nil) and (n > 0) then begin
      {ldcursors}
      if(tvSettings.LDCursor) then begin
         Limits.Offset(px1, py1);
         Limits.Offset(px2, py2);
      end;

      {assign temporary values}
      x1 := px1;
      y1 := py1;
      x2 := px2;
      y2 := py2;

      {check if in bounds and fix if not}
      Limits.Limit(x1, y1, x2, y2);

      if(py1 - n >= Limits.y1) then
         start := py1
      else
         start := py1 + (Limits.y1 - (py1 - n));

      if(start <=  y2) then begin
         count    := (x2 - x1 + 1) * 2;
         posinc   := Dimensions.x * 2;
         position := ((start * Dimensions.x) + x1) * 2;
         offset   := (((start - n) * Dimensions.x) + x1) * 2;

         for y := start to y2 do begin
            move((pointer(Buf) + position)^, (pointer(Buf) + offset)^, count);
            inc(position, posinc);
            inc(offset, posinc);
         end;
      end;

      if(tvSettings.ClearAfterMove) then begin
         if(n > y2 - y1 + 1) then
            n     := y2 - y1 + 1;

         start    := y2 - n + 1;
         if start < Limits.y1 then
            start := Limits.y1;

         position := (start * Dimensions.x) + x1;
         posinc   := Dimensions.x;
         count    := x2 - px1 + 1;

         cell := tvMakeCell(Attr.ClearChar, Attr.ClearColor, Attr.ClearBkColor, false);

         for y := start to y2 do begin
            FillWord(Buf^[position], count, cell);

            inc(position, posinc);
         end;
      end;
   end;
end;

procedure TVideoWindow.MoveDown(px1, py1, px2, py2: longint; n: word);
var
   position,
   offset,
   posinc,
   count: word;
   y,
   x1,
   y1,
   x2,
   y2,
   start: longint;
   cell: TVideoCell;

begin
   if(Buf <> nil) and (n > 0) then begin
      {ldcursors}
      if(tvSettings.LDCursor) then begin
         Limits.Offset(px1, py1);
         Limits.Offset(px2, py2);
      end;

      {assign temporary values}
      x1 := px1;
      y1 := py1;
      x2 := px2;
      y2 := py2;

      {check if in bounds and fix if not}
      Limits.Limit(x1, y1, x2, y2);

      if(py2 + n <= Limits.y2) then
         start := py2
      else
         start := py2 - ((py2 + n) - Limits.y2);

      if(start >=  y1) then begin
         count    := (x2 - x1 + 1) * 2;
         posinc   := Dimensions.x * 2;
         position := ((start * Dimensions.x) + x1) * 2;
         offset   := (((start + n) * Dimensions.x) + x1) * 2;

         for y := start downto y1 do begin
            move((pointer(Buf) + position)^, (pointer(Buf) + offset)^, count);
            dec(position, posinc);
            dec(offset, posinc);
         end;
      end;

      if(tvSettings.ClearAfterMove) then begin
         if(n > y2 - y1 + 1) then
            n := y2 - y1 + 1;

         start    := y1;
         position := (start * Dimensions.x) + x1;
         posinc   := Dimensions.x;
         count    := x2 - px1 + 1;

         cell := tvMakeCell(Attr.ClearChar, Attr.ClearColor, Attr.ClearBkColor, false);

         for y := start to y1 + n - 1 do begin
            FillWord(Buf^[position], count, cell);

            inc(position, posinc);
         end;
      end;
   end;
end;

procedure TVideoWindow.MoveLeft(px1, py1, px2, py2: longint; n: word);
var
   position,
   offset,
   posinc,
   count: word;
   y,
   x1,
   y1,
   x2,
   y2,
   start: longint;

   cell: TVideoCell;

begin
   if(Buf <> nil) and (n > 0) then begin
      {ldcursors}
      if(tvSettings.LDCursor) then begin
         Limits.Offset(px1, py1);
         Limits.Offset(px2, py2);
      end;

      {assign temporary values}
      x1 := px1;
      y1 := py1;
      x2 := px2;
      y2 := py2;

      {check if in bounds and fix if not}
      Limits.Limit(x1, y1, x2, y2);

      if(px1 - n >= Limits.x1) then
         start := px1
      else
         start := px1 + (Limits.x1 - (px1 - n));

      if(start <= x2) then begin
         position := (y1 * Dimensions.x + start) * 2;
         offset   := (y1 * Dimensions.x + (start - n)) * 2;
         posinc   := Dimensions.x * 2;
         count    := (x2 - start + 1) * 2;

         for y := y1 to y2 do begin
            move((pointer(Buf) + position)^, (pointer(Buf) + offset)^, count);
            inc(position, posinc);
            inc(offset, posinc);
         end;
      end;

      if(tvSettings.ClearAfterMove) then begin
         if(n > x2 - x1 + 1) then
            n := x2 - x1 + 1;

         start := x2 - n + 1;

         if start < Limits.x1 then
            start := Limits.x1;

         position := (y1 * Dimensions.x) + start;
         posinc   := Dimensions.x;
         count    := n;

         cell := tvMakeCell(Attr.ClearChar, Attr.ClearColor, Attr.ClearBkColor, false);

         for y := y1 to y2 do begin
            FillWord(Buf^[position], count, cell);

            inc(position, posinc);
         end;
      end;
   end;
end;

procedure TVideoWindow.MoveRight(px1, py1, px2, py2: longint; n: word);
var
   position,
   offset,
   posinc,
   count: word;
   y,
   x1,
   y1,
   x2,
   y2,
   start: longint;

   cell: TVideoCell;

begin
   if(Buf <> nil) and (n > 0) then begin
      {ldcursors}
      if(tvSettings.LDCursor) then begin
         Limits.Offset(px1, py1);
         Limits.Offset(px2, py2);
      end;

      {assign temporary values}
      x1 := px1;
      y1 := py1;
      x2 := px2;
      y2 := py2;

      {check if in bounds and fix if not}
      Limits.Limit(x1, y1, x2, y2);

      start := 0;
      if(n > x2 - x1 + 1) then
         n := x2 - x1 + 1;

      {move}
      if(start <=  x2) then begin
         position := ((y1 * Dimensions.x) + start) * 2;
         offset   := ((y1 * Dimensions.x) + (start + n)) * 2;
         count    := (x2 - x1 - n + 1) * 2;
         posinc   := Dimensions.x * 2;

         for y := y1 to y2 do begin
            move((pointer(Buf) + position)^, (pointer(Buf) + offset)^, count);
            inc(position, posinc);
            inc(offset, posinc);
         end;
      end;

      {clear leftovers}
      if(tvSettings.ClearAfterMove) then begin
         start    := x1;
         position := (y1 * Dimensions.x) + start;
         count    := n;
         posinc   := Dimensions.x;

         cell := tvMakeCell(Attr.ClearChar, Attr.ClearColor, Attr.ClearBkColor, false);

         for y := y1 to y2 do begin
            FillWord(Buf^[position], count, cell);

            inc(position, posinc);
         end;
      end;
   end;
end;

{LINE INSERT}

procedure TVideoWindow.InsertLine(y: longint);
begin
   if(y >= Limits.y1) and (y <= Limits.y2) then begin
      {simply move screen down to make it look like a line was inserted}
      MoveDown(0, y, (Limits.x2 - Limits.x1), y + 1, 1);
   end;
end;

{MOVING ROWS}

procedure TVideoWindow.MoveRowLeft(y: longint; n: word);
var
   position,
   count: word;

begin
   {check arguments}
   if(Buf <> nil) and (n > 0) then begin
      if(tvSettings.LDCursor) then
         inc(y, Limits.y1);

      if(n > Limits.x2 - Limits.x1 + 1) then
         n := Limits.x2 - Limits.x1 + 1;

      if(y >= Limits.y1) and (y <= Limits.y2) then begin
         {move line}
         if(Limits.x2 - Limits.x1 - n >= 1) then begin
            position := (y * Dimensions.x) * 2;
            count    := (Limits.x2 - Limits.x1 - n) * 2;

            move((pointer(Buf) + position+(n * 2))^, (pointer(Buf) + position)^, count);
         end;

         {clear leftovers}
         if(tvSettings.ClearAfterMove) then begin
            position := (y * Dimensions.x + (Limits.x2 - n + 1));
            count    := n;

            FillWord(Buf^[position], count, tvMakeCell(Attr.ClearChar,
               Attr.ClearColor, Attr.ClearBkColor, false));
         end;
      end else
   end;
end;

procedure TVideoWindow.MoveRowRight(y: longint; n: word);
var
   position,
   count: word;

begin
   {check arguments}
   if(Buf <> nil) and (n > 0) then begin
      if(tvSettings.LDCursor) then
         inc(y, Limits.y1);

      if(n > Limits.x2 - Limits.x1 + 1) then
         n := Limits.x2 - Limits.x1 + 1;

      if(y >= Limits.y1) and (y <= Limits.y2) then begin
         {move the line}
         if(Limits.x2 - Limits.x1 - n >= 1) then begin
            position  := (y * Dimensions.x) * 2;
            count := (Limits.x2 - Limits.x1 - n) * 2;

            move((pointer(Buf) + position)^, (pointer(Buf) + position + (n * 2))^, count);
         end;

         {clear leftovers}
         if(tvSettings.ClearAfterMove) then begin
            position  := (y * Dimensions.x + Limits.x1);
            count := n;

            FillWord(Buf^[position], count, tvMakeCell(Attr.ClearChar,
               Attr.ClearColor, Attr.ClearBkColor, false));
         end;
      end;
   end;
end;

{MOVING COLUMNS}

procedure TVideoWindow.MoveColUp(x: longint; n: word);
var
   position,
   offset,
   posinc,
   y,
   count: word;
   cell: TVideoCell;

begin
   {check arguments}
   if(Buf <> nil) and (n > 0) then begin
      if(tvSettings.LDCursor) then
         inc(x, Limits.y1);

      if(n > Limits.y2 - Limits.y1 + 1) then
         n := Limits.y2 - Limits.y1 + 1;

      if(x >= Limits.x1) and (x <= Limits.x2) then begin
         posinc := Dimensions.x;

         {move line}
         if(Limits.y2 - Limits.y1 - n >= 1) then begin
            position := (Limits.y1 + n) * Dimensions.x + x;
            offset := Limits.y1 * Dimensions.x + x;

            for y := Limits.y1 + n to Limits.y2 do begin
               Buf^[offset] := Buf^[position];
               inc(position, posinc);
               inc(offset, posinc);
            end;
         end;

         {clear leftovers}
         if(tvSettings.ClearAfterMove) then begin
            position := ((Limits.y2 - n + 1) * Dimensions.x + x);
            count    := 1;

            cell := tvMakeCell(Attr.ClearChar, Attr.ClearColor, Attr.ClearBkColor, false);

            for y := Limits.y2 - n + 1 to Limits.y2 do begin
               FillWord(Buf^[position], count, cell);

               inc(position, posinc);
            end;
         end;
      end;
   end;
end;

procedure TVideoWindow.MoveColDown(x: longint; n: word);
var
   position,
   offset,
   posinc,
   y,
   count: word;
   cell: TVideoCell;

begin
   {check arguments}
   if(Buf <> nil) and (n > 0) then begin
      if(tvSettings.LDCursor) then
         inc(x, Limits.y1);

      if(n > Limits.y2 - Limits.y1 + 1) then
         n := Limits.y2 - Limits.y1 + 1;

      if(x >= Limits.x1) and (x <= Limits.x2) then begin
         posinc := Dimensions.x;

         {move line}
         if(Limits.y2 - Limits.y1 - n >= 1) then begin
            position := (Limits.y2 - n) * Dimensions.x + x;
            offset   := (Limits.y2 * Dimensions.x) + x;

            for y := Limits.y1 + n to Limits.y2 do begin
               Buf^[offset] := Buf^[position];
               dec(position, posinc);
               dec(offset, posinc);
            end;
         end;

         {clear leftovers}
         if(tvSettings.ClearAfterMove) then begin
            position := ((Limits.y1) * Dimensions.x + x);
            count := 1;

            cell := tvMakeCell(Attr.ClearChar, Attr.ClearColor, Attr.ClearBkColor, false);

            for y := Limits.y1 to Limits.y1 + n - 1 do begin
               FillWord(Buf^[position], count, cell);
               inc(position, posinc);
            end;
         end;
      end;
   end;
end;

{WRITING STRINGS}

procedure TVideoWindow.Write(px, py: longint; const str: string);
var
  len,
  strpos: word;
  x,
  y,
  rep: longint;
  cell: TVideoCell;
  curAttr: TVideoAttribute;
  plotchar: boolean;
  ld: tvTDimensions;
  pd: tvTPhysicalDimensions;

procedure ResetLineStartPos;
begin
   case tvSettings.WriteDirection of
      tvcDLEFT_RIGHT: begin
         if(not tvSettings.newlineat0) then
            x := px
         else
            x := ld.x1;
      end;

      tvcdRIGHT_LEFT: begin
         if(not tvSettings.newlineat0) then
            x := px
         else
            x := ld.x2;
      end;

      tvcDUP_DOWN: begin
         if(not tvSettings.newlineat0) then
            y := py
         else
            y := ld.y1;
      end;

      tvcDDOWN_UP: begin
         if(not tvSettings.newlineat0) then
            y := py
         else
            y := ld.y2;
      end;
   end;
end;

function nextline(): boolean;
begin
   result := true;
   case tvSettings.NewLineDirection of
      tvcDLEFT_RIGHT: begin
         inc(x, tvSettings.LineSpacing);
         ResetLineStartPos();

         if(x >= Limits.x2) then
            result := false
         else
            plotchar := true;
      end;

      tvcdRIGHT_LEFT: begin
         dec(x, tvSettings.LineSpacing);
         ResetLineStartPos();

         if(x < ld.x1) then
            result := false
         else
            plotchar := true;
      end;

      tvcDUP_DOWN: begin
         inc(y, tvSettings.LineSpacing);
         ResetLineStartPos();

         if(y >= ld.y2) then
            result := false
         else
            plotchar := true;
      end;

      tvcDDOWN_UP: begin
         dec(y, tvSettings.LineSpacing);
         ResetLineStartPos();

         if(y <= ld.y1) then
            result := false
         else
            plotchar := true;
      end;
   end;
end;

{goes on to the next character position}
function nextcharacterpos(): boolean;
begin
   result   := true;
   plotchar := true;
   case tvSettings.WriteDirection of
      tvcDLEFT_RIGHT: begin
         inc(x);
         if(x > ld.x2) then begin
            if(not tvSettings.Clip) then
               result := nextline
            else
               plotchar := false;
         end;
      end;

      tvcDRIGHT_LEFT: begin
         dec(x);
         if(x < ld.x1) then begin
            if(not tvSettings.Clip) then
               result := nextline
            else
               plotchar := false;
         end;
      end;

      tvcDUP_DOWN: begin
         inc(y);
         if(y >  ld.y2) then begin
            if(not tvSettings.Clip) then
               result := nextline
            else
               plotchar := false;
         end;
      end;

      tvcDDOWN_UP: begin
         dec(y);
         if(y < ld.y1) then begin
            if(not tvSettings.Clip) then
               result := nextline
            else
               plotchar := false;
         end;
      end;
   end;
end;

begin
   {check arguments}
   if(Buf <> nil) then begin
      len := Length(str);{get the string length}
      if(len = 0) then
         exit;{if the string is empty then exit}

      curAttr := tvMakeAttribute(Attr.Color, Attr.BkColor, Attr.Blink);

      ld := Limits;
      pd := Dimensions;

      if(tvSettings.LDCursor) then begin
         inc(px, ld.y1);
         inc(py, ld.y1);
      end;

      x        := px;
      y        := py;

      plotchar := (x >= ld.x1) and (y >= ld.y1) and (x <= ld.x2) and (y <= ld.y2);
      strpos   := 0;

      repeat
         inc(strpos);
         if(tvSettings.EnterNewLine) then begin
            if((str[strpos] = #13) or (str[strpos] = #10)) then begin
               {jump to a new line}
               if(not nextline) then
                  break;
               {go to the next character}
               inc(strpos);
               {in case there might be an CRLF combination go to the next character}
               if(str[strpos] = #10) then
                  inc(strpos);
            end;
         end;
         if (tvSettings.Tab) then begin
            if(str[strpos] = #9) then begin
               if(tvSettings.TabSize > 0) then begin
                  {$ifdef ENDIAN_LITTLE}
                  cell := 32 + (curAttr shl 8);
                  {$else}
                  cell := curAttr + (32 shl 8);
                  {$endif}
                  for rep := 0 to tvSettings.TabSize-1 do begin
                     if(not tvSettings.SpaceTransparent) and (plotchar) then
                        Buf^[(y*pd.x) + x] := cell;
                     if(not nextcharacterpos) then
                        break;
                  end;
                  inc(strpos);
               end else
                  inc(strpos);
            end;
         end;

         if strpos > len then
            break;

         {plot the character}
         if (plotchar) then begin
            if(not tvSettings.WriteTransparent) then begin
               {make the cell}
               {$IFDEF ENDIAN_LITTLE}
               cell := byte(str[strpos]) + (curAttr shl 8);
               {$ELSE}
               cell := curAttr + (byte(str[strpos]) shl 8);
               {$ENDIF}
            end else begin
               cell := Buf^[(y * pd.x) + x];
               {$IFDEF ENDIAN_LITTLE}
               curAttr := ((hi(cell) shr 4) shl 4) + Attr.Color;
               cell := byte(str[strpos]) + (curAttr shl 8);
               {$ELSE}
               curAttr := ((lo(cell) shl 4) shr 4) + Attr.Color;
               cell := curAttr + (byte(str[strpos]) shl 8);
               {$ENDIF}
            end;
            {now place the cell}
            if(not tvSettings.SpaceTransparent) or (not (str[strpos] = #32)) then
               Buf^[(y * pd.x) + x] := cell;
         end;

         if(not nextcharacterpos) then
            break;
      until(strpos = len);
   end;
end;

procedure TVideoWindow.Write(const str: string);
begin
   Write(Cursor.x, Cursor.y, str);
end;

procedure TVideoWindow.Writeln(px, py: longint; const str: string);
begin
   Write(px, py, str + #13);
end;

procedure TVideoWindow.Writeln(const str: string);
begin
   Write(Cursor.x, Cursor.y, str + #13);
end;

{CLEARING}

procedure TVideoWindow.ClearScreen();
var
   cell: TVideoCell;

begin
   cell := tvMakeCell(Attr.ClearChar, Attr.ClearColor, Attr.ClearBkColor, false);
   fillword(Buf^, (Dimensions.y * Dimensions.x), cell);
end;

procedure TVideoWindow.Clear();
var
   y: word;
   cell: TVideoCell;
   count,
   position: word;

begin
   cell     := tvMakeCell(Attr.ClearChar, Attr.ClearColor, Attr.ClearBkColor, false);
   count    := (Limits.x2 - Limits.x1) + 1;
   position := (Limits.y1 * Dimensions.x * 2);

   if(Buf <> nil) then begin
      for y := Limits.y1 to Limits.y2 do begin
         fillword((pointer(Buf) + position)^, count, cell);
         position := position + ((Dimensions.x) * 2);
      end;
   end;
end;

procedure TVideoWindow.Update(force: boolean);
begin
   UpdateScreen(force);
end;

procedure TVideoWindow.SetClearColor(clr: byte);
begin
   Attr.ClearColor := clr;
end;

function TVideoWindow.GetClearColor(): byte;
begin
   Result := Attr.ClearColor;
end;

procedure TVideoWindow.SetClearBkColor(bkclr: byte);
begin
   Attr.ClearBkColor := bkclr;
end;

function TVideoWindow.GetClearBkColor(): byte;
begin
   Result := Attr.ClearBkColor;
end;

procedure TVideoWindow.SetClearChar(ch: char);
begin
   Attr.ClearChar := ch;
end;

function TVideoWindow.GetClearChar(): char;
begin
   result := Attr.ClearChar;
end;

procedure TVideoWindow.SetClearBlink(blink: boolean);
begin
   Attr.ClearBlink := blink;
end;

function TVideoWindow.GetClearBlink(): boolean;
begin
   Result := Attr.ClearBlink;
end;

{CURSOR MANAGEMENT}

procedure TVideoWindow.GotoXY(x, y: longint);
begin
   Cursor.x := x;
   Cursor.y := y;
end;

procedure TVideoWindow.GotoX(x: longint);
begin
   Cursor.x := x;
end;

procedure TVideoWindow.GotoY(y: longint);
begin
   Cursor.y := y
end;

procedure TVideoWindow.GotoXY();
begin
   GotoXY(0, 0);
end;

function TVideoWindow.GetCursorX(): longint;
begin
   Result := Cursor.x;
end;

function TVideoWindow.GetCursorY(): longint;
begin
   Result := Cursor.y;
end;

procedure TVideoWindow.DrawRect(px1, py1, px2, py2: longint);
var
   curAttr: TVideoAttribute;
   count,
   position,
   posinc: word;
   x,
   y,
   x1,
   y1,
   x2,
   y2: longint;
   cell: TVideoCell;

   LDC: array[0..10] of char;

begin
   LDC[0] := ' ';

   if(Buf <> nil) then begin
      {swap coordinates if they are out of order}
      if(px1 > px2) then begin
         x := px2;
         px2 := px1;
         px1 := x;
      end;

      if(py1 > py2) then begin
         y := py2;
         py2 := py1;
         py1 := y;
      end;

      if(tvSettings.LDCursor) then begin
         Limits.Offset(px1, py1);
         Limits.Offset(px2, py2);
      end;

      if(not Limits.Covers(px1, py1, px2, py2)) then
         exit;

      curAttr := tvMakeAttribute(Attr.Color, Attr.BkColor, Attr.Blink);

      if(px1 = px2) and (py1 = py2) then begin
         if(Limits.Inside(px1, py1)) then
            Buf^[(py1 * Dimensions.x) + px1] := byte(#218) + (curAttr shl 8);

         exit;
      end;

      case Attr.RectStyle of
         tvcSINGLE_LINE:
            move(LDCharSet, LDC, 11);
         tvcDOUBLE_LINE:
            move(LDCharSet[tvcLDD], LDC, 11);
         tvcCHARACTER:
            fillchar(LDC, 11, Attr.RectChar);
         else
            exit;
      end;

      {upper left corner}
      if(Limits.Inside(px1, py1)) then
         Buf^[(py1 * Dimensions.x) + px1] := tvMakeCell(LDC[tvcLDSUpperLeftCorner], curAttr);

      {upper right}
      if(Limits.Inside(px2, py1)) then
         Buf^[(py1 * Dimensions.x) + px2] := tvMakeCell(LDC[tvcLDSUpperRightCorner], curAttr);

      {lower left corner}
      if(Limits.Inside(px1, py2)) then
         Buf^[(py2 * Dimensions.x) + px1] := tvMakeCell(LDC[tvcLDSLowerLeftCorner], curAttr);

      {lower right corner}
      if(Limits.Inside(px2, py2)) then
         Buf^[(py2 * Dimensions.x) + px2] := tvMakeCell(LDC[tvcLDSLowerRightCorner], curAttr);

      x1 := px1;
      y1 := py1;
      x2 := px2;
      y2 := py2;

      inc(y1);
      dec(y2);
      inc(x1);
      dec(x2);

      Limits.Limit(x1, y1, x2, y2);

      {central up-down line}
      if(y1 < y2-1) then begin{if the line are visible at all then draw them}
         cell := tvMakeCell(LDC[tvcLDSUDCenter], curAttr);

         count := Dimensions.x;

         {left}
         if(px1 >= Limits.x1) then begin{if the line is within screen then draw it}
            position := (y1 * Dimensions.x) + px1;

            for y := (y1) to (y2) do begin
               Buf^[position] := cell;
               inc(position, count);
            end;
         end;

         {right}
         if(px2 <= Limits.x2) then begin{if the line is within screen then draw it}
            position := (y1 * Dimensions.x) + px2;

            for y := (y1) to (y2) do begin
               Buf^[position] := cell;
               inc(position, count);
            end;
         end;
      end;

      {line: left-right}
      if(x1 < x2 - 1) then begin{if the lines are visible at all then draw them}
         cell := tvMakeCell(LDC[tvcLDSLRCenter], curAttr);

         count := (x2) - (x1) + 1;

         {up}
         if(py1 >= Limits.y1) then
            fillword(Buf^[(py1 * Dimensions.x) + x1], count, cell);

         {down}
         if(py2 < Dimensions.y) then
            fillword(Buf^[(py2 * Dimensions.x) + x1], count, cell);
      end;


      {fill the rectangle}
      if(Attr.RectFill) and (x1 < x2 - 1) then begin
         cell     := tvMakeCell(Attr.FillChar, Attr.Color, Attr.BkColor, Attr.FillBlink);
         count    := ((x2 - 1) - (x1 + 1) + 1);
         position := ((py1 + 1) * Dimensions.x) + (x1 + 1) + 1;
         posinc   := Dimensions.x;

         for y := y1 to y2 do begin
            fillword(Buf^[position], count, cell);
            inc(position, posinc);
         end;
      end;
   end;
end;

procedure TVideoWindow.DrawRect();
begin
   DrawRect(0, 0, Dimensions.x - 1, Dimensions.y - 1);
end;

{BOX}

procedure TVideoWindow.DrawBox(px1, py1, px2, py2: longint);
var
  x,
  y,
  x1,
  y1,
  x2,
  y2: longint;
  position,
  posinc,
  count: word;

begin
   if(Buf <> nil) then begin
      if(tvSettings.LDCursor) then begin
         Limits.Offset(px1, py1);
         Limits.Offset(px2, py2);
      end;

      {swap coordinates if they are out of order}
      if(px1 > px2) then begin
         x := px2;
         px2 := px1;
         px1 := x;
      end;
      if(py1 > py2) then begin
         y := py2;
         py2 := py1;
         py1 := y;
      end;

      {check if box out of limitations | if it is exit since it would be pointless to even try to draw}
      if(not Limits.Covers(px1, py1, px2, py2)) then
         exit;

      x1 := px1;
      y1 := py1;
      x2 := px2;
      y2 := py2;

      Limits.Limit(px1, py1, px2, py2);

      count    := x2 - x1 + 1;
      position := (py1 * Dimensions.x) + x1;
      posinc   := Dimensions.x;
      for y := y1 to y2 do begin
         fillword(Buf^[position], count, tvMakeCell(Attr.FillChar, Attr.Color, Attr.BkColor, Attr.FillBlink));
         inc(position, posinc);
      end;
   end;
end;

procedure TVideoWindow.DrawBox();
begin
   DrawBox(0, 0, Limits.x2, Limits.y2);
end;

{LINES}

procedure TVideoWindow.HLine(px1, py1, px2: longint; ch: char);
var
   x,
   count: word;
   cell: TVideoCell;

begin
   if(Buf <> nil) then begin
      {modify the arguments for LD}
      if(tvSettings.LDCursor) then begin
         Limits.Offset(px1, py1);
         inc(px2, Limits.x1);
      end;

      {swap coordinates if they are out of order}
      if(px1 > px2) then begin
         x := px2;
         px2 := px1;
         px1 := x;
      end;

      {if out of bounds exit}
      if(not Limits.Covers(px1, py1, px2, py1)) then
         exit;

      if(px1 < tvCurrent.Limits.x1) then
         px1 := tvCurrent.Limits.x1;
      if(px2 > tvCurrent.Limits.x2) then
         px2 := tvCurrent.Limits.x2;

      cell := tvMakeCell(ch, tvCurrent.Attr.color, tvCurrent.Attr.bkcolor, tvCurrent.Attr.blink);

      count := px2 - px1 + 1;
      fillword(tvCurrent.Buf^[(py1 * Dimensions.x) + px1], count, cell);
   end;
end;

procedure TVideoWindow.VLine(px1, py1, py2: longint; ch: char);
var
   y,
   count,
   position: word;
   cell: TVideoCell;

begin
   if(Buf <> nil) then begin

      {modify the arguments for LD}
      if(tvSettings.LDCursor) then begin
         Limits.Offset(px1, py1);
         inc(py2, Limits.y1);
      end;

      {swap coordinates if they are out of order}
      if(py1 > py2) then begin
         y  := py2;
         py2 := py1;
         py1 := y;
      end;

      {if out of bounds exit}
      if (px1 < Limits.x1) or (px1 > Limits.x2) or
         (py2 < Limits.y1) or (py1 > Limits.y2) then
            exit;

      if(py1 < Limits.y1) then
         py1 := Limits.y1;
      if(py2 > Limits.y2) then
         py2 := Limits.y2;

      cell := tvMakeCell(ch, Attr.color, Attr.bkcolor, Attr.blink);
      position := (py1 * Dimensions.x) + px1;
      count := Dimensions.x;

      for y := py1 to py2 do begin
         Buf^[position] := cell;
         inc(position, count);
      end;
   end;
end;

procedure TVideoWindow.HLine(px1, py1, px2: longint; ldchar: byte);
begin
   HLine(px1, px2, py1, LDCharSet[ldchar]);
end;

procedure TVideoWindow.VLine(px1, py1, py2: longint; ldchar: byte);
begin
   VLine(px1, py1, py2, LDCharSet[ldchar]);
end;

{IMAGES}

{Image format:
   byte 0: image width - word
   byte 2: image heigth - word
   byte >= 4: image contents starting from 0:0, line by line

tvGetImage procs automatically allocate memory for the image. In case the
memory is already allocated the memory is freed and then reallocated(so make
sure your pointers are nil at the start, otehrwise the routines might think
there is memory allocated to them). Each proc first checks arguments & coordinates,
does memory allocs if required, sets or gets dimensions into the image, does
calculations concerning from and where to move and how much and then moves
everything(plots). Then does the clean-up.}

procedure TVideoWindow.GetImageDim(var w, h: word; img: pointer);
begin
   if(img = nil) then begin
      w := 0;
      h := 0;
      tvGlobal.eRaise(eNil);
      exit;
   end;

   {get width and heigth from the image}
   w := word(img^);
   h := word((img+2)^);
end;

function TVideoWindow.GetImageWidth(img: pointer): word;
begin
   if(img = nil) then begin
      Result := 0;
      tvGlobal.eRaise(eNil);
      exit;
   end;

   {get width and heigth from the image}
   Result := word(img^);
end;

function TVideoWindow.GetImageHeigth(img: pointer): word;
begin
   if(img = nil) then begin
      Result := 0;
      tvGlobal.eRaise(eNil);
      exit;
   end;

   {get width and heigth from the image}
   Result := word((img + 2)^);
end;

procedure TVideoWindow.GetImage(px1, py1, px2, py2: longint; var img: pointer);
var
   x,
   y,
   w,
   h,
   movecount,
   position,
   offset,
   incpos,
   incofs: word;
   x1,
   y1,
   x2,
   y2: longint;

begin
   if(Buf <> nil) then begin
      {swap coordinates if they are out of order}
      if(px1 > px2) then begin
         x := px2;
         px2 := px1;
         px1 := x;
      end;
      if(py1 > py2) then begin
         y := py2;
         py2 := py1;
         py1 := y;
      end;

      if(tvSettings.LDCursor) then begin
         Limits.Offset(px1, py1);
         Limits.Offset(px2, py2);
      end;

      w := px2 - px1 + 1;
      h := py2 - py1 + 1;

      {if there is memory allocated to the pointer then free it}
      if(img <> nil) then begin
         XFreeMem(img);
         img := nil;
      end;

      {try to allocate memory for the image}
      XGetMem(img, (w * h * 2) + 4);
      if(img = nil) then begin
         tvGlobal.eRaise(eNO_MEMORY);
         exit;
      end;

      {write width and heigth into the image}
      word(img^)     := w;
      word((img+2)^) := h;

      if (px1 + w < 0) or (py1 + h < 0) or (px1 > Dimensions.x) or (py1 > Dimensions.y) then
         exit; {if it is out of bounds then exit since the image cannot be captured}

      {perform all calculations required to capture the image properly}
      offset := 4;
      if(px1 < 0) then begin
         inc(offset, (0 - px1) * 2);
         x1 := 0;
      end else
         x1 := px1;

      if(py1 < 0) then begin
         inc(offset, (0 - py1) * w * 2);
         y1 := 0;
      end else
         y1 := py1;

      if(px2 >= Dimensions.x) then
         x2 := Dimensions.x - 1
      else
         x2 := px2;

      if(py2 >= Dimensions.y) then
         y2 := Dimensions.y - 1
      else
         y2 := py2;

      movecount   := (x2 - x1 + 1) * 2;
      position    := (y1 * Dimensions.x + x1) * 2;
      incpos      := Dimensions.x * 2;
      incofs      := w * 2;

      {now capture the image}
      for y := y1 to y2 do begin
         move((pointer(Buf) + position)^, (img + offset)^, movecount);
         inc(position, incpos);
         inc(offset, incofs);
      end;
   end;
end;

procedure TVideoWindow.PlotImage(px1, py1: longint; wid, hgt: word; img: pointer);
var
   movecount,
   w,
   h,
   position,
   offset,
   incpos,
   incofs: word;
   y,
   x1,
   y1,
   x2,
   y2: longint;

begin
   if(Buf <> nil) and (img <> nil) then begin
      {get width and heigth from the image}
      w := word(img^);
      h := word((img+2)^);

      if wid = 0 then
         wid := w
      else if wid > w then
         wid := w;

      if hgt = 0 then
         hgt := h
      else if wid > h then
         hgt := h;

      if(tvSettings.LDCursor) then begin
         Limits.Offset(px1, py1);
      end;

      if (px1 + w < 0) or (py1 + h < 0) or (px1 > Dimensions.x) or (py1 > Dimensions.y) then
         exit; {if it is out of bounds then exit since the image cannot be captured}

      {perform all required calculations}
      x2   := px1 + (wid - 1);
      y2   := py1 + (hgt - 1);

      offset := 4;
      if(px1 < 0) then begin
         x1 := 0;
         inc(offset, (0 - px1) * 2);
      end else
         x1 := px1;

      if py1 < 0 then begin
         y1 := 0;
         inc(offset, (0 - py1) * w * 2);
      end else
         y1 := py1;

      if(x2 >= Dimensions.x) then
         x2 := Dimensions.x - 1;

      if(y2 >= Dimensions.y) then
         y2 := Dimensions.y - 1;

      {determine from and to where to move and how much}
      position    := (y1 * Dimensions.x + x1) * 2;
      movecount   := (x2-x1 + 1) * 2;

      incofs := w * 2;
      incpos := Dimensions.x * 2;

      {draw the image}
      for y := y1 to y2 do begin
         move((img+offset)^, (pointer(Buf)+position)^, movecount);
         inc(offset, incofs);
         inc(position, incpos);
      end;
   end;
end;

procedure TVideoWindow.PlotImage(px1, py1: longint; img: pointer);
begin
   PlotImage(px1, py1, 0, 0, img);
end;

procedure TVideoWindow.GetScreenLtd(var img: pointer);
var
   w,
   h,
   pos,
   posinc,
   ofs,
   count,
   y,
   x1,
   y1,
   x2,
   y2: word;

begin
   if(Buf <> nil) then begin
      x1 := Limits.x1;
      y1 := Limits.y1;
      x2 := Limits.x2;
      y2 := Limits.y2;

      w := x2 - x1 + 1;
      h := y2 - y1 + 1;

      {if there is memory allocated to the pointer then free it}
      if(img <> nil) then begin
         XFreeMem(img);
         img := nil;
      end;

      {try to allocate memory for the image | otherwise assume that memory has already been allocated}
      XGetMem(img, (w * h * 2) + 4);
      if(img = nil) then begin
         tvGlobal.eRaise(eNO_MEMORY);
         exit;
      end;

      {write width and heigth into the image}
      word(img^)        := w;
      word((img + 2)^)  := h;

      pos      := (y1 * Dimensions.x + x1) * 2;
      posinc   := Dimensions.x * 2;
      count    := w * 2;
      ofs      := 4;

      {now capture the image}
      for y := y1 to y2 do begin
         move((pointer(Buf) + pos)^, (img + ofs)^, count);
         inc(pos, posinc);
         inc(ofs, count);
      end;
   end;
end;

procedure TVideoWindow.PlotScreenLtd(img: pointer);
var
   w,
   h,
   pos,
   posinc,
   ofs,
   count,
   y,
   x1,
   y1,
   x2,
   y2: word;

begin
   if(Buf <> nil) and (img <> nil) then begin
      {get width and heigth from the image}
      w := word(img^);
      h := word((img + 2)^);

      x1 := Limits.x1;
      y1 := Limits.y1;
      x2 := Limits.x2;
      y2 := Limits.y2;

      if(y2 - y1 > h) then
         y2 := y1 + h - 1;

      pos      := (y1 * Dimensions.x + x1) * 2;
      posinc   := Dimensions.x*2;
      count    := (x2 - x1 + 1) * 2;
      ofs      := 4;

      {now capture the image}
      for y := y1 to y2 do begin
         move((img + ofs)^, (pointer(Buf) + pos)^, count);
         inc(pos, posinc);
         inc(ofs, w * 2);
      end;
   end;
end;

procedure TVideoWindow.GetScreen(var img: pointer);
var
  w,
  h: word;

begin
   if(Buf <> nil) then begin
      w := Dimensions.x;
      h := Dimensions.y;

      {if there is memory allocated to the pointer then free it}
      if(img <> nil) then begin
         XFreeMem(img);
         img := nil;
      end;

      {try to allocate memory for the image | otherwise assume that memory has already been allocated}
      XGetMem(img, (w * h * 2) + 4);
      if(img = nil) then begin
         tvGlobal.eRaise(eNO_MEMORY);
         exit;
      end;

      {write width and heigth into the image}
      word(img^)        := w;
      word((img + 2)^)  := h;

      {now capture the image}
      move(Buf^, (img + 4)^, w * h * 2);
   end;
end;

procedure TVideoWindow.PlotScreen(img: pointer);
var
  w, h: word;

begin
   if(Buf <> nil) and (img <> nil) then begin
      {get width and heigth from the image}
      w := word(img^);
      h := word((img + 2)^);

      if(w > Dimensions.x) or (h > Dimensions.y) then begin
         tvGlobal.eRaise(tveOUT_OF_BOUNDS);
         exit;
      end;

      {write width and heigth into the image}
      word(img^)        := w;
      word((img + 2)^)  := h;

      {draw the image}
      move((img + 4)^, Buf^, w * h * 2);
   end;
end;

procedure TVideoWindow.DisposeImage(var img: pointer);
begin
   if(img <> nil) then begin
      XFreeMem(img);
      img := nil;
   end;
end;

{CLIP}

{Clip the image at borders. This will make it smaller. The memory is also
reallocated assuring smaller memory usage of the image since the image is clipped.}
procedure TVideoWindow.ClipImage(wid, hgt: word; var img: pointer);
var
   w,
   h,
   rep,
   pos,
   ofs,
   posinc,
   ofsinc: word;

begin
   {check arguments}
   if(img = nil) then begin
      tvGlobal.eRaise(eNil);
      exit;
   end;

   {get width and heigth from the image}
   w := word(img^);
   h := word((img + 2)^);

   {check if it makes sense to process the image}
   if(wid > w) or (wid < 1) or (hgt < 1) or (hgt > h) then
      exit;

   if(wid = w) and (hgt = h) then
      exit;

   {calculate starting positions and how much to move later for each line}
   pos      := (1 * h) * 2 + 4;
   posinc   := w * 2;
   ofsinc   := wid * 2;
   ofs      := ofsinc + 4;

   {process the image}
   for rep := 1 to hgt-1 do begin
      move((img+pos)^, (img+ofs)^, ofsinc);
      inc(pos, posinc);
      inc(ofs, ofsinc);
   end;

   {write new width and heigth into the image}
   word(img^)        := wid;
   word((img + 2)^)  := hgt;

   ReAllocMem(img, (wid * hgt * 2 + 4));
end;

procedure TVideoWindow.ClipBuf(wid, hgt: word; var pbuf: PVideoBuf; var pdim: tvTPhysicalDimensions);
var
   w,
   h,
   rep,
   pos,
   ofs,
   posinc,
   ofsinc: word;

begin
   {check arguments}
   if(pbuf = nil) then begin
      tvGlobal.eRaise(eNil);
      exit;
   end;

   {get dimensions of the buffer}
   w := pdim.x;
   h := pdim.y;

   {check if it makes sense to process the image}
   if(wid > w) or (wid < 1) or (hgt < 1) or (hgt > h) then
      exit;
   if(wid = w) and (hgt = h) then
      exit;

   {calculate starting positions and how much to move later for each line}
   pos      := (1 * h) * 2;
   posinc   := w * 2;
   ofsinc   := wid * 2;
   ofs      := ofsinc;

   {process the image}
   for rep := 1 to hgt-1 do begin
      move((pointer(pbuf) + pos)^, (pointer(pbuf) + ofs)^, ofsinc);
      inc(pos, posinc);
      inc(ofs, ofsinc);
   end;

   {write new width and heigth into the pdim}
   pdim.x := wid;
   pdim.y := hgt;

   ReAllocMem(pbuf, (wid * hgt * 2));
end;

INITIALIZATION
   tvSettings.Log                := true;
   tvSettings.ChangeModes        := true;
   tvSettings.TabSize            := 8;
   tvSettings.Clip               := true;
   tvSettings.EnterNewLine       := true;
   tvSettings.WriteDirection     := tvcDLEFT_RIGHT;
   tvSettings.NewLineDirection   := tvcDUP_DOWN;
   tvSettings.LineSpacing        := 1;
   tvSettings.LDCursor           := true;
   tvCurrent.Initialize();

FINALIZATION
   tvGlobal.Deinitialize();

END.
