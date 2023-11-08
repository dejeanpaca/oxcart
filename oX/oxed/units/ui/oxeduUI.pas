{
   oxeduUI, oxed UI basics
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduUI;

INTERFACE

   USES
      uColors;

TYPE

   { oxedTUI }

   oxedTUI = record
      LazarusColor: TColor4ub;
   end;

VAR
   oxedUI: oxedTUI;

IMPLEMENTATION

INITIALIZATION
   oxedUI.LazarusColor.Assign(160, 160, 255, 255);

END.
