{
   oxugl1Shims, shims for missing gl 1 methods
   Copyright (C) 2021. Dejan Boras

   Because masochism and we can hack this to run on the Windows software gl driver :D
}

{$INCLUDE oxheader.inc}
UNIT oxugl1Shims;

INTERFACE

   USES
      uLog,
      {$INCLUDE usesgl.inc},
      {ox}
      uOX, oxuRunRoutines,
      oxuglRenderer, oxuglRendererInfo;

IMPLEMENTATION

VAR
   initRoutine: oxTRunRoutine;

procedure shimDrawArrays(mode: GLenum; first: GLint; count: GLsizei); {$IFDEF WINDOWS}stdcall; {$ELSE}cdecl; {$ENDIF}
begin

end;

procedure shimDrawElements(mode: GLenum; count: GLsizei; _type: GLenum; const indices: PGLvoid); {$IFDEF WINDOWS}stdcall; {$ELSE}cdecl; {$ENDIF}
begin

end;

procedure initShims();
begin
   if(oxglRendererInfo.Version.Major = 1) and (oxglRendererInfo.Version.Minor = 1) then begin
      glDrawArrays := @shimDrawArrays;
      glDrawElements := @shimDrawElements;

      log.v('gl > Using shims');
   end;
end;

procedure init();
begin
   oxglRenderer.AfterInit.Add(initRoutine, 'shims', @initShims);
end;

INITIALIZATION
   {$IFNDEF OX_LIBRARY}
   ox.PreInit.Add('gl.shims', @init);
   {$ENDIF}

END.
