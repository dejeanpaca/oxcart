{
   oxuThreadContext, thread context
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuThreadContext;

INTERFACE

   USES
      {oX}
      oxuMaterial;

TYPE
   oxTThreadContext = class
      Material: oxTMaterial;
   end;

THREADVAR
   oxThreadContext: oxTThreadContext;

IMPLEMENTATION

INITIALIZATION
   oxThreadContext := oxTThreadContext.Create();

END.

