{   
   ConsoleUtils, various utilities for console programs
   Copyright (C) 2008. Dejan Boras

   Started On:    19.04.2008.
}

{$MODE OBJFPC}{$H+}{$I-}{$MODESWITCH ADVANCEDRECORDS}
UNIT ConsoleUtils;

INTERFACE

   USES uStd
     {$IFDEF WINDOWS}, sysutils, windows{$ENDIF};

{$IFDEF UNIX}
   {$DEFINE TTY_SUPPORTED}
{$ENDIF}
{$IFDEF WINDOWS}
   {$DEFINE TTY_SUPPORTED}
{$ENDIF}

TYPE
   { TConsoleGlobal }

   TConsoleGlobal = record
   const
      Black         = 0;
      Blue          = 1;
      Green         = 2;
      Cyan          = 3;
      Red           = 4;
      Magenta       = 5;
      Brown         = 6;
      LightGray     = 7;
      DarkGray      = 8;
      LightBlue     = 9;
      LightGreen    = 10;
      LightCyan     = 11;
      LightRed      = 12;
      LightMagenta  = 13;
      Yellow        = 14;
      White         = 15;
      Transparent   = 255; {special cases, means to leave color intact}

   public
      Colors: record
         Enabled: boolean;

         Default,
         DefaultBackground,
         Verbose,
         Error,
         Warning: longint;
      end;

      LastTextColor,
      LastBackgroundColor,
      InitialTextColor,
      InitialBackgroundColor: longint;

      {$IFDEF WINDOWS}
      hwnd: HWND;
      {are we running in a bash environment under windows}
      ansiSupported: boolean;
      {$ENDIF}

      {method prefixed with an n do not write a prefix string}

      {write an error string}
      procedure e(const say: StdString); inline;
      {write a warning string}
      procedure w(const say: StdString); inline;
      {write a verbose string}
      procedure v(const say: StdString); inline;
      {outputs text to the console}
      procedure i(const say: StdString);
      procedure i();
      {constructs a string out of all parameter strings}
      procedure GetParamsString(out s: StdString);

      procedure TextColor(color: longint);
      procedure BackgroundColor(bkgColor: longint);
      procedure Bold();
      procedure Italic();
      procedure Underline();
      procedure ResetDefault();

      {$IFDEF TTY_SUPPORTED}
      procedure SetUnixColor();
      {$ENDIF}

      {$IFDEF WINDOWS}
      procedure SetWindowsColor();
      {$ENDIF}

      procedure Clear();
   end;

VAR
   console: TConsoleGlobal;

IMPLEMENTATION

{$IFDEF TTY_SUPPORTED}
VAR
   (*30	Black
   31	Red
   32	Green
   33	Yellow
   34	Blue
   35	Magenta
   36	Cyan
   37	White

   Background colors
   40	Black
   41	Red
   42	Green
   43	Yellow
   44	Blue
   45	Magenta
   46	Cyan
   47	White*)

   fguColorEscapeSequences: array[0..15] of StdString = (
      '30', {Black}
      '34', {Blue}
      '32', {Green}
      '36', {Cyan}
      '31', {Red}
      '35', {Magenta}
      '33', {Brown}
      '37', {LightGray}
      '90', {DarkGray}
      '94', {LightBlue}
      '92', {LightGreen}
      '96', {LightCyan}
      '91', {LightRed}
      '95', {LightMagenta}
      '93', {Yellow}
      '97;' {White}
   );

   bguColorEscapeSequences: array[0..15] of StdString = (
      '40', {Black}
      '44', {Blue}
      '42', {Green}
      '46', {Cyan}
      '41', {Red}
      '45', {Magenta}
      '43', {Brown}
      '47', {LightGray}
      '100', {DarkGray}
      '104', {LightBlue}
      '102', {LightGreen}
      '106', {LightCyan}
      '101', {LightRed}
      '105', {LightMagenta}
      '103', {Yellow}
      '107'  {White}
   );
{$ENDIF}

{$IFDEF WINDOWS}
VAR
   fgColorEscapeSequences: array[0..15] of byte = (
      0, {Black}
      FOREGROUND_BLUE, {Blue}
      FOREGROUND_GREEN, {Green}
      FOREGROUND_BLUE or FOREGROUND_GREEN, {Cyan}
      FOREGROUND_RED, {Red}
      FOREGROUND_RED or FOREGROUND_BLUE, {Magenta}
      FOREGROUND_RED or FOREGROUND_GREEN, {Brown}
      FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_BLUE, {LightGray}
      FOREGROUND_INTENSITY, {DarkGray}
      FOREGROUND_INTENSITY or FOREGROUND_BLUE, {LightBlue}
      FOREGROUND_INTENSITY or FOREGROUND_GREEN, {LightGreen}
      FOREGROUND_INTENSITY or FOREGROUND_BLUE or FOREGROUND_GREEN, {LightCyan}
      FOREGROUND_INTENSITY or FOREGROUND_RED, {LightRed}
      FOREGROUND_INTENSITY or FOREGROUND_RED or FOREGROUND_BLUE, {LightMagenta}
      FOREGROUND_INTENSITY or FOREGROUND_RED or FOREGROUND_GREEN, {Yellow}
      FOREGROUND_INTENSITY or FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_BLUE {White}
   );

   bgColorEscapeSequences: array[0..15] of byte = (
      0, {Black}
      BACKGROUND_BLUE, {Blue}
      BACKGROUND_GREEN, {Green}
      BACKGROUND_BLUE or BACKGROUND_GREEN, {Cyan}
      BACKGROUND_RED, {Red}
      BACKGROUND_RED or BACKGROUND_BLUE, {Magenta}
      BACKGROUND_RED or BACKGROUND_GREEN, {Brown}
      BACKGROUND_RED or BACKGROUND_GREEN or BACKGROUND_BLUE, {LightGray}
      BACKGROUND_INTENSITY, {DarkGray}
      BACKGROUND_INTENSITY or BACKGROUND_BLUE, {LightBlue}
      BACKGROUND_INTENSITY or BACKGROUND_GREEN, {LightGreen}
      BACKGROUND_INTENSITY or BACKGROUND_BLUE or BACKGROUND_GREEN, {LightCyan}
      BACKGROUND_INTENSITY or BACKGROUND_RED, {LightRed}
      BACKGROUND_INTENSITY or BACKGROUND_RED or BACKGROUND_BLUE, {LightMagenta}
      BACKGROUND_INTENSITY or BACKGROUND_RED or BACKGROUND_GREEN, {Yellow}
      BACKGROUND_INTENSITY or BACKGROUND_RED or BACKGROUND_GREEN or BACKGROUND_BLUE {White}
   );
{$ENDIF}

procedure TConsoleGlobal.e(const say: StdString);
begin
   {$IFDEF WINDOWS}if(isConsole = true) then{$ENDIF}
   begin
      TextColor(Colors.Error);
      writeln(say);
      ResetDefault();
   end;
end;

procedure TConsoleGlobal.w(const say: StdString);
begin
   {$IFDEF WINDOWS}if(isConsole = true) then{$ENDIF}
   begin
      TextColor(Colors.Warning);
      writeln(say);
      ResetDefault();
   end;
end;

procedure TConsoleGlobal.v(const say: StdString);
begin
   {$IFDEF WINDOWS}if(isConsole = true) then{$ENDIF}
   begin
      TextColor(Colors.Verbose);
      writeln(say);
      ResetDefault();
   end;
end;

procedure TConsoleGlobal.i(const say: StdString);
begin
   {$IFDEF WINDOWS}if(isConsole = true) then{$ENDIF}
      writeln(say);
end;

procedure TConsoleGlobal.i();
begin
   {$IFDEF WINDOWS}if(isConsole = true) then{$ENDIF}
      writeln('');
end;

procedure TConsoleGlobal.GetParamsString(out s: StdString);
var
   nParams,
   z: longint;

begin
   s := '';

   nParams := ParamCount();
   if(nParams > 0) then begin
      for z := 1 to nParams do
         if(z <> nParams) then
            s := s + ParamStr(z) + ' '
         else
            s := s + ParamStr(z);
   end;
end;

procedure TConsoleGlobal.TextColor(color: longint);
begin
   if(color >= 0) and (color <= White) then begin
      LastTextColor := color;

      {$IFDEF UNIX}
      SetUnixColor();
      {$ENDIF}

      {$IFDEF WINDOWS}
      if(not ansiSupported) then
         SetWindowsColor()
      else
         SetUnixColor();
      {$ENDIF}
   end;
end;

procedure TConsoleGlobal.BackgroundColor(bkgColor: longint);
begin
   if(bkgColor < Transparent) then begin
      LastBackgroundColor := bkgColor;

      {$IFDEF UNIX}
      SetUnixColor();
      {$ENDIF}
      {$IFDEF WINDOWS}
      if(not ansiSupported) then
         SetWindowsColor()
      else
         SetUnixColor();
      {$ENDIF}
   end;
end;

procedure TConsoleGlobal.Bold();
begin
   {$IFDEF UNIX}
   Write(#27'[1m');
   {$ENDIF}

   {$IFDEF WINDOWS}
   if(ansiSupported) then
      write(#27'[1m');
   {$ENDIF}
end;

procedure TConsoleGlobal.Italic();
begin
   {$IFDEF UNIX}
   Write(#27'[3m');
   {$ENDIF}

   {$IFDEF WINDOWS}
   if(ansiSupported) then
      write(#27'[3m');
   {$ENDIF}
end;

procedure TConsoleGlobal.Underline();
begin
   {$IFDEF UNIX}
   Write(#27'[4m');
   {$ENDIF}

   {$IFDEF WINDOWS}
   if(ansiSupported) then
      write(#27'[4m');
   {$ENDIF}
end;

procedure TConsoleGlobal.ResetDefault();
begin
   LastTextColor := console.Colors.Default;
   LastBackgroundColor := console.Colors.DefaultBackground;

   {$IFDEF UNIX}
   Write(#27'[0m');
   {$ENDIF}
   {$IFDEF WINDOWS}
   TextColor(console.Colors.Default);
   BackgroundColor(console.Colors.DefaultBackground);

   // TODO: Use SetConsoleTextAttribute with the original attributes
   {$ENDIF}
end;

{$IFDEF WINDOWS}
procedure TConsoleGlobal.SetWindowsColor;
var
   attributes: word;

begin
   if(system.IsConsole) and (console.hwnd <> 0) then begin
      {$PUSH}{$R-}
      attributes := fgColorEscapeSequences[LastTextColor];
      if(LastBackgroundColor < console.Transparent) then
         attributes := attributes or bgColorEscapeSequences[LastBackgroundColor];

      SetConsoleTextAttribute(console.hwnd, attributes);
   end;
end;
{$ENDIF}

{$IFDEF TTY_SUPPORTED}
procedure TConsoleGlobal.SetUnixColor();
begin
   if(LastBackgroundColor < Transparent) then
      Write(#27'[' + fguColorEscapeSequences[LastTextColor] + ';' + bguColorEscapeSequences[LastBackgroundColor] + 'm')
   else
      Write(#27'[' + fguColorEscapeSequences[LastTextColor] + 'm');
end;
{$ENDIF}

procedure TConsoleGlobal.Clear();
begin
   {$IFDEF UNIX}
   write(#27'[2J');
   {$ENDIF}

   {$IFDEF WINDOWS}
   if(ansiSupported) then
      write(#27'[2J');
   {$ENDIF}
end;

{$IFDEF WINDOWS}
procedure InitializeWindows();
var
   info: TCONSOLESCREENBUFFERINFO;
   i: loopint;
   clr: byte;

begin
   SetConsoleCP(CP_UTF8);

   if(pos('bash', sysutils.GetEnvironmentVariable('SHELL')) > 0) then begin
      console.ansiSupported := true;
      exit;
   end;

   if(system.IsConsole) then
      console.hwnd := GetStdHandle(STD_OUTPUT_HANDLE);

   ZeroOut(info, SizeOf(info));
   GetConsoleScreenBufferInfo(console.hwnd, info);

   clr := 0;

   if(info.wAttributes and FOREGROUND_RED > 0) then
      clr := clr or FOREGROUND_RED;
   if(info.wAttributes and FOREGROUND_GREEN > 0) then
      clr := clr or FOREGROUND_GREEN;
   if(info.wAttributes and FOREGROUND_BLUE > 0) then
      clr := clr or FOREGROUND_BLUE;
   if(info.wAttributes and FOREGROUND_INTENSITY > 0) then
      clr := clr or FOREGROUND_INTENSITY;

   for i := 0 to console.White do begin
      if(fgColorEscapeSequences[i] = clr) then begin
         console.InitialTextColor := i;
         console.LastTextColor := i;
         break;
      end;
   end;

   clr := 0;
   if(info.wAttributes and BACKGROUND_RED > 0) then
      clr := clr or BACKGROUND_RED;
   if(info.wAttributes and BACKGROUND_GREEN > 0) then
      clr := clr or BACKGROUND_GREEN;
   if(info.wAttributes and BACKGROUND_BLUE > 0) then
      clr := clr or BACKGROUND_BLUE;
   if(info.wAttributes and BACKGROUND_INTENSITY > 0) then
      clr := clr or BACKGROUND_INTENSITY;

   for i := 0 to console.White do begin
      if(bgColorEscapeSequences[i] = clr) then begin
         console.InitialBackgroundColor := i;
         console.LastBackgroundColor := i;
         break;
      end;
   end;
end;
{$ENDIF}

INITIALIZATION
   console.Colors.Verbose := console.DarkGray;
   console.Colors.Error := console.LightRed;
   console.Colors.Warning := console.Yellow;
   console.Colors.Default := console.LightGray;
   console.Colors.DefaultBackground := console.Transparent;

   console.LastBackgroundColor := console.colors.DefaultBackground;
   console.LastTextColor := console.colors.Default;

   console.InitialTextColor := console.Transparent;
   console.InitialBackgroundColor := console.Transparent;

   {$IFDEF WINDOWS}
   InitializeWindows();
   {$ENDIF}

   if(console.InitialTextColor <> console.Transparent) then
      console.Colors.Default := console.InitialTextColor;

   if(console.InitialBackgroundColor <> console.Transparent) then
      console.Colors.DefaultBackground := console.InitialBackgroundColor;

   console.ResetDefault();

FINALIZATION
   if(console.InitialTextColor <> console.Transparent) then
      console.TextColor(console.LastTextColor);

   if(console.InitialBackgroundColor <> console.Transparent) then
      console.BackgroundColor(console.LastBackgroundColor);

END.
