{
   uLinux, input controller handling for Linux
   Copyright (C) 2016. Dejan Boras

   Started On:    15.09.2016.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}{$I-}
UNIT uLinux;

INTERFACE

   USES StringUtils, baseunix, errors;

TYPE

   { appTLinuxHelper }

   appTLinuxHelper = record
   const
      _IOC_NRBITS       = 8;
      _IOC_TYPEBITS     = 8;

      _IOC_SIZEBITS     = 14;
      _IOC_DIRBITS      = 2;

      _IOC_NRMASK       = (1 shl _IOC_NRBITS) - 1;
      _IOC_TYPEMASK     = (1 shl _IOC_TYPEBITS) - 1;
      _IOC_SIZEMASK     = (1 shl _IOC_SIZEBITS) - 1;
      _IOC_DIRMASK      = (1 shl _IOC_DIRBITS) - 1;

      _IOC_NRSHIFT      = 0;
      _IOC_TYPESHIFT    = _IOC_NRSHIFT + _IOC_NRBITS;
      _IOC_SIZESHIFT    = _IOC_TYPESHIFT + _IOC_TYPEBITS;
      _IOC_DIRSHIFT     = _IOC_SIZESHIFT + _IOC_SIZEBITS;

      _IOC_NONE         = 0;
      _IOC_WRITE        = $1;
      _IOC_READ         = $2;

      class function GetErrorString(ErrorCode: cint; includeNumber: boolean = true): string; static;
      class function _ioc(dir, typ, nr, size: cint): cint; static;
      class function _ior(typ, nr, size: cint): cint; static;
      class function _iow(typ, nr, size: cint): cint; static;
      class function _ior(typ: char; nr, size: cint): cint; static;
      class function _iow(typ: char; nr, size: cint): cint; static;
   end;

VAR
   linux: appTLinuxHelper;

IMPLEMENTATION

{ appTLinuxHelper }

class function appTLinuxHelper.GetErrorString(ErrorCode: cint; includeNumber: boolean = true): string;
begin
   if(includeNumber) then
      result := '(' + sf(ErrorCode) + ') ' +StrError(ErrorCode)
   else
      result := StrError(ErrorCode);
end;

class function appTLinuxHelper._ioc(dir, typ, nr, size: cint): cint;
begin
   {$PUSH}{$R-}
   result := ((dir shl _IOC_DIRSHIFT) or
      (typ shl _IOC_TYPESHIFT) or
      (nr shl _IOC_NRSHIFT) or
      (size shl _IOC_SIZESHIFT));
   {$POP}
end;

class function appTLinuxHelper._ior(typ, nr, size: cint): cint;
begin
   result := _ioc(_IOC_READ, typ, nr, size);
end;

class function appTLinuxHelper._iow(typ, nr, size: cint): cint;
begin
   result := _ioc(_IOC_WRITE, typ, nr, size);
end;

class function appTLinuxHelper._ior(typ: char; nr, size: cint): cint;
begin
   result := _ioc(_IOC_READ, ord(typ), nr, size);
end;

class function appTLinuxHelper._iow(typ: char; nr, size: cint): cint;
begin
   result := _ioc(_IOC_WRITE, ord(typ), nr, size);
end;

END.

