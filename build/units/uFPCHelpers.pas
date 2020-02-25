{
   uFPCHelpers
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
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
   p: loopint;

begin
   cpu := '';
   os := '';

   p := Pos('-', Self);

   if(p > 0) then begin
      cpu := Copy(Self, 1, p - 1);
      os := Copy(Self, p + 1, Length(Self) - p);
   end;
end;

END.
