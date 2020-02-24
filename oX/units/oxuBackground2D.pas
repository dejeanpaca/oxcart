{
   oxuBackground2D, 2D backgrounds
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuBackground2D;

INTERFACE

   USES
      uStd, vmVector,
      {ox}
      oxumPrimitive, oxuProjection, oxuTexture, oxuTransform, oxuTextureGenerate;

TYPE
   oxTBackground2D = record
      sizex, 
      sizey, 
      px, 
      py, 
      screenx, 
      screeny: single;

      useCorrection, 
      restoreTranslation: boolean;

      Texture: oxTTexture;

      q: oxTPrimitiveModel;
   end;

VAR
   oxDefaultBackground2D: oxTBackground2D;

procedure oxbk2dInit(var bk: oxTBackground2D);
procedure oxbk2dSize(var bk: oxTBackground2D; x, y: single);
procedure oxbk2dMove(var bk: oxTBackground2D; x, y: single);
procedure oxbk2dBuild(var bk: oxTBackground2D);
function oxbk2dTexture(var bk: oxTBackground2D; const fn: string): longint;
procedure oxbk2dRender(var bk: oxTBackground2D);

IMPLEMENTATION

procedure oxbk2dInit(var bk: oxTBackground2D);
begin
   bk := oxDefaultBackground2D;
end;

procedure oxbk2dSize(var bk: oxTBackground2D; x, y: single);
begin
   bk.sizex       := x;
   bk.sizey       := y;
   bk.q.QuadResetVertices();
   bk.q.Scale(x, y, 1.0);
end;

procedure oxbk2dMove(var bk: oxTBackground2D; x, y: single);
begin
   bk.px := x;
   bk.py := y;
end;

function oxbk2dTexture(var bk: oxTBackground2D; const fn: string): longint;
var
   x,
   y: single;
   errcode: longint;

begin
   result   := eNONE;

   errcode  := oxTextureGenerate.Generate(fn, bk.Texture);
   if(errcode <> 0) then
      exit(errcode);

   if(oxTextureGenerate.Image.Width > oxTextureGenerate.Image.Height) then begin
      y     := 1.0;
      x     := oxTextureGenerate.Image.Width / oxTextureGenerate.Image.Height;
   end else begin
      x     := 1.0;
      y     := oxTextureGenerate.Image.Height / oxTextureGenerate.Image.Width;
   end;

   if(x < y) then begin
      if(oxProjection.a.acX > x) then begin
         x  := x * oxProjection.a.acX;
         y  := y * oxProjection.a.acX;
      end;
   end else if(y < x) then begin
      if(oxProjection.a.acY > y) then begin
         x  := x * oxProjection.a.acY;
         y  := y * oxProjection.a.acY;
      end;
   end;

   oxbk2dSize(bk, x, y);
end;

procedure oxbk2dBuild(var bk: oxTBackground2D);
begin
   bk.q.Quad();
end;

procedure oxbk2dRender(var bk: oxTBackground2D);
var
   x, y: single;
   m: TMatrix4f;

begin
   x  := 0.0;
   y  := bk.py * (bk.sizey - bk.screeny);

   m := oxTransform.Matrix;

   oxTransform.Translate(x, y, 0.0);
   oxTransform.Apply();
   bk.q.Render();

   if(bk.restoreTranslation) then
      oxTransform.Apply(m);
end;

INITIALIZATION
   {initialize the default background}
   oxDefaultBackground2D.q.Init();

   with oxDefaultBackground2D do begin
      sizex    := 1.0;
      sizey    := 1.0;
      px       := 0.0;
      py       := 0.0;
      screenx  := 1.0;
      screeny  := 1.0;

      useCorrection        := true;
      restoreTranslation   := true;
   end;

END.
