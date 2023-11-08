{
   appkRemapCodes.inc, remap codes for various operating systems
   Copyright (C) 2008. Dejan Boras
}

   appkRemapCodes: appTKeyRemapCodes = (
000,
{$IFDEF LINUX}
   {$INCLUDE klRemapCodes.inc}
{$ENDIF}
{$IFDEF WINDOWS}
   {$INCLUDE kwRemapCodes.inc}
{$ENDIF}
{$IFDEF DARWIN}
   {$INCLUDE klRemapCodes.inc}
{$ENDIF}
);
