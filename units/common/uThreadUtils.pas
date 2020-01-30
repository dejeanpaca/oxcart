{
   uThreadUtils, thread helper functionality
   Copyright (C) Dejan Boras 2020.

   Started on:    30.01.2020.
}

{$INCLUDE oxheader.inc}
UNIT uThreadUtils;

INTERFACE

   USES
      classes
      {$IFDEF WINDOWS}
      , windows
      {$ENDIF};

TYPE

   { TThreadUtils }

   TThreadUtils = record
      class procedure SetThreadName({%H-}t: TThread; const name: string); static;
   end;

IMPLEMENTATION

{$IFDEF WINDOWS}
CONST
   MS_VC_EXCEPTION: windows.DWORD = $406D1388;

TYPE
   THREADNAME_INFO = record
      dwType: windows.DWORD; // Must be 0x1000.
      szName: windows.LPCSTR; // Pointer to name (in user addr space).
      dwThreadID: windows.DWORD; // Thread ID (-1=caller thread).
      dwFlags: windows.DWORD; // Reserved for future use, must be zero.
   end;

{ TThreadUtils }

class procedure TThreadUtils.SetThreadName(t: TThread; const name: string);
var
   info: THREADNAME_INFO;

begin
   info.dwType := $1000;
   info.szName := pchar(name);
   info.dwThreadID := t.ThreadID;
   info.dwFlags := 0;

   try
      {raise exception to set thread name, because yay}
      RaiseException(MS_VC_EXCEPTION, 0, sizeof(info) div sizeof(ULONG_PTR), @info);
   except
   end;
end;

{$ELSE}
procedure TThreadUtils.SetThreadName(t: TThread);
begin
end;
{$ENDIF}

END.
