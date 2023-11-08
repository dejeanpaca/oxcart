{
   oxurConsoleRender, rendering component
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxurConsoleRender;

INTERFACE

   USES
      uOX, uStd,
      {oX}
      oxuRenderer, oxuRender,
      {con}
      oxuConsoleRenderer;

TYPE

   { oxrconTRender }

   oxrconTRender = class(oxTRender)
   end;

IMPLEMENTATION

VAR
   conRender: oxrconTRender;

function componentReturn(): TObject;
begin
   result := conRender;
end;

procedure init();
begin
   conRender := oxrconTRender.Create();

   oxConsoleRenderer.components.RegisterComponent('render', @componentReturn);
end;

procedure deinit();
begin
   FreeObject(conRender);
end;

INITIALIZATION
   ox.PreInit.Add('ox.con.render', @init, @deinit);

END.
