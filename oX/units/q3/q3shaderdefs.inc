{
   Copyright (c) 2010. Dejan Boras

   Shader definition file for Quake 3 shaders. These definitions may be erroneous or incomplete.
}

cull                       = (SHORTSTRING);
nopicmip                   = (NIL);
nomipmap                   = (NIL);
polygonOffset              = (NIL);
portal                     = (NIL);
sort                       = (SHORTSTRING);
map                        = (SHORTSTRING);
Clampmap                   = (SHORTSTRING);
blendfunc                  = (SHORTSTRING, SHORTSTRING);
blendfunc(add)             = (SHORTSTRING);
blendfunc(blend)           = (SHORTSTRING);
blendfunc(filter)          = (SHORTSTRING);
rgbGen                     = (SHORTSTRING);
{rgbGen wave <func> <base> <amp> <phase> <freq>}
rgbGen(wave)               = (SHORTSTRING, SHORTSTRING, SINGLE, SINGLE, SINGLE, SINGLE);
AlphaGen                   = (SHORTSTRING);
{tcGen <coordinate source>}
tcGen                      = (SHORTSTRING);
tcGen(vector)              = (SHORTSTRING);
depthFunc                  = (SHORTSTRING);
depthWrite                 = (NIL);
Detail                     = (NIL);
alphaFunc                  = (SHORTSTRING);
