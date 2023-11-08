{
   yPakU, yPak tool base unit
   Copyright (C) 2011. Dejan Boras
}

{$MODE OBJFPC}{$H+}
UNIT yPakU;

INTERFACE

   USES uFile, uyPak;

CONST
   { filtering modes }
   FLTR_MODE_UNKNOWN    = $0000;
   FLTR_MODE_INCLUDE    = $0001;
   FLTR_MODE_EXCLUDE    = $0002;

   pakfnDefault = 'data.ypk';

VAR
  pak: record
     fn: string;
     f: TFile;
     filterMode: longint;
     included, excluded: string;
     entries: ypkTEntries;
  end;

procedure ypkfSetBuffer();

IMPLEMENTATION

procedure ypkfSetBuffer();
begin
   pak.f.Buffer(128 * 1024);
end;

INITIALIZATION
   pak.excluded := '.exe .ypk';

END.
