{
   yPakU, yPak tool base unit
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT yPakU;

INTERFACE

   USES
      uFile, uyPakFile;

CONST
   YPK_DEFAULT_FN = 'data.ypk';

   { filtering modes }
   FLTR_MODE_UNKNOWN    = $0000;
   FLTR_MODE_INCLUDE    = $0001;
   FLTR_MODE_EXCLUDE    = $0002;

TYPE

  { TPak }

  TPak = record
     fn: string;
     f: TFile;
     data: ypkTData;
     FilterMode: longint;
     Included,
     Excluded: string;
     Entries: ypkfTEntries;

     procedure SetBuffer();
  end;

VAR
  pak: TPak;
  ypkf: ypkTFile;

IMPLEMENTATION

{ TPak }

procedure TPak.SetBuffer();
begin
  pak.f.Buffer(128 * 1024);
end;

INITIALIZATION
   ypkTFile.Initialize(ypkf);
   ypkf.f := @pak.f;
   pak.Excluded := '.exe .ypk';

END.
