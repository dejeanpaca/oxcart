{
   uFileTrash, file trash/recycle helpers
   Copyright (C) 2020. Dejan Boras

   Started On:    30.01.2020.
}

{$INCLUDE oxheader.inc}
UNIT uFileTrash;

INTERFACE

   USES
      uStd, uFileUtils;

TYPE

   { TFileTrash }

   TFileTrash = record
      class procedure Recycle(const fn: StdString); static;
   end;

IMPLEMENTATION

{ TFileTrash }

{$IFDEF WINDOWS}
class procedure TFileTrash.Recycle(const fn: StdString);
begin

end;
{$ELSE}
class procedure TFileTrash.Recycle(const fn: StdString);
begin

end;
{$ENDIF}

END.
