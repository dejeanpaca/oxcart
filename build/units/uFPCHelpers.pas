{
   uFPCHelpers
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uFPCHelpers;

INTERFACE

   USES uStd;

CONST

   FPC_VERSION = {$I %FPCVersion%};
   FPC_TARGET = {$I %FPCTARGET%};
   FPC_TARGETCPU = {$I %FPCTARGETCPU%};
   FPC_TARGETOS = {$I %FPCTARGETOS%};

TYPE
   TFPCPlatformString = StdString;

   { TFPCPlatformStringHelper }

   TFPCPlatformStringHelper = type helper for TFPCPlatformString
      procedure Separate(out cpu, os: StdString);
   end;

IMPLEMENTATION

{ TFPCPlatformStringHelper }

procedure TFPCPlatformStringHelper.Separate(out cpu, os: StdString);
var
   p, p2: loopint;

begin
   cpu := '';
   os := '';

   p := Pos('-', Self);

   if(p > 0) then begin
      {some string may contain a second '-' such as x86-64-android}
      p2 := Pos('-', Self, p + 1);

      if(p2 > 0) then
         p := p2;

      {separate}
      cpu := Copy(Self, 1, p - 1);
      os := Copy(Self, p + 1, Length(Self) - p);
   end;
end;

END.
