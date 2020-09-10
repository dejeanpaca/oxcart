{
   oxulibSettings, library mode settings
   Copyright (c) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxulibSettings;

INTERFACE

TYPE
   oxPLibrarySettings = ^oxTLibrarySettings;
   oxTLibrarySettings = record
      {is any of the library mode windows focused}
      Focused: boolean;
   end;

VAR
   oxLibrarySettings: oxTLibrarySettings;

IMPLEMENTATION

END.
