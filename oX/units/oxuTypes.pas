{
   oxuTypes, common oX data types
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuTypes;

INTERFACE

   USES
      sysutils, uStd, uSimpleList, StringUtils;

TYPE

   { oxTPoint }

   oxTPoint = record
      x,
      y: loopint;

      procedure Assign(nx, ny: loopint);
      class function Make(nx, ny: loopint): oxTPoint; static;
      class function MakeCenterPoint(w, h, w2, h2: loopint): oxTPoint; static;
      class function Null(): oxTPoint; static;

      {distance between another point}
      function Distance(p2: oxTPoint): loopint;

      function ToString(): StdString;
   end;

   { oxTPointf }

   oxTPointf = record
      x,
      y: single;

      procedure Assign(nx, ny: single);
      class function Make(nx, ny: single): oxTPointf; static;
      class function MakeCenterPoint(w, h, w2, h2: single): oxTPointf; static;
      class function Null(): oxTPointf; static;

      {distance between another point}
      function Distance(p2: oxTPointf): single;

      function ToString(decimals: loopint = 0): StdString;
   end;

   { oxTDimensions }

   oxTDimensions = record
      w, h: loopint;

      procedure Assign(nw, nh: loopint);
      class function Make(width, height: loopint): oxTDimensions; static;
      class function Fit(width, width2, height, height2: loopint): oxTDimensions; static;
      class function Null(): oxTDimensions; static;

      {tells if both dimensions have a positive value}
      function IsPositive(): boolean;

      function ToString(): StdString;
   end;

   { oxTDimensionsf }

   oxTDimensionsf = record
      w, h: single;

      procedure Assign(nw, nh: loopint);
      class function Make(width, height: single): oxTDimensionsf; static;
      class function Fit(width, width2, height, height2: single): oxTDimensionsf; static;
      class function Null(): oxTDimensionsf; static;

      {tells if both dimensions have a positive value}
      function IsPositive(): boolean;

      function ToString(decimals: loopint = 0): StdString;
   end;

   { oxTRect }

   oxTRect = record
      x,
      y,
      w,
      h: loopint;

      procedure Assign(nx, ny, nw, nh: loopint);
      procedure Assign(const p: oxTPoint; const d: oxTDimensions);
      class function Make(nx, ny, nw, nh: loopint): oxTRect; static;
      function Inside(px, py: loopint): Boolean;
      {fits another rect inside this one, if can't fit inside it resizes the given rect}
      procedure FitInside(var another: oxTRect);
      {fits another rect inside this one, if it can't fit inside it centers it}
      procedure PositionInside(var another: oxTRect);
   end;

   { oxTRectf }

   oxTRectf = record
      x,
      y,
      w,
      h: single;

      procedure Assign(nx, ny, nw, nh: single);
      procedure Assign(const p: oxTPointf; const d: oxTDimensionsf);
      class function Make(nx, ny, nw, nh: single): oxTRectf; static;
      function Inside(px, py: single): Boolean;

      {fits another rect inside this one, if can't fit inside it resizes the given rect}
      procedure FitInside(var another: oxTRectf);
      {fits another rect inside this one, if it can't fit inside it centers it}
      procedure PositionInside(var another: oxTRectf);
   end;

   oxTProgressIndicatorType = (
      oxPROGRESS_INDICATOR_NONE,
      oxPROGRESS_INDICATOR_RATIO,
      oxPROGRESS_INDICATOR_PERCENTAGE,
      oxPROGRESS_INDICATOR_ITEMS
   );

   { oxTProgressIndicatorData }

   oxTProgressIndicatorData = record
      {show progress as a caption}
      Caption: string;
      {progress as a ratio (from 0 to 1) (negative number means this is not used)}
      Ratio,
      {progress as a percentage (from 0 to 100) (negative number means this is not used)}
      Percentage: single;
      {items currently done (set ShowItems to show in the string)}
      ItemsDone,
      {total items that can be done (if 0 this is not enabled)}
      ItemsTotal: loopint;

      {the progress is paused}
      Paused: boolean;

      {what value to use to show progress with (what would fill up a bar on a progress bar)}
      ShowProgressWith: oxTProgressIndicatorType;
      {show items in text (affects ToString method)}
      ItemsInText,
      {show percentage in text (affects ToString method)}
      PercentageInText,
      {show ratio in text (affects ToString method)}
      RatioInText: boolean;

      procedure SetPercentage(p: single);
      procedure SetRatio(r: single);

      {get a textual representation}
      function ToString(): StdString;
      {initialize record}
      class procedure Init(out p: oxTProgressIndicatorData); static;
   end;

   {base class for any resource}

   { oxTResource }

   oxTResource = class
      Path: StdString;
      ReferenceCount: loopint;
      Pool: TObject;

      {$IFDEF OX_RESOURCE_DEBUG}
      DebugAllocationPoint,
      DebugFreePoint: StdString;
      {mark as freed without actually freeing}
      DebugFreed,
      {are we doing object free from a resource method}
      FreeInResourceMethod: boolean;
      {$ENDIF}

      constructor Create(); virtual;
      destructor Destroy(); override;

      {mark the resource as used (increase the reference count)}
      procedure MarkUsed();
      {mark the resource as permanent (cannot be destroyed via oxResource.Destroy())}
      procedure MarkPermanent();
      {mark resource as unused (decrease the reference count)}
      procedure Unused();

      function AddrToString(): StdString;

      {get normalized path}
      function GetPath(): StdString;

      {get the resource loader for this resource type}
      function GetLoader(): POObject;
   end;

   oxTResourceClass = class of oxTResource;

   oxTSimpleResourceListClass = specialize TSimpleListClass<oxTResource>;

   oxTTextureID = type longword;

   oxTTextureFilter = (
      oxTEXTURE_FILTER_NONE,
      oxTEXTURE_FILTER_LINEAR,
      oxTEXTURE_FILTER_BILINEAR,
      oxTEXTURE_FILTER_TRILINEAR,
      oxTEXTURE_FILTER_ANISOTROPIC
   );

   oxTNormalsMode = (
      oxNORMALS_MODE_NONE,
      oxNORMALS_MODE_PER_POLY,
      oxNORMALS_MODE_PER_VERTEX,
      oxNORMALS_MODE_NORMALIZED_VERTICES
   );

   oxTCullFace = (
      oxCULL_FACE_NONE,
      oxCULL_FACE_BACK,
      oxCULL_FACE_FRONT
   );

   oxTPrimitives = (
      oxPRIMITIVE_NONE,
      oxPRIMITIVE_POINTS,
      oxPRIMITIVE_LINES,
      oxPRIMITIVE_LINE_LOOP,
      oxPRIMITIVE_LINE_STRIP,
      oxPRIMITIVE_TRIANGLES,
      oxPRIMITIVE_TRIANGLE_STRIP,
      oxPRIMITIVE_TRIANGLE_FAN,
      oxPRIMITIVE_QUADS
   );

   oxTTestFunction = (
      oxTEST_FUNCTION_NONE,
      oxTEST_FUNCTION_NEVER,
      oxTEST_FUNCTION_EQUAL,
      oxTEST_FUNCTION_GREATER,
      oxTEST_FUNCTION_GEQUAL,
      oxTEST_FUNCTION_LEQUAL,
      oxTEST_FUNCTION_LESS,
      oxTEST_FUNCTION_ALWAYS
   );

   oxTBlendFunction = (
      oxBLEND_NONE,
      oxBLEND_ALPHA,
      oxBLEND_ADD,
      oxBLEND_SUBTRACT,
      oxBLEND_FILTER
   );

   { TEXTURE TYPE }
   oxTTextureType = (
      oxTEXTURE_1D,
      oxTEXTURE_2D,
      oxTEXTURE_3D
   );

CONST
   oxBLEND_MAX = oxBLEND_FILTER;

   oxrBUFFER_CLEAR_COLOR               = $1;
   oxrBUFFER_CLEAR_DEPTH               = $2;
   oxrBUFFER_CLEAR_STENCIL             = $4;
   oxrBUFFER_CLEAR_ACCUM               = $8;

   oxrBUFFER_CLEAR_NOTHING             = $0;
   oxrBUFFER_CLEAR_DEFAULT             = oxrBUFFER_CLEAR_COLOR or oxrBUFFER_CLEAR_DEPTH;
   oxrBUFFER_CLEAR_ALL                 = oxrBUFFER_CLEAR_COLOR or oxrBUFFER_CLEAR_DEPTH or oxrBUFFER_CLEAR_STENCIL;

   oxNORMALS_MODE_MAX = oxNORMALS_MODE_NORMALIZED_VERTICES;
   oxTEST_FUNCTION_DEFAULT = oxTEST_FUNCTION_LEQUAL;
   oxBLEND_DEFAULT = oxBLEND_ALPHA;
   oxCULL_FACE_DEFAULT = oxCULL_FACE_BACK;

   oxcMAXIMUM_WINDOWS               = 4;
   oxcMAX_WINDOW                    = oxcMAXIMUM_WINDOWS - 1;

   {maximum number of rendering contexts}
   oxMAXIMUM_RENDER_CONTEXTS  = 32;
   oxMAXIMUM_RENDER_CONTEXT   = oxMAXIMUM_RENDER_CONTEXTS - 1;

   oxcCONTEXT_WINDOW_IDX            = -1;


VAR
   oxNullPoint: oxTPoint;
   oxNullDimensions: oxTDimensions;

{return an oxTPoint record with the specified coordinates}
function oxPoint(x, y: loopint): oxTPoint;
{return an oxTDimensions record with the specified width and height}
function oxDimensions(w, h: loopint): oxTDimensions;

IMPLEMENTATION

function oxPoint(x, y: loopint): oxTPoint;
begin
   Result.x := x;
   Result.y := y;
end;

function oxDimensions(w, h: loopint): oxTDimensions;
begin
   Result.w := w;
   Result.h := h;
end;

{ oxTProgressIndicatorData }

procedure oxTProgressIndicatorData.SetPercentage(p: single);
begin
   if(p < 0) then
      p := 0
   else if(p > 100) then
      p := 100;

   Percentage := p;
end;

procedure oxTProgressIndicatorData.SetRatio(r: single);
begin
   if(r < 0) then
      r := 0
   else if(r > 1) then
      r := 1;

   Ratio := r;
end;

function oxTProgressIndicatorData.ToString(): StdString;
var
   s: TAppendableString;

begin
   s := '';

   if(Caption <> '') then
      s := Caption;

   if(Percentage >= 0) and (PercentageInText) then
      s.AddSpaced(sf(Percentage, 0) + '%');

   if(Ratio >= 0) and (RatioInText) then
      s.AddSpaced(sf(Ratio, 2));

   if(ItemsTotal > 0) and (ItemsInText) then
      s.AddSpaced(sf(ItemsDone) + '/' + sf(ItemsTotal));

   Result := s;
end;

class procedure oxTProgressIndicatorData.Init(out p: oxTProgressIndicatorData);
begin
   ZeroPtr(@p, SizeOf(p));
   p.Percentage := -1;
   p.Ratio := -1;
   p.PercentageInText := true;
   p.RatioInText := true;
   p.ShowProgressWith := oxPROGRESS_INDICATOR_ITEMS;
end;

{ oxTResource }

constructor oxTResource.Create();
begin
   {$IFDEF OX_RESOURCE_DEBUG}
   DebugAllocationPoint := DumpCallStack(1);
   {$ENDIF}
   ReferenceCount := 1;
end;

destructor oxTResource.Destroy();
begin
   inherited Destroy;

   {$IFDEF OX_RESOURCE_DEBUG}
   if(ReferenceCount = -1) then
      assert(FreeInResourceMethod, 'Permanent resource object freed outside of resource methods (do not free directly) ' + LineEnding + DebugAllocationPoint)
   else
      assert(FreeInResourceMethod, 'Resource object freed outside of resource methods (do not free directly) ' + LineEnding + DebugAllocationPoint);
   {$ENDIF}
end;

procedure oxTResource.MarkUsed();
begin
   if(ReferenceCount <> -1) then
      Inc(ReferenceCount);
end;

procedure oxTResource.MarkPermanent();
begin
   ReferenceCount := -1;
end;

procedure oxTResource.Unused();
begin
   dec(ReferenceCount);
end;

function oxTResource.AddrToString(): StdString;
begin
   Result := addr2str(Self);
end;

function oxTResource.GetPath(): StdString;
begin
   Result := ExtractFilePath(Path);

   if(Result <> '') then
      Result := IncludeTrailingPathDelimiter(Result);
end;

function oxTResource.GetLoader(): POObject;
begin
   Result := nil;
end;

{ oxTRectf }

procedure oxTRectf.Assign(nx, ny, nw, nh: single);
begin
   x := nx;
   y := ny;
   w := nw;
   h := nh;
end;

procedure oxTRectf.Assign(const p: oxTPointf; const d: oxTDimensionsf);
begin
   self.x := p.x;
   self.y := p.y;
   self.w := d.w;
   self.h := d.h;
end;

class function oxTRectf.Make(nx, ny, nw, nh: single): oxTRectf;
begin
   Result.x := nx;
   Result.y := ny;
   Result.w := nw;
   Result.h := nh;
end;

function oxTRectf.Inside(px, py: single): Boolean;
begin
   Result := (px >= x) and (px < x + w) and (py <= y) and (py > y - h);
end;

procedure oxTRectf.FitInside(var another: oxTRectf);
begin
   { check horizontal }

   if(another.x < self.x) then
      another.x := self.x;

   if(another.x >= self.x + Self.w) then
      another.x := self.x + self.w - another.w;

   { check vertical }

   if(another.y > self.y) then
      another.y := self.y;

   if(another.y <= self.y - Self.h) then
      another.y := self.y - self.h + another.h;

   { if still out of bounds, resize }

   if(another.x < self.x) or (another.x >= self.x + Self.w) or (another.x + another.w >= self.x + self.w) then begin
      another.x := self.x;
      another.w := self.w;
   end;

   if(another.y > self.y) or (another.y <= self.y - Self.h) or (another.y - another.h <= self.y - self.h) then begin
      another.y := self.y;
      another.h := self.h;
   end;
end;

procedure oxTRectf.PositionInside(var another: oxTRectf);
var
   diff: single;

begin
   { check horizontal }

   if(another.x < self.x) then
      another.x := self.x;

   if(another.x >= self.x + Self.w) then
      another.x := self.x + self.w - another.w;

   { check vertical }

   if(another.y > self.y) then
      another.y := self.y;

   if(another.y <= self.y - Self.h) then
      another.y := self.y - self.h + another.h;

   { if still out of bounds, resize }

   if(another.x < self.x) or (another.x >= self.x + Self.w) or (another.x + another.w >= self.x + self.w) then begin
      diff := abs(Self.w - another.w) / 2;

      another.x := self.x - diff;
   end;

   if(another.y > self.y) or (another.y <= self.y - Self.h) or (another.y - another.h <= self.y - self.h) then begin
      diff := abs(Self.h - another.h) / 2;

      another.y := self.y + diff;
   end;
end;

{ oxTDimensionsf }

procedure oxTDimensionsf.Assign(nw, nh: loopint);
begin
   w := nw;
   h := nh;
end;

class function oxTDimensionsf.Make(width, height: single): oxTDimensionsf;
begin
   Result.w := width;
   Result.h := height;
end;

class function oxTDimensionsf.Fit(width, width2, height, height2: single): oxTDimensionsf;
begin
   Result.w := width;
   if width2 < Result.w then
      Result.w := width2;

   Result.h := height;
   if height2 < Result.h then
      Result.h := height2;
end;

class function oxTDimensionsf.Null(): oxTDimensionsf;
begin
   Result.w := 0;
   Result.h := 0;
end;

function oxTDimensionsf.IsPositive(): boolean;
begin
   Result := (w > 0) and (h > 0);
end;

function oxTDimensionsf.ToString(decimals: loopint): StdString;
begin
   Result := sf(w, decimals) + 'x' + sf(h, decimals);
end;

{ oxTPointf }

procedure oxTPointf.Assign(nx, ny: single);
begin
   x := nx;
   y := ny;
end;

class function oxTPointf.Make(nx, ny: single): oxTPointf;
begin
   Result.x := nx;
   Result.y := ny;
end;

class function oxTPointf.MakeCenterPoint(w, h, w2, h2: single): oxTPointf;
var
   cw, ch: single;

begin
   cw := w2 / 2;
   ch := h2 / 2;

   Result.x := cw - (w / 2);
   Result.y := ch + (h / 2);
end;

class function oxTPointf.Null(): oxTPointf;
begin
   Result.x := 0;
   Result.y := 0;
end;

function oxTPointf.Distance(p2: oxTPointf): single;
begin
   Result := abs(p2.x - x) + abs(p2.y - y);
end;

function oxTPointf.ToString(decimals: loopint): StdString;
begin
   Result := sf(x, decimals) + ', ' + sf(y, decimals);
end;

{ oxTPoint }

procedure oxTPoint.Assign(nx, ny: loopint);
begin
   x := nx;
   y := ny;
end;

class function oxTPoint.Make(nx, ny: loopint): oxTPoint;
begin
   Result.x := nx;
   Result.y := ny;
end;

class function oxTPoint.MakeCenterPoint(w, h, w2, h2: loopint): oxTPoint;
var
   cw, ch: loopint;

begin
   cw := w2 div 2;
   ch := h2 div 2;

   Result.x := cw - (w div 2);
   Result.y := ch + (h div 2);
end;

class function oxTPoint.Null(): oxTPoint;
begin
   Result.x := 0;
   Result.y := 0;
end;

function oxTPoint.Distance(p2: oxTPoint): loopint;
begin
   Result := abs(p2.x - x) + abs(p2.y - y);
end;

function oxTPoint.ToString(): StdString;
begin
   Result := sf(x) + 'x' + sf(y);
end;

{ oxTRect }

procedure oxTRect.Assign(nx, ny, nw, nh: loopint);
begin
   x := nx;
   y := ny;
   w := nw;
   h := nh;
end;

procedure oxTRect.Assign(const p: oxTPoint; const d: oxTDimensions);
begin
   self.x := p.x;
   self.y := p.y;
   self.w := d.w;
   self.h := d.h;
end;

class function oxTRect.Make(nx, ny, nw, nh: loopint): oxTRect;
begin
   Result.x := nx;
   Result.y := ny;
   Result.w := nw;
   Result.h := nh;
end;

function oxTRect.Inside(px, py: loopint): Boolean;
begin
   Result := (px >= x) and (px < x + w) and (py <= y) and (py > y - h);
end;

procedure oxTRect.FitInside(var another: oxTRect);
begin
   { check horizontal }

   if(another.x < self.x) then
      another.x := self.x;

   if(another.x >= self.x + Self.w) then
      another.x := self.x + self.w - another.w;

   { check vertical }

   if(another.y > self.y) then
      another.y := self.y;

   if(another.y <= self.y - Self.h) then
      another.y := self.y - self.h + another.h;

   { if still out of bounds, resize }

   if(another.x < self.x) or (another.x >= self.x + Self.w) or (another.x + another.w >= self.x + self.w) then begin
      another.x := self.x;
      another.w := self.w;
   end;

   if(another.y > self.y) or (another.y <= self.y - Self.h) or (another.y - another.h <= self.y - self.h) then begin
      another.y := self.y;
      another.h := self.h;
   end;
end;

procedure oxTRect.PositionInside(var another: oxTRect);
begin
   { check horizontal }

   if(another.x < self.x) then
      another.x := self.x;

   if(another.x >= self.x + Self.w) then
      another.x := self.x + self.w - another.w;

   { check vertical }

   if(another.y > self.y) then
      another.y := self.y;

   if(another.y <= self.y - Self.h) then
      another.y := self.y - self.h + another.h;
end;

{ oxTDimensions }

procedure oxTDimensions.Assign(nw, nh: loopint);
begin
   w := nw;
   h := nh;
end;

class function oxTDimensions.Make(width, height: loopint): oxTDimensions;
begin
   Result.w := width;
   Result.h := height;
end;

class function oxTDimensions.Fit(width, width2, height, height2: loopint): oxTDimensions;
begin
   Result.w := width;
   if width2 < Result.w then
      Result.w := width2;

   Result.h := height;
   if height2 < Result.h then
      Result.h := height2;
end;

class function oxTDimensions.Null(): oxTDimensions;
begin
   Result.w := 0;
   Result.h := 0;
end;

function oxTDimensions.IsPositive(): boolean;
begin
   Result := (w > 0) and (h > 0);
end;

function oxTDimensions.ToString(): StdString;
begin
   Result := sf(w) + 'x' + sf(h);
end;

END.
