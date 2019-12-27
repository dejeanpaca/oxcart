{
   vmVector, base VectorMachine unit
   Copyright (C) 2007. Dejan Boras

   Started On:    14.06.2007.

   vmVector is the base unit for VectorMachine, a group of units designed to
   perform math and related operations on vectors and similar data types.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH TYPEHELPERS}
UNIT vmVector;

{$IFNDEF NO_VM_INLINE}
   {$DEFINE VM_INLINE}
{$ENDIF}

{By defining the symbol VM_INLINE all routines will be compiled as inline,
which will increase code size, but improve execution speed of the routines
(almost twice).}

{enable in-line routines if VM_INLINE is defined}
{$IFDEF VM_INLINE}{$INLINE ON}{$ENDIF}

INTERFACE

   USES
      uStd, Math, StringUtils;

CONST
   {PI}
   vmcPi             = 3.1415926535897932384626433832795;
   vmcHalfPi         = 3.1415926535897932384626433832795 / 2;
   vmcToDeg          = 180 / vmcPi;
   vmcToRad          = vmcPi / 180;

   {sphere classification constants}
   vmcBehind         = 0;
   vmcIntersects     = 1;
   vmcFront          = 2;

   {coordinate types}
   vmcXYZ            = 0000;
   vmcXZY            = 0001;

TYPE
   generic TVector2g<T> = array[0..1] of T;
   generic TVector3g<T> = array[0..2] of T;
   generic TVector4g<T> = array[0..3] of T;

   {VECTOR TYPES}
   {byte}
   PVector2ub = ^TVector2ub;
   TVector2ub = specialize TVector2g<byte>;
   PVector3ub = ^TVector3ub;
   TVector3ub = specialize TVector3g<byte>;
   PVector4ub = ^TVector4ub;
   TVector4ub = specialize TVector4g<byte>;

   {shortint}
   PVector2b = ^TVector2b;
   TVector2b = specialize TVector2g<shortint>;
   PVector3b = ^TVector3b;
   TVector3b = specialize TVector3g<shortint>;
   PVector4b = ^TVector4b;
   TVector4b = specialize TVector4g<shortint>;

   {smallint}
   PVector2s = ^TVector2s;
   TVector2s = specialize TVector2g<smallint>;
   PVector3s = ^TVector3s;
   TVector3s = specialize TVector3g<smallint>;
   PVector4s = ^TVector4s;
   TVector4s = specialize TVector4g<smallint>;

   {word}
   PVector2us = ^TVector2us;
   TVector2us = specialize TVector2g<word>;
   PVector3us = ^TVector3us;
   TVector3us = specialize TVector3g<word>;
   PVector4us = ^TVector4us;
   TVector4us = specialize TVector4g<word>;

   {longint}
   PVector2i = ^TVector2i;
   TVector2i = specialize TVector2g<longint>;
   PVector3i = ^TVector3i;
   TVector3i = specialize TVector3g<longint>;
   PVector4i = ^TVector4i;
   TVector4i = specialize TVector4g<longint>;

   {longword}
   PVector2ui = ^TVector2ui;
   TVector2ui = specialize TVector2g<longword>;
   PVector3ui = ^TVector3ui;
   TVector3ui = specialize TVector3g<longword>;
   PVector4ui = ^TVector4ui;
   TVector4ui = specialize TVector4g<longword>;

   {floating point, single precision}
   PVector2f = ^TVector2f;
   TVector2f = specialize TVector2g<single>;
   PVector3f = ^TVector3f;
   TVector3f = specialize TVector3g<single>;
   PVector4f = ^TVector4f;
   TVector4f = specialize TVector4g<single>;

   {floating point, double precision}
   PVector2d = ^TVector2d;
   TVector2d = specialize TVector2g<double>;
   PVector3d = ^TVector3d;
   TVector3d = specialize TVector3g<double>;
   PVector4d = ^TVector4d;
   TVector4d = specialize TVector4g<double>;

   {floating point, extended}
   PVector2e = ^TVector2e;
   TVector2e = specialize TVector2g<extended>;
   PVector3e = ^TVector3e;
   TVector3e = specialize TVector3g<extended>;
   PVector4e = ^TVector4e;
   TVector4e = specialize TVector4g<extended>;

   {standard, default types = single precision floating point}
   PVector2 = ^TVector2;
   TVector2 = TVector2f;
   PVector3 = ^TVector3;
   TVector3 = TVector3f;
   PVector4 = ^TVector4;
   TVector4 = TVector4f;

   {MATRIX TYPES}
   {byte, unsigned byte}
   TMatrix2ub = array[0..1, 0..1] of byte;
   TMatrix3ub = array[0..2, 0..2] of byte;
   TMatrix4ub = array[0..3, 0..3] of byte;

   {shortint, unsigned byte}
   TMatrix2b = array[0..1, 0..1] of shortint;
   TMatrix3b = array[0..2, 0..2] of shortint;
   TMatrix4b = array[0..3, 0..3] of shortint;

   {word}
   TMatrix2us = array[0..1, 0..1] of word;
   TMatrix3us = array[0..2, 0..2] of word;
   TMatrix4us = array[0..3, 0..3] of word;

   {smallint}
   TMatrix2s = array[0..1, 0..1] of smallint;
   TMatrix3s = array[0..2, 0..2] of smallint;
   TMatrix4s = array[0..3, 0..3] of smallint;

   {longword}
   TMatrix2ui = array[0..1, 0..1] of longword;
   TMatrix3ui = array[0..2, 0..2] of longword;
   TMatrix4ui = array[0..3, 0..3] of longword;

   {longint}
   TMatrix2i = array[0..1, 0..1] of longint;
   TMatrix3i = array[0..2, 0..2] of longint;
   TMatrix4i = array[0..3, 0..3] of longint;


   {floating point, single precision}
   PMatrix2f = ^TMatrix2f;
   TMatrix2f = array[0..1, 0..1] of single;
   PMatrix3f = ^TMatrix3f;
   TMatrix3f = array[0..2, 0..2] of single;
   PMatrix4f = ^TMatrix4f;
   TMatrix4f = array[0..3, 0..3] of single;

   {floating point, double precision}
   PMatrix2d = ^TMatrix2d;
   TMatrix2d = array[0..1, 0..1] of double;
   PMatrix3d = ^TMatrix3d;
   TMatrix3d = array[0..2, 0..2] of double;
   PMatrix4d = ^TMatrix4d;
   TMatrix4d = array[0..3, 0..3] of double;

   {floating point, extended}
   PMatrix2e = ^TMatrix2e;
   TMatrix2e = array[0..1, 0..1] of extended;
   PMatrix3e = ^TMatrix3e;
   TMatrix3e = array[0..2, 0..2] of extended;
   PMatrix4e = ^TMatrix4e;
   TMatrix4e = array[0..3, 0..3] of extended;

   {standard, default types = single precision floating point}
   PMatrix2 = PMatrix2f;
   TMatrix2 = TMatrix2f;
   PMatrix3 = PMatrix3f;
   TMatrix3 = TMatrix3f;
   PMatrix4 = PMatrix4f;
   TMatrix4 = TMatrix4f;

   {bounding boxes}
   TBoundingBoxub    = array[0..1] of TVector3ub;
   TBoundingBoxb     = array[0..1] of TVector3b;
   TBoundingBoxus    = array[0..1] of TVector3us;
   TBoundingBoxs     = array[0..1] of TVector3s;
   TBoundingBoxui    = array[0..1] of TVector3ui;
   TBoundingBoxi     = array[0..1] of TVector3i;

   TBoundingBoxf     = array[0..1] of TVector3f;
   TBoundingBoxd     = array[0..1] of TVector3d;

   TBoundingBox      = TBoundingBoxf;

TYPE

   { TVector2Helper }

   TVector2Helper = type helper for TVector2
      procedure Normalize(); {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Normalized(): TVector2; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Magnitude(): single; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      procedure Negative(); {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Length(): single; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Dot(v: TVector2): single; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Distance(v: TVector2): single; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Equal(v: TVector2; epsilon: single): boolean; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      procedure Assign(x, y: single); {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function ToString(decimals: loopint = 0; const separator: string = ','): string;
      class function Create(x, y: single): TVector2; static; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
   end;

   { TVector3Helper }

   TVector3Helper = type helper for TVector3
      procedure Normalize(); {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Normalized(): TVector3; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Magnitude(): single; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      procedure Negative(); {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Length(): single; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Cross(v: TVector3): TVector3; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Dot(v: TVector3): single; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Distance(v: TVector3): single; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Equal(v: TVector3; epsilon: single): boolean; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      procedure Assign(x, y, z: single); {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function ToString(decimals: loopint = 0; const separator: string = ','): string;
      class function Create(x, y, z: single): TVector3; static; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
   end;

   { TVector4Helper }

   TVector4Helper = type helper for TVector4
      procedure Normalize(); {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Normalized(): TVector4; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Magnitude(): single; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      procedure Negative(); {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Length(): single; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Dot(v: TVector4): single; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Distance(v: TVector4): single; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Equal(v: TVector4; epsilon: single): boolean; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      procedure Assign(x, y, z, w: single); {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function ToString(decimals: loopint = 0; const separator: string = ','): string;
      class function Create(x, y, z, w: single): TVector4; static; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
   end;

   { TVector2iHelper }

   TVector2iHelper = type helper for TVector2i
      function ToString(const separator: string = ','): string;
   end;

   { TVector3iHelper }

   TVector3iHelper = type helper for TVector3i
      function ToString(const separator: string = ','): string;
   end;

   { TVector4iHelper }

   TVector4iHelper = type helper for TVector4i
      function ToString(const separator: string = ','): string;
   end;

   { TMatrix4Helper }

   TMatrix2Helper = type helper for TMatrix2
      function Transposed(): TMatrix2; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
   end;

   TMatrix3Helper = type helper for TMatrix3
      function Transposed(): TMatrix3; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
   end;

   TMatrix4Helper = type helper for TMatrix4
      function Transposed(): TMatrix4; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function Inversed(): TMatrix4; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
      function GetDeterminant(): single; {$IFDEF VM_INLINE_HELPERS}inline;{$ENDIF}
   end;

   { TBoundingBoxHelper }

   TBoundingBoxHelper = type helper for TBoundingBox
      {tells if bounding box dimensions are 0 (all points are 0)}
      function IsZero(): boolean;

      procedure AssignPoint(const p: TVector3f; size: Single);
      procedure AssignPoint(const x, y, z: single; size: Single);
   end;

CONST
   {zero vectors}
   vmvZero2: TVector2            = (0.0, 0.0);
   vmvZero3: TVector3            = (0.0, 0.0, 0.0);
   vmvZero4: TVector4            = (0.0, 0.0, 0.0, 0.0);

   vmvZero2b: TVector2b          = (0, 0);
   vmvZero3b: TVector3b          = (0, 0, 0);
   vmvZero4b: TVector4b          = (0, 0, 0, 0);

   vmvZero2ub: TVector2ub        = (0, 0);
   vmvZero3ub: TVector3ub        = (0, 0, 0);
   vmvZero4ub: TVector4ub        = (0, 0, 0, 0);

   vmvZero2s: TVector2s          = (0, 0);
   vmvZero3s: TVector3s          = (0, 0, 0);
   vmvZero4s: TVector4s          = (0, 0, 0, 0);

   vmvZero2us: TVector2us        = (0, 0);
   vmvZero3us: TVector3us        = (0, 0, 0);
   vmvZero4us: TVector4us        = (0, 0, 0, 0);

   vmvZero2i: TVector2i          = (0, 0);
   vmvZero3i: TVector3i          = (0, 0, 0);
   vmvZero4i: TVector4i          = (0, 0, 0, 0);

   vmvZero2ui: TVector2ui        = (0, 0);
   vmvZero3ui: TVector3ui        = (0, 0, 0);
   vmvZero4ui: TVector4ui        = (0, 0, 0, 0);

   vmvZero2f: TVector2f          = (0.0, 0.0);
   vmvZero3f: TVector3f          = (0.0, 0.0, 0.0);
   vmvZero4f: TVector4f          = (0.0, 0.0, 0.0, 0.0);

   vmvZero2d: TVector2d          = (0.0, 0.0);
   vmvZero3d: TVector3d          = (0.0, 0.0, 0.0);
   vmvZero4d: TVector4d          = (0.0, 0.0, 0.0, 0.0);

   vmvZero2e: TVector2e          = (0.0, 0.0);
   vmvZero3e: TVector3e          = (0.0, 0.0, 0.0);
   vmvZero4e: TVector4e          = (0.0, 0.0, 0.0, 0.0);

   {unit vectors}
   vmvUnit2: TVector2            = (1.0, 0.0);
   vmvUnit3: TVector3            = (1.0, 0.0, 0.0);
   vmvUnit4: TVector4            = (1.0, 0.0, 0.0, 0.0);

   vmvUnit2b: TVector2b          = (1, 0);
   vmvUnit3b: TVector3b          = (1, 0, 0);
   vmvUnit4b: TVector4b          = (1, 0, 0, 0);

   vmvUnit2ub: TVector2ub        = (1, 0);
   vmvUnit3ub: TVector3ub        = (1, 0, 0);
   vmvUnit4ub: TVector4ub        = (1, 0, 0, 0);

   vmvUnit2s: TVector2s          = (1, 0);
   vmvUnit3s: TVector3s          = (1, 0, 0);
   vmvUnit4s: TVector4s          = (1, 0, 0, 0);

   vmvUnit2us: TVector2us        = (1, 0);
   vmvUnit3us: TVector3us        = (1, 0, 0);
   vmvUnit4us: TVector4us        = (1, 0, 0, 0);

   vmvUnit2i: TVector2i          = (1, 0);
   vmvUnit3i: TVector3i          = (1, 0, 0);
   vmvUnit4i: TVector4i          = (1, 0, 0, 0);

   vmvUnit2ui: TVector2ui        = (1, 0);
   vmvUnit3ui: TVector3ui        = (1, 0, 0);
   vmvUnit4ui: TVector4ui        = (1, 0, 0, 0);

   vmvUnit2f: TVector2f          = (1.0, 0.0);
   vmvUnit3f: TVector3f          = (1.0, 0.0, 0.0);
   vmvUnit4f: TVector4f          = (1.0, 0.0, 0.0, 0.0);

   vmvUnit2d: TVector2d          = (1.0, 0.0);
   vmvUnit3d: TVector3d          = (1.0, 0.0, 0.0);
   vmvUnit4d: TVector4d          = (1.0, 0.0, 0.0, 0.0);

   vmvUnit2e: TVector2e          = (1.0, 0.0);
   vmvUnit3e: TVector3e          = (1.0, 0.0, 0.0);
   vmvUnit4e: TVector4e          = (1.0, 0.0, 0.0, 0.0);

   {One vectors}
   vmvOne2: TVector2             = (1.0, 1.0);
   vmvOne3: TVector3             = (1.0, 1.0, 1.0);
   vmvOne4: TVector4             = (1.0, 1.0, 1.0, 1.0);

   vmvOne2b: TVector2b           = (1, 0);
   vmvOne3b: TVector3b           = (1, 0, 0);
   vmvOne4b: TVector4b           = (1, 0, 0, 0);

   vmvOne2ub: TVector2ub         = (1, 0);
   vmvOne3ub: TVector3ub         = (1, 0, 0);
   vmvOne4ub: TVector4ub         = (1, 0, 0, 0);

   vmvOne2s: TVector2s           = (1, 0);
   vmvOne3s: TVector3s           = (1, 0, 0);
   vmvOne4s: TVector4s           = (1, 0, 0, 0);

   vmvOne2us: TVector2us         = (1, 0);
   vmvOne3us: TVector3us         = (1, 0, 0);
   vmvOne4us: TVector4us         = (1, 0, 0, 0);

   vmvOne2i: TVector2i           = (1, 0);
   vmvOne3i: TVector3i           = (1, 0, 0);
   vmvOne4i: TVector4i           = (1, 0, 0, 0);

   vmvOne2ui: TVector2ui         = (1, 0);
   vmvOne3ui: TVector3ui         = (1, 0, 0);
   vmvOne4ui: TVector4ui         = (1, 0, 0, 0);

   vmvOne2f: TVector2f           = (1.0, 1.0);
   vmvOne3f: TVector3f           = (1.0, 1.0, 1.0);
   vmvOne4f: TVector4f           = (1.0, 1.0, 1.0, 1.0);

   vmvOne2d: TVector2d           = (1.0, 1.0);
   vmvOne3d: TVector3d           = (1.0, 1.0, 1.0);
   vmvOne4d: TVector4d           = (1.0, 1.0, 1.0, 1.0);

   vmvOne2e: TVector2e           = (1.0, 1.0);
   vmvOne3e: TVector3e           = (1.0, 1.0, 1.0);
   vmvOne4e: TVector4e           = (1.0, 1.0, 1.0, 1.0);

   {view vectors}
   vmvUp: TVector3               = (0.0, 1.0, 0.0);
   vmvDown: TVector3             = (0.0,-1.0, 0.0);

   vmvLeft: TVector3             = ( 1.0, 0.0, 0.0);
   vmvRight: TVector3            = (-1.0, 0.0, 0.0);

   vmvForward: TVector3          = (0.0, 0.0, 1.0);
   vmvBack: TVector3             = (0.0, 0.0,-1.0);

   {zero matrices}
   vmmZero2: TMatrix2 = (
      (0, 0),
      (0, 0)
   );

   vmmZero3: TMatrix3 = (
      (0, 0, 0),
      (0, 0, 0),
      (0, 0, 0)
   );

   vmmZero4: TMatrix4 = (
      (0, 0, 0, 0),
      (0, 0, 0, 0),
      (0, 0, 0, 0),
      (0, 0, 0, 0)
   );

   {unit matrices}
   vmmUnit2: TMatrix2 = (
      (1, 0),
      (0, 1)
   );

   vmmUnit3: TMatrix3 = (
      (1, 0, 0),
      (0, 1, 0),
      (0, 0, 1)
   );

   vmmUnit4: TMatrix4 = (
      (1, 0, 0, 0),
      (0, 1, 0, 0),
      (0, 0, 1, 0),
      (0, 0, 0, 1)
   );

   vmBBoxZero: TBoundingBox = (
      (0, 0, 0), 
      (0, 0, 0)
   );

   vmBBoxUnit: TBoundingBox = (
      (0.5, 0.5, 0.5),
      (-0.5, -0.5, -0.5)
   );

   { VECTOR MATH ROUTINES }

{creates a vector and returns it}
function vmCreate(const a, b: byte): TVector2ub; inline;
function vmCreate(const a, b: shortint): TVector2b; inline;
function vmCreate(const a, b: word): TVector2us; inline;
function vmCreate(const a, b: smallint): TVector2s; inline;
function vmCreate(const a, b: longword): TVector2ui; inline;
function vmCreate(const a, b: longint): TVector2i; inline;
function vmCreate(const a, b: single): TVector2f; inline;
function vmCreate(const a, b: double): TVector2d; inline;

function vmCreate(const a, b, c: byte): TVector3ub; inline;
function vmCreate(const a, b, c: shortint): TVector3b; inline;
function vmCreate(const a, b, c: word): TVector3us; inline;
function vmCreate(const a, b, c: smallint): TVector3s; inline;
function vmCreate(const a, b, c: longword): TVector3ui; inline;
function vmCreate(const a, b, c: longint): TVector3i; inline;
function vmCreate(const a, b, c: single): TVector3f; inline;
function vmCreate(const a, b, c: double): TVector3d; inline;

function vmCreate(const a, b, c, d: byte): TVector4ub; inline;
function vmCreate(const a, b, c, d: shortint): TVector4b; inline;
function vmCreate(const a, b, c, d: word): TVector4us; inline;
function vmCreate(const a, b, c, d: smallint): TVector4s; inline;
function vmCreate(const a, b, c, d: longword): TVector4ui; inline;
function vmCreate(const a, b, c, d: longint): TVector4i; inline;
function vmCreate(const a, b, c, d: single): TVector4f; inline;
function vmCreate(const a, b, c, d: double): TVector4d; inline;

{other vector operations}

procedure vmCross(out ox, oy, oz: single; a,b,c,x,y,z: single);

{returns a triple scalar product}
function vmTripleScalar(const v1, v2, v3: TVector3): single;

procedure vmNormalize(var x, y, z: single);

{calculates the normal of a polygon}
function vmNormal(var Poly: array of TVector3): TVector3;
{return the normal of 3 sided polygon(aka triangle)}
function vmNormal(const v1, v2, v3: TVector3): TVector3; {$IFDEF VM_INLINE}inline;{$ENDIF}

{figure out the closes point on line}
function vmClosestPointOnLine(const v1, v2, vPoint: TVector3): TVector3; {$IFDEF VM_INLINE}inline;{$ENDIF}
{returns the distance of an plane(as determined by it's normal) from a point}
function vmPlaneDistance(const normal, point: TVector3): single; {$IFDEF VM_INLINE}inline;{$ENDIF}

{ ANGLE ROUTINES }

{return angle between two vectors}
function vmAngle(const v1, v2: TVector2): double; {$IFDEF VM_INLINE}inline;{$ENDIF}
function vmAngle(const v1, v2: TVector3): double; {$IFDEF VM_INLINE}inline;{$ENDIF}
function vmAngle(const v1, v2: TVector4): double; {$IFDEF VM_INLINE}inline;{$ENDIF}
{return the angle between moving vectors}
function vmxAngle(const v1, v2: TVector2): double; {$IFDEF VM_INLINE}inline;{$ENDIF}
function vmxAngle(const v1, v2: TVector3): double; {$IFDEF VM_INLINE}inline;{$ENDIF}
function vmxAngle(const v1, v2: TVector4): double; {$IFDEF VM_INLINE}inline;{$ENDIF}

{rotate a vector around an arbitrary point}
procedure vmRotateAroundPoint(angle, x, y, z: single; point: TVector3;
      var vector: TVector3); {$IFDEF VM_INLINE}inline;{$ENDIF}

{ SPHERE }

{convert a vector given in sphere coordinates to cartesian coordinates}
procedure vmSphereToCartesian(r, phi, theta: single; out c: TVector3f); {$IFDEF VM_INLINE}inline;{$ENDIF}

{ VECTOR OPERATIONS }
{changes source coordinate type to destination coordinate type}
procedure vmSwapCoords(src, dst: longint; var v: TVector3f; n: longint);
{left to right coordinate swap}
procedure vmLTR(var v: TVector3f; n: longint);

{scales an array of vectors}
procedure vmScale(var v: TVector2f; n: longint; scale: single);
procedure vmScale(var v: TVector3f; n: longint; scale: single);
procedure vmScale(var v: TVector4f; n: longint; scale: single);

procedure vmScale(var v: TVector2f; n: longint; x, y: single);
procedure vmScale(var v: TVector3f; n: longint; x, y, z: single);
procedure vmScale(var v: TVector4f; n: longint; x, y, z, w: single);

{offset an array of vectors}
procedure vmOffset(var v: TVector2f; n: longint; x, y: single);
procedure vmOffset(var v: TVector3f; n: longint; x, y, z: single);
procedure vmOffset(var v: TVector4f; n: longint; x, y, z, w: single);

{ DIRECTION }
function vmDirectionAB(const a, b: TVector3f): TVector3f;

{ OPERATOR OVERLOAD }

{ VECTOR/VECTOR OPERATIONS }

{SHORT (SMALLINT)}

operator + (const v1, v2: TVector2s): TVector2s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1, v2: TVector3s): TVector3s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1, v2: TVector4s): TVector4s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1, v2: TVector2s): TVector2s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1, v2: TVector3s): TVector3s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1, v2: TVector4s): TVector4s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1, v2: TVector2s): TVector2s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1, v2: TVector3s): TVector3s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1, v2: TVector4s): TVector4s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1, v2: TVector2s): TVector2s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1, v2: TVector3s): TVector3s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1, v2: TVector4s): TVector4s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

{UNSIGNED SHORT (WORD)}

operator + (const v1, v2: TVector2us): TVector2us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1, v2: TVector3us): TVector3us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1, v2: TVector4us): TVector4us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1, v2: TVector2us): TVector2us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1, v2: TVector3us): TVector3us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1, v2: TVector4us): TVector4us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1, v2: TVector2us): TVector2us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1, v2: TVector3us): TVector3us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1, v2: TVector4us): TVector4us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1, v2: TVector2us): TVector2us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1, v2: TVector3us): TVector3us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1, v2: TVector4us): TVector4us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

{INTEGER (LONGINT)}

operator + (const v1, v2: TVector2i): TVector2i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1, v2: TVector3i): TVector3i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1, v2: TVector4i): TVector4i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1, v2: TVector2i): TVector2i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1, v2: TVector3i): TVector3i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1, v2: TVector4i): TVector4i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1, v2: TVector2i): TVector2i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1, v2: TVector3i): TVector3i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1, v2: TVector4i): TVector4i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1, v2: TVector2i): TVector2i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1, v2: TVector3i): TVector3i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1, v2: TVector4i): TVector4i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

{UNSIGNED INTEGER (LONGWORD)}

operator + (const v1, v2: TVector2ui): TVector2ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1, v2: TVector3ui): TVector3ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1, v2: TVector4ui): TVector4ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1, v2: TVector2ui): TVector2ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1, v2: TVector3ui): TVector3ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1, v2: TVector4ui): TVector4ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1, v2: TVector2ui): TVector2ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1, v2: TVector3ui): TVector3ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1, v2: TVector4ui): TVector4ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1, v2: TVector2ui): TVector2ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1, v2: TVector3ui): TVector3ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1, v2: TVector4ui): TVector4ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

{SINGLE}

operator + (const v1, v2: TVector2f): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1, v2: TVector3f): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1, v2: TVector4f): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1, v2: TVector2f): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1, v2: TVector3f): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1, v2: TVector4f): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1, v2: TVector2f): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1, v2: TVector3f): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1, v2: TVector4f): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1, v2: TVector2f): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1, v2: TVector3f): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1, v2: TVector4f): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

{DOUBLE}

operator + (const v1, v2: TVector2d): TVector2d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1, v2: TVector3d): TVector3d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1, v2: TVector4d): TVector4d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1, v2: TVector2d): TVector2d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1, v2: TVector3d): TVector3d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1, v2: TVector4d): TVector4d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1, v2: TVector2d): TVector2d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1, v2: TVector3d): TVector3d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1, v2: TVector4d): TVector4d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1, v2: TVector2d): TVector2d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1, v2: TVector3d): TVector3d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1, v2: TVector4d): TVector4d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

{ VECTOR/SCALAR OPERATIONS }

{SHORT (SMALLINT)}

operator + (const v1: TVector2s; const scalar: smallint): TVector2s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector3s; const scalar: smallint): TVector3s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector4s; const scalar: smallint): TVector4s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector2s; const scalar: smallint): TVector2s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector3s; const scalar: smallint): TVector3s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector4s; const scalar: smallint): TVector4s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

operator * (const v1: TVector2s; const scalar: smallint): TVector2s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector3s; const scalar: smallint): TVector3s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector4s; const scalar: smallint): TVector4s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector2s; const scalar: smallint): TVector2s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector3s; const scalar: smallint): TVector3s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector4s; const scalar: smallint): TVector4s; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

{UNSIGNED SHORT (WORD)}

operator + (const v1: TVector2us; const scalar: word): TVector2us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector3us; const scalar: word): TVector3us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector4us; const scalar: word): TVector4us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector2us; const scalar: word): TVector2us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector3us; const scalar: word): TVector3us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector4us; const scalar: word): TVector4us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

operator * (const v1: TVector2us; const scalar: word): TVector2us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector3us; const scalar: word): TVector3us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector4us; const scalar: word): TVector4us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector2us; const scalar: word): TVector2us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector3us; const scalar: word): TVector3us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector4us; const scalar: word): TVector4us; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

{INTEGER (LONGINT)}

operator + (const v1: TVector2i; const scalar: longint): TVector2i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector3i; const scalar: longint): TVector3i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector4i; const scalar: longint): TVector4i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector2i; const scalar: longint): TVector2i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector3i; const scalar: longint): TVector3i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector4i; const scalar: longint): TVector4i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

operator * (const v1: TVector2i; const scalar: longint): TVector2i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector3i; const scalar: longint): TVector3i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector4i; const scalar: longint): TVector4i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector2i; const scalar: longint): TVector2i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector3i; const scalar: longint): TVector3i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector4i; const scalar: longint): TVector4i; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

{UNSIGNED INTEGER (LONGWORD)}

operator + (const v1: TVector2ui; const scalar: longword): TVector2ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector3ui; const scalar: longword): TVector3ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector4ui; const scalar: longword): TVector4ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector2ui; const scalar: longword): TVector2ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector3ui; const scalar: longword): TVector3ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector4ui; const scalar: longword): TVector4ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}


operator * (const v1: TVector2ui; const scalar: longword): TVector2ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector3ui; const scalar: longword): TVector3ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector4ui; const scalar: longword): TVector4ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector2ui; const scalar: longword): TVector2ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector3ui; const scalar: longword): TVector3ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector4ui; const scalar: longword): TVector4ui; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

{SHORT (SMALLINT) / SINGLE}

operator + (const v1: TVector2s; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector3s; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector4s; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector2s; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector3s; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector4s; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}


operator * (const v1: TVector2s; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector3s; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector4s; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector2s; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector3s; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector4s; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

{UNSIGNED SHORT (WORD) / SINGLE}

operator + (const v1: TVector2us; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector3us; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector4us; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector2us; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector3us; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector4us; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}


operator * (const v1: TVector2us; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector3us; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector4us; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector2us; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector3us; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector4us; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

{INTEGER (INT32) / SINGLE}

operator + (const v1: TVector2i; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector3i; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector4i; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector2i; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector3i; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector4i; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

operator * (const v1: TVector2i; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector3i; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector4i; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector2i; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector3i; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector4i; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

{UNSIGNED INTEGER (LONGWORD) / SINGLE}

operator + (const v1: TVector2ui; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector3ui; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector4ui; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector2ui; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector3ui; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector4ui; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

operator * (const v1: TVector2ui; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector3ui; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector4ui; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector2ui; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector3ui; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector4ui; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

{SINGLE}

operator + (const v1: TVector2f; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector3f; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector4f; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector2f; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector3f; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector4f; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

operator * (const v1: TVector2f; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector3f; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector4f; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector2f; const scalar: single): TVector2f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector3f; const scalar: single): TVector3f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector4f; const scalar: single): TVector4f; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

{DOUBLE}

operator + (const v1: TVector2d; const scalar: double): TVector2d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector3d; const scalar: double): TVector3d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator + (const v1: TVector4d; const scalar: double): TVector4d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector2d; const scalar: double): TVector2d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector3d; const scalar: double): TVector3d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator - (const v1: TVector4d; const scalar: double): TVector4d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector2d; const scalar: double): TVector2d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector3d; const scalar: double): TVector3d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator * (const v1: TVector4d; const scalar: double): TVector4d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector2d; const scalar: double): TVector2d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector3d; const scalar: double): TVector3d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}
operator / (const v1: TVector4d; const scalar: double): TVector4d; {$IFDEF VM_OPERATOR_INLINE}inline;{$ENDIF}

{ MATRIX }

operator * (const m1: TMatrix2f; const m2: TMatrix2f): TMatrix2f;
operator * (const m1: TMatrix3f; const m2: TMatrix3f): TMatrix3f;
operator * (const m1: TMatrix4f; const m2: TMatrix4f): TMatrix4f;

operator * (const m1: TMatrix4f; const v: TVector3f): TVector3f;
operator * (const m1: TMatrix4f; const v: TVector4f): TVector4f;

IMPLEMENTATION

{ VECTOR MATH ROUTINES }

{TVector2*}
function vmCreate(const a, b: byte): TVector2ub; inline;
{$INCLUDE operators/create2.inc}

function vmCreate(const a, b: shortint): TVector2b; inline;
{$INCLUDE operators/create2.inc}

function vmCreate(const a, b: word): TVector2us; inline;
{$INCLUDE operators/create2.inc}

function vmCreate(const a, b: smallint): TVector2s; inline;
{$INCLUDE operators/create2.inc}

function vmCreate(const a, b: longword): TVector2ui; inline;
{$INCLUDE operators/create2.inc}

function vmCreate(const a, b: longint): TVector2i; inline;
{$INCLUDE operators/create2.inc}

function vmCreate(const a, b: single): TVector2f; inline;
{$INCLUDE operators/create2.inc}

function vmCreate(const a, b: double): TVector2d; inline;
{$INCLUDE operators/create2.inc}

{TVector3*}
function vmCreate(const a, b, c: byte): TVector3ub; inline;
{$INCLUDE operators/create3.inc}

function vmCreate(const a, b, c: shortint): TVector3b; inline;
{$INCLUDE operators/create3.inc}

function vmCreate(const a, b, c: word): TVector3us; inline;
{$INCLUDE operators/create3.inc}

function vmCreate(const a, b, c: smallint): TVector3s; inline;
{$INCLUDE operators/create3.inc}

function vmCreate(const a, b, c: longword): TVector3ui; inline;
{$INCLUDE operators/create3.inc}

function vmCreate(const a, b, c: longint): TVector3i; inline;
{$INCLUDE operators/create3.inc}

function vmCreate(const a, b, c: single): TVector3f; inline;
{$INCLUDE operators/create3.inc}

function vmCreate(const a, b, c: double): TVector3d; inline;
{$INCLUDE operators/create3.inc}

{TVector4*}

function vmCreate(const a, b, c, d: byte): TVector4ub; inline;
{$INCLUDE operators/create4.inc}

function vmCreate(const a, b, c, d: shortint): TVector4b; inline;
{$INCLUDE operators/create4.inc}

function vmCreate(const a, b, c, d: word): TVector4us; inline;
{$INCLUDE operators/create4.inc}

function vmCreate(const a, b, c, d: smallint): TVector4s; inline;
{$INCLUDE operators/create4.inc}

function vmCreate(const a, b, c, d: longword): TVector4ui; inline;
{$INCLUDE operators/create4.inc}

function vmCreate(const a, b, c, d: longint): TVector4i; inline;
{$INCLUDE operators/create4.inc}

function vmCreate(const a, b, c, d: single): TVector4f; inline;
{$INCLUDE operators/create4.inc}

function vmCreate(const a, b, c, d: double): TVector4d; inline;
{$INCLUDE operators/create4.inc}


procedure vmCross(out ox, oy, oz: single; a,b,c,x,y,z: single);
begin
   ox := b * z - y * c;
   oy := c * x - z * a;
   oz := a * y - x * b;
end;

function vmTripleScalar(const v1, v2, v3: TVector3): single;
begin
   Result := (v1[0] *( v2[1] * v3[2] - v2[2] * v3[1])) +
        (v1[1] *(-v2[0] * v3[2] + v2[2] * v3[0])) +
        (v1[2] *( v2[0] * v3[1] - v2[1] * v3[0]));
end;

procedure vmNormalize(var x, y, z: single);
var
   mag: single;

begin
   mag   := sqrt(x * x + y * y + z * z);
   x     := x / mag;
   y     := y / mag;
   z     := z / mag;
end;

function vmNormal(var Poly: array of TVector3): TVector3;
begin
   Result := (Poly[2] - Poly[0]).Cross(Poly[1] - Poly[0]);
   Result.Normalize();
end;

function vmNormal(const v1, v2, v3: TVector3): TVector3; {$IFDEF VM_INLINE}inline;{$ENDIF}
begin
   Result := (v3 - v1).Cross(v2 - v1);
   Result.Normalize();
end;

function vmClosestPointOnLine(const v1, v2, vPoint: TVector3): TVector3; {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   vector1, vector2, vector3: TVector3;
   dist, t: single;

begin
   Result := v1;

   vector1 := vPoint - v1;
   {direction vector}
   vector2 := (v2 - v1);
   vector2.Normalize();

   {calculate distance}
   dist := v1.Distance(v2);

   t := vector2.Dot(vector1);

   if(t <= 0) then
      exit(v1);

   if(t >= dist) then
      exit(v2);

   vector3 := vector2 * t;

   Result := v1 + vector3;
end;

function vmPlaneDistance(const normal, point: TVector3): single; {$IFDEF VM_INLINE}inline;{$ENDIF}
begin
   {Using the plane equation:  Ax + By + Cz + D = 0
    we will find the distance by converting it into: D = -(Ax + By + Cz)

    Generally, the negated dot product of the normal of the plane and the point
    from which we calculate the plane distance.
   }
   Result := -((normal[0]*point[0]) + (normal[1]*point[1]) + (normal[2]*point[2]));
end;

{ANGLE ROUTINES}
function vmAngle(const v1, v2: TVector2): double; {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   dotp, magnitude: single;

begin
   dotp := (v1[0] * v2[0]) + (v1[1] * v2[1]);

   magnitude := sqrt((v1[0] * v1[0]) + (v1[1] * v1[1])) *
                sqrt((v2[0] * v2[0]) + (v2[1] * v2[1]));

   Result := arccos(dotp / magnitude);
end;

function vmAngle(const v1, v2: TVector3): double; {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   dotp, magnitude: single;

begin
   dotp := (v1[0] * v2[0]) + (v1[1] * v2[1]) + (v1[2] * v2[2]);

   magnitude := sqrt((v1[0] * v1[0]) + (v1[1] * v1[1]) + (v1[2] * v1[2])) *
                sqrt((v2[0] * v2[0]) + (v2[1] * v2[1]) + (v2[2] * v2[2]));

   Result := arccos(dotp / magnitude);
end;

function vmAngle(const v1, v2: TVector4): double; {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   dotp, magnitude: single;

begin
   {this could}
   dotp := (v1[0] * v2[0]) + (v1[1] * v2[1]) + (v1[2] * v2[2]) + (v1[3] * v2[3]);

   magnitude := sqrt((v1[0] * v1[0]) + (v1[1] * v1[1]) + (v1[2] * v1[2]) + (v1[3] * v1[3])) *
                sqrt((v2[0] * v2[0]) + (v2[1] * v2[1]) + (v2[2] * v2[2]) + (v2[3] * v2[3]));

   Result := arccos(dotp / magnitude);
end;

{Note on vmxAngle routines: As you move a vector further from the origin(0,0) the
angle between that vector, and another vector moving along with the first vector,
is decreasing with distance. v1 should be the center vector, and v2 the
rotational vector (point rotating around the center). Useful to determine the
camera angle.}

function vmxAngle(const v1, v2: TVector2): double; {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   v3: TVector2;

begin
   v3 := v2 - v1;
   Result := vmAngle(vmvUnit2, v3);
end;

function vmxAngle(const v1, v2: TVector3): double; {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   v3: TVector3;

begin
   v3 := v2 - v1;
   Result := vmAngle(vmvUnit3, v3);
end;

function vmxAngle(const v1, v2: TVector4): double; {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   v3: TVector4;

begin
   v3 := v2 - v1;
   Result := vmAngle(vmvUnit4, v3);
end;

procedure vmRotateAroundPoint(angle, x, y, z: single; point: TVector3;
      var vector: TVector3); {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   vPos,
   vNewPos: TVector3;
   c,
   s,
   OneMinusC: single;

begin
   {get the directional vector}
   vPos := vector - point;

	{calculate the angles sine and cosine once}
   c := cos(angle);
   s := sin(angle);

   OneMinusC := (1 - c);

   {calculate the new x position of the rotated point}
   vNewPos[0] := (c + OneMinusC * x * x)  * vPos[0];
   vNewPos[0] := vNewPos[0] + ((OneMinusC * x * y - z * s) * vPos[1]);
   vNewPos[0] := vNewPos[0] + ((OneMinusC * x * z + y * s) * vPos[2]);

   {calculate the new y position of the rotated point}
   vNewPos[1] := (OneMinusC * x * y + z * s) * vPos[0];
   vNewPos[1] := vNewPos[1] + ((c + OneMinusC * y * y) * vPos[1]);
   vNewPos[1] := vNewPos[1] + ((OneMinusC * y * z - x * s) * vPos[2]);

   {calculate the new z position of the rotated point}
   vNewPos[2] := (OneMinusC * x * z - y * s) * vPos[0];
   vNewPos[2] := vNewPos[2] + ((OneMinusC * y * z + x * s) * vPos[1]);
   vNewPos[2] := vNewPos[2] + ((c + OneMinusC * z * z)  * vPos[2]);

   {add the new view to the position to rotate}
   vector := point + vNewPos;
end;

{ SPHERE }

procedure vmSphereToCartesian(r, phi, theta: single; out c: TVector3f); {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   costheta,
   sintheta,
   cosphi,
   sinphi: single;

begin
   costheta := cos(theta);
   sintheta := sin(theta);
   cosphi   := cos(phi);
   sinphi   := sin(phi);

   c[0] := r * sinphi * sintheta;
   c[1] := r * costheta;
   c[2] := r * cosphi * sintheta;
end;

{ VECTOR OPERATIONS }

procedure vmSwapCoords(src, dst: longint; var v: TVector3f; n: longint);
var
   i: longint;
   p: PVector3f;
   t: TVector3f;

begin
   p := @v;
   if(src <> dst) and (p <> nil) and (n > 0) then begin
      if((src = vmcXYZ) and (dst = vmcXZY)) or ((src = vmcXZY) and (dst = vmcXYZ)) then begin
         for i := 0 to (n-1) do begin
            t        := p[i];
            p[i][0]  := t[0];
            p[i][1]  := t[2];
            p[i][2]  := -t[1];
         end;
      end;
   end;
end;

procedure vmLTR(var v: TVector3f; n: longint);
var
   i: loopint;
   p: PVector3f;
   t: TVector3f;

begin
   p := @v;

   if(p <> nil) and (n > 0) then begin
      for i := 0 to (n - 1) do begin
         t        := p[i];
         p[i][0]  := t[0];
         p[i][1]  := t[2];
         p[i][2]  := -t[1];
      end;
   end;
end;

{scales an array of vectors}
procedure vmScale(var v: TVector2f; n: longint; scale: single);
var
   i: longint;
   p: PVector2f;

begin
   p := @v;
   for i := 0 to (n-1) do begin
      p[i][0] := p[i][0] * scale;
      p[i][1] := p[i][1] * scale;
   end;
end;

procedure vmScale(var v: TVector3f; n: longint; scale: single);
var
   i: longint;
   p: PVector3f;

begin
   p := @v;
   for i := 0 to (n-1) do begin
      p[i][0] := p[i][0] * scale;
      p[i][1] := p[i][1] * scale;
      p[i][2] := p[i][2] * scale;
   end;
end;

procedure vmScale(var v: TVector4f; n: longint; scale: single);
var
   i: longint;
   p: PVector4f;

begin
   p := @v;
   for i := 0 to (n-1) do begin
      p[i][0] := p[i][0] * scale;
      p[i][1] := p[i][1] * scale;
      p[i][2] := p[i][2] * scale;
      p[i][3] := p[i][3] * scale;
   end;
end;

procedure vmScale(var v: TVector2f; n: longint; x, y: single);
var
   i: longint;
   p: PVector2f;

begin
   p := @v;
   for i := 0 to (n-1) do begin
      p[i][0] := p[i][0] * x;
      p[i][1] := p[i][1] * y;
   end;
end;


procedure vmScale(var v: TVector3f; n: longint; x, y, z: single);
var
   i: longint;
   p: PVector3f;

begin
   p := @v;
   for i := 0 to (n-1) do begin
      p[i][0] := p[i][0] * x;
      p[i][1] := p[i][1] * y;
      p[i][2] := p[i][2] * z;
   end;
end;

procedure vmScale(var v: TVector4f; n: longint; x, y, z, w: single);
var
   i: longint;
   p: PVector4f;

begin
   p := @v;
   for i := 0 to (n-1) do begin
      p[i][0] := p[i][0] * x;
      p[i][1] := p[i][1] * y;
      p[i][2] := p[i][2] * z;
      p[i][3] := p[i][3] * w;
   end;
end;

procedure vmOffset(var v: TVector2f; n: longint; x, y: single);
var
   i: longint;
   p: PVector2f;

begin
   p := @v;
   for i := 0 to (n-1) do begin
      p[i][0] := p[i][0] + x;
      p[i][1] := p[i][1] + y;
   end;
end;

procedure vmOffset(var v: TVector3f; n: longint; x, y, z: single);
var
   i: longint;
   p: PVector3f;

begin
   p := @v;
   for i := 0 to (n-1) do begin
      p[i][0] := p[i][0] + x;
      p[i][1] := p[i][1] + y;
      p[i][2] := p[i][2] + z;
   end;
end;

procedure vmOffset(var v: TVector4f; n: longint; x, y, z, w: single);
var
   i: longint;
   p: PVector4f;

begin
   p := @v;
   for i := 0 to (n-1) do begin
      p[i][0] := p[i][0] + x;
      p[i][1] := p[i][1] + y;
      p[i][2] := p[i][2] + z;
      p[i][3] := p[i][3] + w;
   end;
end;

{ DIRECTION }

function vmDirectionAB(const a, b: TVector3f): TVector3f;
begin
   Result := b - a;
   Result.Normalize();
end;


{ OPERATOR OVERLOAD }

{ VECTOR/VECTOR OPERATIONS }

{SHORT (SMALLINT)}

operator + (const v1, v2: TVector2s): TVector2s;
{$INCLUDE operators/opaddvec2.inc}

operator + (const v1, v2: TVector3s): TVector3s;
{$INCLUDE operators/opaddvec3.inc}

operator + (const v1, v2: TVector4s): TVector4s;
{$INCLUDE operators/opaddvec4.inc}

operator - (const v1, v2: TVector2s): TVector2s;
{$INCLUDE operators/opsubvec2.inc}

operator - (const v1, v2: TVector3s): TVector3s;
{$INCLUDE operators/opsubvec3.inc}

operator - (const v1, v2: TVector4s): TVector4s;
{$INCLUDE operators/opsubvec4.inc}

operator * (const v1, v2: TVector2s): TVector2s;
{$INCLUDE operators/opmulvec2.inc}

operator * (const v1, v2: TVector3s): TVector3s;
{$INCLUDE operators/opmulvec3.inc}

operator * (const v1, v2: TVector4s): TVector4s;
{$INCLUDE operators/opmulvec4.inc}

operator / (const v1, v2: TVector2s): TVector2s;
{$INCLUDE operators/opdivvec2i.inc}

operator / (const v1, v2: TVector3s): TVector3s;
{$INCLUDE operators/opdivvec3i.inc}

operator / (const v1, v2: TVector4s): TVector4s;
{$INCLUDE operators/opdivvec4i.inc}

{UNSIGNED SHORT (WORD)}

operator + (const v1, v2: TVector2us): TVector2us;
{$INCLUDE operators/opaddvec2.inc}

operator + (const v1, v2: TVector3us): TVector3us;
{$INCLUDE operators/opaddvec3.inc}

operator + (const v1, v2: TVector4us): TVector4us;
{$INCLUDE operators/opaddvec4.inc}

operator - (const v1, v2: TVector2us): TVector2us;
{$INCLUDE operators/opsubvec2.inc}

operator - (const v1, v2: TVector3us): TVector3us;
{$INCLUDE operators/opsubvec3.inc}

operator - (const v1, v2: TVector4us): TVector4us;
{$INCLUDE operators/opsubvec4.inc}

operator * (const v1, v2: TVector2us): TVector2us;
{$INCLUDE operators/opmulvec2.inc}

operator * (const v1, v2: TVector3us): TVector3us;
{$INCLUDE operators/opmulvec3.inc}

operator * (const v1, v2: TVector4us): TVector4us;
{$INCLUDE operators/opmulvec4.inc}

operator / (const v1, v2: TVector2us): TVector2us;
{$INCLUDE operators/opdivvec2i.inc}

operator / (const v1, v2: TVector3us): TVector3us;
{$INCLUDE operators/opdivvec3i.inc}

operator / (const v1, v2: TVector4us): TVector4us;
{$INCLUDE operators/opdivvec4i.inc}

{INTEGER (LONGINT)}

operator + (const v1, v2: TVector2i): TVector2i;
{$INCLUDE operators/opaddvec2.inc}

operator + (const v1, v2: TVector3i): TVector3i;
{$INCLUDE operators/opaddvec3.inc}

operator + (const v1, v2: TVector4i): TVector4i;
{$INCLUDE operators/opaddvec4.inc}

operator - (const v1, v2: TVector2i): TVector2i;
{$INCLUDE operators/opsubvec2.inc}

operator - (const v1, v2: TVector3i): TVector3i;
{$INCLUDE operators/opsubvec3.inc}

operator - (const v1, v2: TVector4i): TVector4i;
{$INCLUDE operators/opsubvec4.inc}

operator * (const v1, v2: TVector2i): TVector2i;
{$INCLUDE operators/opmulvec2.inc}

operator * (const v1, v2: TVector3i): TVector3i;
{$INCLUDE operators/opmulvec3.inc}

operator * (const v1, v2: TVector4i): TVector4i;
{$INCLUDE operators/opmulvec4.inc}

operator / (const v1, v2: TVector2i): TVector2i;
{$INCLUDE operators/opdivvec2i.inc}

operator / (const v1, v2: TVector3i): TVector3i;
{$INCLUDE operators/opdivvec3i.inc}

operator / (const v1, v2: TVector4i): TVector4i;
{$INCLUDE operators/opdivvec4i.inc}

{UNSIGNED INTEGER (LONGWORD)}

operator + (const v1, v2: TVector2ui): TVector2ui;
{$INCLUDE operators/opaddvec2.inc}

operator + (const v1, v2: TVector3ui): TVector3ui;
{$INCLUDE operators/opaddvec3.inc}

operator + (const v1, v2: TVector4ui): TVector4ui;
{$INCLUDE operators/opaddvec4.inc}

operator - (const v1, v2: TVector2ui): TVector2ui;
{$INCLUDE operators/opsubvec2.inc}

operator - (const v1, v2: TVector3ui): TVector3ui;
{$INCLUDE operators/opsubvec3.inc}

operator - (const v1, v2: TVector4ui): TVector4ui;
{$INCLUDE operators/opsubvec4.inc}

operator * (const v1, v2: TVector2ui): TVector2ui;
{$INCLUDE operators/opmulvec2.inc}

operator * (const v1, v2: TVector3ui): TVector3ui;
{$INCLUDE operators/opmulvec3.inc}

operator * (const v1, v2: TVector4ui): TVector4ui;
{$INCLUDE operators/opmulvec4.inc}

operator / (const v1, v2: TVector2ui): TVector2ui;
{$INCLUDE operators/opdivvec2i.inc}

operator / (const v1, v2: TVector3ui): TVector3ui;
{$INCLUDE operators/opdivvec3i.inc}

operator / (const v1, v2: TVector4ui): TVector4ui;
{$INCLUDE operators/opdivvec4i.inc}

{SINGLE}

operator + (const v1, v2: TVector2f): TVector2f;
{$INCLUDE operators/opaddvec2.inc}

operator + (const v1, v2: TVector3f): TVector3f;
{$INCLUDE operators/opaddvec3.inc}

operator + (const v1, v2: TVector4f): TVector4f;
{$INCLUDE operators/opaddvec4.inc}

operator - (const v1, v2: TVector2f): TVector2f;
{$INCLUDE operators/opsubvec2.inc}

operator - (const v1, v2: TVector3f): TVector3f;
{$INCLUDE operators/opsubvec3.inc}

operator - (const v1, v2: TVector4f): TVector4f;
{$INCLUDE operators/opsubvec4.inc}

operator * (const v1, v2: TVector2f): TVector2f;
{$INCLUDE operators/opmulvec2.inc}

operator * (const v1, v2: TVector3f): TVector3f;
{$INCLUDE operators/opmulvec3.inc}

operator * (const v1, v2: TVector4f): TVector4f;
{$INCLUDE operators/opmulvec4.inc}

operator / (const v1, v2: TVector2f): TVector2f;
{$INCLUDE operators/opdivvec2.inc}

operator / (const v1, v2: TVector3f): TVector3f;
{$INCLUDE operators/opdivvec3.inc}

operator / (const v1, v2: TVector4f): TVector4f;
{$INCLUDE operators/opdivvec4.inc}

{DOUBLE}

operator + (const v1, v2: TVector2d): TVector2d;
{$INCLUDE operators/opaddvec2.inc}

operator + (const v1, v2: TVector3d): TVector3d;
{$INCLUDE operators/opaddvec3.inc}

operator + (const v1, v2: TVector4d): TVector4d;
{$INCLUDE operators/opaddvec4.inc}

operator - (const v1, v2: TVector2d): TVector2d;
{$INCLUDE operators/opsubvec2.inc}

operator - (const v1, v2: TVector3d): TVector3d;
{$INCLUDE operators/opsubvec3.inc}

operator - (const v1, v2: TVector4d): TVector4d;
{$INCLUDE operators/opsubvec4.inc}

operator * (const v1, v2: TVector2d): TVector2d;
{$INCLUDE operators/opmulvec2.inc}

operator * (const v1, v2: TVector3d): TVector3d;
{$INCLUDE operators/opmulvec3.inc}

operator * (const v1, v2: TVector4d): TVector4d;
{$INCLUDE operators/opmulvec4.inc}

operator / (const v1, v2: TVector2d): TVector2d;
{$INCLUDE operators/opdivvec2.inc}

operator / (const v1, v2: TVector3d): TVector3d;
{$INCLUDE operators/opdivvec3.inc}

operator / (const v1, v2: TVector4d): TVector4d;
{$INCLUDE operators/opdivvec4.inc}


{ VECTOR/SCALAR OPERATIONS }

{SHORT (SMALLINT)}

operator + (const v1: TVector2s; const scalar: smallint): TVector2s;
{$INCLUDE operators/opaddvec2s.inc}

operator + (const v1: TVector3s; const scalar: smallint): TVector3s;
{$INCLUDE operators/opaddvec3s.inc}

operator + (const v1: TVector4s; const scalar: smallint): TVector4s;
{$INCLUDE operators/opaddvec4s.inc}

operator - (const v1: TVector2s; const scalar: smallint): TVector2s;
{$INCLUDE operators/opsubvec2s.inc}

operator - (const v1: TVector3s; const scalar: smallint): TVector3s;
{$INCLUDE operators/opsubvec3s.inc}

operator - (const v1: TVector4s; const scalar: smallint): TVector4s;
{$INCLUDE operators/opsubvec3s.inc}

operator * (const v1: TVector2s; const scalar: smallint): TVector2s;
{$INCLUDE operators/opmulvec2s.inc}

operator * (const v1: TVector3s; const scalar: smallint): TVector3s;
{$INCLUDE operators/opmulvec3s.inc}

operator * (const v1: TVector4s; const scalar: smallint): TVector4s;
{$INCLUDE operators/opmulvec4s.inc}

operator / (const v1: TVector2s; const scalar: smallint): TVector2s;
{$INCLUDE operators/opdivvec2si.inc}

operator / (const v1: TVector3s; const scalar: smallint): TVector3s;
{$INCLUDE operators/opdivvec3si.inc}

operator / (const v1: TVector4s; const scalar: smallint): TVector4s;
{$INCLUDE operators/opdivvec4si.inc}

{UNSIGNED SHORT (WORD)}

operator + (const v1: TVector2us; const scalar: word): TVector2us;
{$INCLUDE operators/opaddvec2s.inc}

operator + (const v1: TVector3us; const scalar: word): TVector3us;
{$INCLUDE operators/opaddvec3s.inc}

operator + (const v1: TVector4us; const scalar: word): TVector4us;
{$INCLUDE operators/opaddvec4s.inc}

operator - (const v1: TVector2us; const scalar: word): TVector2us;
{$INCLUDE operators/opsubvec2s.inc}

operator - (const v1: TVector3us; const scalar: word): TVector3us;
{$INCLUDE operators/opsubvec3s.inc}

operator - (const v1: TVector4us; const scalar: word): TVector4us;
{$INCLUDE operators/opsubvec3s.inc}

operator * (const v1: TVector2us; const scalar: word): TVector2us;
{$INCLUDE operators/opmulvec2s.inc}

operator * (const v1: TVector3us; const scalar: word): TVector3us;
{$INCLUDE operators/opmulvec3s.inc}

operator * (const v1: TVector4us; const scalar: word): TVector4us;
{$INCLUDE operators/opmulvec4s.inc}

operator / (const v1: TVector2us; const scalar: word): TVector2us;
{$INCLUDE operators/opdivvec2si.inc}

operator / (const v1: TVector3us; const scalar: word): TVector3us;
{$INCLUDE operators/opdivvec3si.inc}

operator / (const v1: TVector4us; const scalar: word): TVector4us;
{$INCLUDE operators/opdivvec4si.inc}

{INTEGER (LONGINT)}

operator + (const v1: TVector2i; const scalar: longint): TVector2i;
{$INCLUDE operators/opaddvec2s.inc}

operator + (const v1: TVector3i; const scalar: longint): TVector3i;
{$INCLUDE operators/opaddvec3s.inc}

operator + (const v1: TVector4i; const scalar: longint): TVector4i;
{$INCLUDE operators/opaddvec4s.inc}

operator - (const v1: TVector2i; const scalar: longint): TVector2i;
{$INCLUDE operators/opsubvec2s.inc}

operator - (const v1: TVector3i; const scalar: longint): TVector3i;
{$INCLUDE operators/opsubvec3s.inc}

operator - (const v1: TVector4i; const scalar: longint): TVector4i;
{$INCLUDE operators/opsubvec3s.inc}


operator * (const v1: TVector2i; const scalar: longint): TVector2i;
{$INCLUDE operators/opmulvec2s.inc}

operator * (const v1: TVector3i; const scalar: longint): TVector3i;
{$INCLUDE operators/opmulvec3s.inc}

operator * (const v1: TVector4i; const scalar: longint): TVector4i;
{$INCLUDE operators/opmulvec4s.inc}

operator / (const v1: TVector2i; const scalar: longint): TVector2i;
{$INCLUDE operators/opdivvec2si.inc}

operator / (const v1: TVector3i; const scalar: longint): TVector3i;
{$INCLUDE operators/opdivvec3si.inc}

operator / (const v1: TVector4i; const scalar: longint): TVector4i;
{$INCLUDE operators/opdivvec4si.inc}

{UNSIGNED INTEGER (LONGWORD)}

operator + (const v1: TVector2ui; const scalar: longword): TVector2ui;
{$INCLUDE operators/opaddvec2s.inc}

operator + (const v1: TVector3ui; const scalar: longword): TVector3ui;
{$INCLUDE operators/opaddvec3s.inc}

operator + (const v1: TVector4ui; const scalar: longword): TVector4ui;
{$INCLUDE operators/opaddvec4s.inc}

operator - (const v1: TVector2ui; const scalar: longword): TVector2ui;
{$INCLUDE operators/opsubvec2s.inc}

operator - (const v1: TVector3ui; const scalar: longword): TVector3ui;
{$INCLUDE operators/opsubvec3s.inc}

operator - (const v1: TVector4ui; const scalar: longword): TVector4ui;
{$INCLUDE operators/opsubvec3s.inc}

operator * (const v1: TVector2ui; const scalar: longword): TVector2ui;
{$INCLUDE operators/opmulvec2s.inc}

operator * (const v1: TVector3ui; const scalar: longword): TVector3ui;
{$INCLUDE operators/opmulvec3s.inc}

operator * (const v1: TVector4ui; const scalar: longword): TVector4ui;
{$INCLUDE operators/opmulvec4s.inc}

operator / (const v1: TVector2ui; const scalar: longword): TVector2ui;
{$INCLUDE operators/opdivvec2si.inc}

operator / (const v1: TVector3ui; const scalar: longword): TVector3ui;
{$INCLUDE operators/opdivvec3si.inc}

operator / (const v1: TVector4ui; const scalar: longword): TVector4ui;
{$INCLUDE operators/opdivvec4si.inc}

{SHORT (SMALLINT) / SINGLE}

operator + (const v1: TVector2s; const scalar: single): TVector2f;
{$INCLUDE operators/opaddvec2s.inc}

operator + (const v1: TVector3s; const scalar: single): TVector3f;
{$INCLUDE operators/opaddvec3s.inc}

operator + (const v1: TVector4s; const scalar: single): TVector4f;
{$INCLUDE operators/opaddvec4s.inc}

operator - (const v1: TVector2s; const scalar: single): TVector2f;
{$INCLUDE operators/opsubvec2s.inc}

operator - (const v1: TVector3s; const scalar: single): TVector3f;
{$INCLUDE operators/opsubvec3s.inc}

operator - (const v1: TVector4s; const scalar: single): TVector4f;
{$INCLUDE operators/opsubvec3s.inc}

operator * (const v1: TVector2s; const scalar: single): TVector2f;
{$INCLUDE operators/opmulvec2s.inc}

operator * (const v1: TVector3s; const scalar: single): TVector3f;
{$INCLUDE operators/opmulvec3s.inc}

operator * (const v1: TVector4s; const scalar: single): TVector4f;
{$INCLUDE operators/opmulvec4s.inc}

operator / (const v1: TVector2s; const scalar: single): TVector2f;
{$INCLUDE operators/opdivvec2s.inc}

operator / (const v1: TVector3s; const scalar: single): TVector3f;
{$INCLUDE operators/opdivvec3s.inc}

operator / (const v1: TVector4s; const scalar: single): TVector4f;
{$INCLUDE operators/opdivvec4s.inc}

{UNSIGNED SHORT (WORD) / SINGLE}

operator + (const v1: TVector2us; const scalar: single): TVector2f;
{$INCLUDE operators/opaddvec2s.inc}

operator + (const v1: TVector3us; const scalar: single): TVector3f;
{$INCLUDE operators/opaddvec3s.inc}

operator + (const v1: TVector4us; const scalar: single): TVector4f;
{$INCLUDE operators/opaddvec4s.inc}

operator - (const v1: TVector2us; const scalar: single): TVector2f;
{$INCLUDE operators/opsubvec2s.inc}

operator - (const v1: TVector3us; const scalar: single): TVector3f;
{$INCLUDE operators/opsubvec3s.inc}

operator - (const v1: TVector4us; const scalar: single): TVector4f;
{$INCLUDE operators/opsubvec3s.inc}

operator * (const v1: TVector2us; const scalar: single): TVector2f;
{$INCLUDE operators/opmulvec2s.inc}

operator * (const v1: TVector3us; const scalar: single): TVector3f;
{$INCLUDE operators/opmulvec3s.inc}

operator * (const v1: TVector4us; const scalar: single): TVector4f;
{$INCLUDE operators/opmulvec4s.inc}

operator / (const v1: TVector2us; const scalar: single): TVector2f;
{$INCLUDE operators/opdivvec2s.inc}

operator / (const v1: TVector3us; const scalar: single): TVector3f;
{$INCLUDE operators/opdivvec3s.inc}

operator / (const v1: TVector4us; const scalar: single): TVector4f;
{$INCLUDE operators/opdivvec4s.inc}

{INTEGER (INT32) / SINGLE}

operator + (const v1: TVector2i; const scalar: single): TVector2f;
{$INCLUDE operators/opaddvec2s.inc}

operator + (const v1: TVector3i; const scalar: single): TVector3f;
{$INCLUDE operators/opaddvec3s.inc}

operator + (const v1: TVector4i; const scalar: single): TVector4f;
{$INCLUDE operators/opaddvec4s.inc}

operator - (const v1: TVector2i; const scalar: single): TVector2f;
{$INCLUDE operators/opsubvec2s.inc}

operator - (const v1: TVector3i; const scalar: single): TVector3f;
{$INCLUDE operators/opsubvec3s.inc}

operator - (const v1: TVector4i; const scalar: single): TVector4f;
{$INCLUDE operators/opsubvec3s.inc}

operator * (const v1: TVector2i; const scalar: single): TVector2f;
{$INCLUDE operators/opmulvec2s.inc}

operator * (const v1: TVector3i; const scalar: single): TVector3f;
{$INCLUDE operators/opmulvec3s.inc}

operator * (const v1: TVector4i; const scalar: single): TVector4f;
{$INCLUDE operators/opmulvec4s.inc}

operator / (const v1: TVector2i; const scalar: single): TVector2f;
{$INCLUDE operators/opdivvec2s.inc}

operator / (const v1: TVector3i; const scalar: single): TVector3f;
{$INCLUDE operators/opdivvec3s.inc}

operator / (const v1: TVector4i; const scalar: single): TVector4f;
{$INCLUDE operators/opdivvec4s.inc}

{UNSIGNED INTEGER (LONGWORD) / SINGLE}

operator + (const v1: TVector2ui; const scalar: single): TVector2f;
{$INCLUDE operators/opaddvec2s.inc}

operator + (const v1: TVector3ui; const scalar: single): TVector3f;
{$INCLUDE operators/opaddvec3s.inc}

operator + (const v1: TVector4ui; const scalar: single): TVector4f;
{$INCLUDE operators/opaddvec4s.inc}

operator - (const v1: TVector2ui; const scalar: single): TVector2f;
{$INCLUDE operators/opsubvec2s.inc}

operator - (const v1: TVector3ui; const scalar: single): TVector3f;
{$INCLUDE operators/opsubvec3s.inc}

operator - (const v1: TVector4ui; const scalar: single): TVector4f;
{$INCLUDE operators/opsubvec3s.inc}

operator * (const v1: TVector2ui; const scalar: single): TVector2f;
{$INCLUDE operators/opmulvec2s.inc}

operator * (const v1: TVector3ui; const scalar: single): TVector3f;
{$INCLUDE operators/opmulvec3s.inc}

operator * (const v1: TVector4ui; const scalar: single): TVector4f;
{$INCLUDE operators/opmulvec4s.inc}

operator / (const v1: TVector2ui; const scalar: single): TVector2f;
{$INCLUDE operators/opdivvec2s.inc}

operator / (const v1: TVector3ui; const scalar: single): TVector3f;
{$INCLUDE operators/opdivvec3s.inc}

operator / (const v1: TVector4ui; const scalar: single): TVector4f;
{$INCLUDE operators/opdivvec4s.inc}

{SINGLE}

operator + (const v1: TVector2f; const scalar: single): TVector2f;
{$INCLUDE operators/opaddvec2s.inc}

operator + (const v1: TVector3f; const scalar: single): TVector3f;
{$INCLUDE operators/opaddvec3s.inc}

operator + (const v1: TVector4f; const scalar: single): TVector4f;
{$INCLUDE operators/opaddvec4s.inc}

operator - (const v1: TVector2f; const scalar: single): TVector2f;
{$INCLUDE operators/opsubvec2s.inc}

operator - (const v1: TVector3f; const scalar: single): TVector3f;
{$INCLUDE operators/opsubvec3s.inc}

operator - (const v1: TVector4f; const scalar: single): TVector4f;
{$INCLUDE operators/opsubvec3s.inc}

operator * (const v1: TVector2f; const scalar: single): TVector2f;
{$INCLUDE operators/opmulvec2s.inc}

operator * (const v1: TVector3f; const scalar: single): TVector3f;
{$INCLUDE operators/opmulvec3s.inc}

operator * (const v1: TVector4f; const scalar: single): TVector4f;
{$INCLUDE operators/opmulvec4s.inc}

operator / (const v1: TVector2f; const scalar: single): TVector2f;
{$INCLUDE operators/opdivvec2s.inc}

operator / (const v1: TVector3f; const scalar: single): TVector3f;
{$INCLUDE operators/opdivvec3s.inc}

operator / (const v1: TVector4f; const scalar: single): TVector4f;
{$INCLUDE operators/opdivvec4s.inc}

{DOUBLE}

operator + (const v1: TVector2d; const scalar: double): TVector2d;
{$INCLUDE operators/opaddvec2s.inc}

operator + (const v1: TVector3d; const scalar: double): TVector3d;
{$INCLUDE operators/opaddvec3s.inc}

operator + (const v1: TVector4d; const scalar: double): TVector4d;
{$INCLUDE operators/opaddvec4s.inc}

operator - (const v1: TVector2d; const scalar: double): TVector2d;
{$INCLUDE operators/opsubvec2s.inc}

operator - (const v1: TVector3d; const scalar: double): TVector3d;
{$INCLUDE operators/opsubvec3s.inc}

operator - (const v1: TVector4d; const scalar: double): TVector4d;
{$INCLUDE operators/opsubvec3s.inc}

operator * (const v1: TVector2d; const scalar: double): TVector2d;
{$INCLUDE operators/opmulvec2s.inc}

operator * (const v1: TVector3d; const scalar: double): TVector3d;
{$INCLUDE operators/opmulvec3s.inc}

operator * (const v1: TVector4d; const scalar: double): TVector4d;
{$INCLUDE operators/opmulvec4s.inc}

operator / (const v1: TVector2d; const scalar: double): TVector2d;
{$INCLUDE operators/opdivvec2s.inc}

operator / (const v1: TVector3d; const scalar: double): TVector3d;
{$INCLUDE operators/opdivvec3s.inc}

operator / (const v1: TVector4d; const scalar: double): TVector4d;
{$INCLUDE operators/opdivvec4s.inc}

{ MATRIX }

operator * (const m1: TMatrix2f; const m2: TMatrix2f): TMatrix2f;
{$INCLUDE operators/opmulmatrix2.inc}
operator * (const m1: TMatrix3f; const m2: TMatrix3f): TMatrix3f;
{$INCLUDE operators/opmulmatrix3.inc}
operator * (const m1: TMatrix4f; const m2: TMatrix4f): TMatrix4f;
{$INCLUDE operators/opmulmatrix4.inc}

operator * (const m1: TMatrix4f; const v: TVector3f): TVector3f;
{$INCLUDE operators/opmulmatrix4v3.inc}

operator * (const m1: TMatrix4f; const v: TVector4f): TVector4f;
{$INCLUDE operators/opmulmatrix4v4.inc}

{ TVector2Helper }

procedure TVector2Helper.Normalize();
var
   mag: single;

begin
	mag := sqrt(Self[0] * Self[0] +
               Self[1] * Self[1]);

   {$IFNDEF NO_SAFE_NORMALIZATION}
   if(Magnitude <> 0.0) then begin
   {$ENDIF}
      Self[0] := Self[0] / single(mag);
      Self[1] := Self[1] / single(mag);
   {$IFNDEF NO_SAFE_NORMALIZATION}
   end;
   {$ENDIF}
end;

function TVector2Helper.Normalized(): TVector2;
var
   mag: single;

begin
	mag := sqrt(Self[0] * Self[0] +
               Self[1] * Self[1]);

   {$IFNDEF VM_NO_SAFE_NORMALIZATION}
   if(mag <> 0.0) then begin
   {$ENDIF}
      Result[0] := Self[0] / single(mag);
      Result[1] := Self[1] / single(mag);
   {$IFNDEF VM_NO_SAFE_NORMALIZATION}
   end else
      Result := Self; {to prevent divisions by zero}
   {$ENDIF}
end;

function TVector2Helper.Magnitude(): single;
begin
	Result := sqrt(Self[0] * Self[0] +
                  Self[1] * Self[1]);
end;

procedure TVector2Helper.Negative();
begin
   Self[0] := -Self[0];
   Self[1] := -Self[1];
end;

function TVector2Helper.Length(): single;
begin
   Result := sqrt(Self[0] * Self[0] + Self[1] * Self[1])
end;

function TVector2Helper.Dot(v: TVector2): single;
begin
   Result := (Self[0] * v[0]) + (Self[1] * v[1]);
end;

function TVector2Helper.Distance(v: TVector2): single;
var
   x1, x2: single;

begin
   x1 := v[0] - Self[0];
   x2 := v[1] - Self[1];

   {now to calculate distance and return it}
   Result := sqrt(x1 * x1 + x2 * x2);
end;

function TVector2Helper.Equal(v: TVector2; epsilon: single): boolean;
begin
   Result := (abs(Self[0] - v[0]) < epsilon)
         and (abs(Self[1] - v[1]) < epsilon);
end;

procedure TVector2Helper.Assign(x, y: single);
begin
   Self[0] := x;
   Self[1] := y;
end;

function TVector2Helper.ToString(decimals: loopint; const separator: string): string;
begin
   Result := sf(Self[0], decimals) + separator + sf(Self[1], decimals);
end;

class function TVector2Helper.Create(x, y: single): TVector2;
begin
   Result[0] := x;
   Result[1] := y;
end;

{ TVector3Helper }

procedure TVector3Helper.Normalize();
var
   mag: single;

begin
	mag := sqrt(Self[0] * Self[0] +
               Self[1] * Self[1] +
               Self[2] * Self[2]);

   {$IFNDEF NO_SAFE_NORMALIZATION}
   if(mag <> 0.0) then begin
   {$ENDIF}
      Self[0] := Self[0] / single(mag);
      Self[1] := Self[1] / single(mag);
      Self[2] := Self[2] / single(mag);
   {$IFNDEF NO_SAFE_NORMALIZATION}
   end;
   {$ENDIF}
end;

function TVector3Helper.Normalized(): TVector3;
var
   mag: single;

begin
	mag := sqrt(Self[0] * Self[0] +
               Self[1] * Self[1] +
               Self[2] * Self[2]);

   {$IFNDEF NO_SAFE_NORMALIZATION}
   if(mag <> 0.0) then begin
   {$ENDIF}
      Result[0] := Self[0] / single(mag);
      Result[1] := Self[1] / single(mag);
      Result[2] := Self[2] / single(mag);
   {$IFNDEF NO_SAFE_NORMALIZATION}
   end else
      Result := Self;
   {$ENDIF}
end;

function TVector3Helper.Magnitude(): single;
begin
	Result := sqrt(Self[0] * Self[0] +
                  Self[1] * Self[1] +
                  Self[2] * Self[2]);
end;

procedure TVector3Helper.Negative();
begin
   Self[0] := -Self[0];
   Self[1] := -Self[1];
   Self[2] := -Self[2];
end;

function TVector3Helper.Length(): single;
begin
   Result := sqrt(Self[0] * Self[0] + Self[1] * Self[1] + Self[2] * Self[2])
end;

function TVector3Helper.Cross(v: TVector3): TVector3;
begin
   Result[0] := (Self[1] * v[2]) - (Self[2] * v[1]);
   Result[1] := (Self[2] * v[0]) - (Self[0] * v[2]);
   Result[2] := (Self[0] * v[1]) - (Self[1] * v[0]);
end;

function TVector3Helper.Dot(v: TVector3): single;
begin
   Result := (Self[0] * v[0]) + (Self[1] * v[1]) + (Self[2] * v[2]);
end;

function TVector3Helper.Distance(v: TVector3): single;
var
   x1, x2, x3: single;

begin
   {The distance formula in 3D coordinate space
    Distance = sqrt(  (P2[0] - P1[0])^2 + (P2[1] - P1[1])^2 + (P2[2] - P1[2])^2}

   x1 := v[0] - Self[0];
   x2 := v[1] - Self[1];
   x3 := v[2] - Self[2];

   {now to calculate distance and return it}
   Result := sqrt(x1 * x1 + x2 * x2 + x3 * x3);
end;

function TVector3Helper.Equal(v: TVector3; epsilon: single): boolean;
begin
   Result := (abs(Self[0] - v[0]) < epsilon)
         and (abs(Self[1] - v[1]) < epsilon)
         and (abs(Self[2] - v[2]) < epsilon);
end;

procedure TVector3Helper.Assign(x, y, z: single);
begin
   Self[0] := x;
   Self[1] := y;
   Self[2] := z;
end;

function TVector3Helper.ToString(decimals: loopint; const separator: string): string;
begin
   Result := sf(Self[0], decimals) + separator + sf(Self[1], decimals) + separator + sf(Self[2], decimals);
end;

class function TVector3Helper.Create(x, y, z: single): TVector3;
begin
   Result[0] := x;
   Result[1] := y;
   Result[2] := z;
end;


{ TVector4Helper }

procedure TVector4Helper.Normalize();
var
   mag: single;

begin
	mag := sqrt(Self[0] * Self[0] +
               Self[1] * Self[1] +
               Self[2] * Self[2] +
               Self[3] * Self[3]);

   {$IFNDEF NO_SAFE_NORMALIZATION}
   if(mag <> 0.0) then begin
   {$ENDIF}
      Self[0] := Self[0] / single(mag);
      Self[1] := Self[1] / single(mag);
      Self[2] := Self[2] / single(mag);
      Self[3] := Self[3] / single(mag);
   {$IFNDEF NO_SAFE_NORMALIZATION}
   end;
   {$ENDIF}
end;

function TVector4Helper.Normalized(): TVector4;
var
   mag: single;

begin
	mag := sqrt(Self[0] * Self[0] +
               Self[1] * Self[1] +
               Self[2] * Self[2] +
               Self[3] * Self[3]);

   {$IFNDEF NO_SAFE_NORMALIZATION}
   if(mag <> 0.0) then begin
   {$ENDIF}
      Result[0] := Self[0] / single(mag);
      Result[1] := Self[1] / single(mag);
      Result[2] := Self[2] / single(mag);
      Result[3] := Self[3] / single(mag);
   {$IFNDEF NO_SAFE_NORMALIZATION}
   end else
      Result := Self;
   {$ENDIF}
end;

function TVector4Helper.Magnitude(): single;
begin
	Result := sqrt(Self[0] * Self[0] +
                  Self[1] * Self[1] +
                  Self[2] * Self[2] +
                  Self[3] * Self[3]);
end;

procedure TVector4Helper.Negative();
begin
   Self[0] := -Self[0];
   Self[1] := -Self[1];
   Self[2] := -Self[2];
   Self[3] := -Self[3];
end;

function TVector4Helper.Length(): single;
begin
   Result := sqrt(Self[0] * Self[0] + Self[1] * Self[1] + Self[2] * Self[2] + Self[3] * Self[3]);
end;

function TVector4Helper.Dot(v: TVector4): single;
begin
   Result := (Self[0] * v[0]) + (Self[1] * v[1]) + (Self[2] * v[2]) + (Self[3] * v[3]);
end;

function TVector4Helper.Distance(v: TVector4): single;
var
   x1, x2, x3, x4: single;

begin
   x1 := v[0] - Self[0];
   x2 := v[1] - Self[1];
   x3 := v[2] - Self[2];
   x4 := v[3] - Self[3];

   {now to calculate distance and return it}
   Result := sqrt(x1 * x1 + x2 * x2 + x3 * x3 + x4 * x4);
end;

function TVector4Helper.Equal(v: TVector4; epsilon: single): boolean;
begin
   Result := (abs(Self[0] - v[0]) < epsilon)
        and (abs(Self[1] - v[1]) < epsilon)
        and (abs(Self[2] - v[2]) < epsilon)
        and (abs(Self[3] - v[3]) < epsilon);
end;

procedure TVector4Helper.Assign(x, y, z, w: single);
begin
   Self[0] := x;
   Self[1] := y;
   Self[2] := z;
   Self[3] := w;
end;

function TVector4Helper.ToString(decimals: loopint; const separator: string): string;
begin
   Result := sf(Self[0], decimals) + separator + sf(Self[1], decimals) + separator + sf(Self[2], decimals) + separator + sf(Self[3], decimals);
end;

class function TVector4Helper.Create(x, y, z, w: single): TVector4;
begin
   Result[0] := x;
   Result[1] := y;
   Result[2] := z;
   Result[3] := w;
end;


{ TVector2iHelper }

function TVector2iHelper.ToString(const separator: string): string;
begin
   Result := sf(Self[0]) + separator + sf(Self[1]);
end;

{ TVector3iHelper }

function TVector3iHelper.ToString(const separator: string): string;
begin
   Result := sf(Self[0]) + separator + sf(Self[1]) + separator + sf(Self[2]);
end;


{ TVector4iHelper }

function TVector4iHelper.ToString(const separator: string): string;
begin
   Result := sf(Self[0]) + separator + sf(Self[1]) + separator + sf(Self[2]) + separator + sf(Self[3]);
end;

{ TMatrix2Helper }

function TMatrix2Helper.Transposed(): TMatrix2;
begin
   Result[0][0] := Self[0][0];
   Result[1][0] := Self[0][1];

   Result[0][1] := Self[1][0];
   Result[1][1] := Self[1][1];
end;

{ TMatrix3Helper }

function TMatrix3Helper.Transposed(): TMatrix3;
begin
   Result[0][0] := Self[0][0];
   Result[1][0] := Self[0][1];
   Result[2][0] := Self[0][2];

   Result[0][1] := Self[1][0];
   Result[1][1] := Self[1][1];
   Result[2][1] := Self[1][2];

   Result[0][2] := Self[2][0];
   Result[1][2] := Self[2][1];
   Result[2][2] := Self[2][2];
end;

{ TMatrix4Helper }

function TMatrix4Helper.Transposed(): TMatrix4;
begin
   Result[0][0] := Self[0][0];
   Result[1][0] := Self[0][1];
   Result[2][0] := Self[0][2];
   Result[3][0] := Self[0][3];

   Result[0][1] := Self[1][0];
   Result[1][1] := Self[1][1];
   Result[2][1] := Self[1][2];
   Result[3][1] := Self[1][3];

   Result[0][2] := Self[2][0];
   Result[1][2] := Self[2][1];
   Result[2][2] := Self[2][2];
   Result[3][2] := Self[2][3];

   Result[0][3] := Self[3][0];
   Result[1][3] := Self[3][1];
   Result[2][3] := Self[3][2];
   Result[3][3] := Self[3][3];
end;

function TMatrix4Helper.Inversed: TMatrix4;
var
   determinant: single;

begin
   determinant := GetDeterminant();

   if(determinant = 0) then begin
      Result := vmmUnit4;
      exit;
   end;

   determinant := 1 / determinant;

   Result[0,0] := determinant * (Self[1,1] * (Self[2,2] * Self[3,3] - Self[2,3] * Self[3,2]) +
                                 Self[1,2] * (Self[2,3] * Self[3,1] - Self[2,1] * Self[3,3]) +
                                 Self[1,3] * (Self[2,1] * Self[3,2] - Self[2,2] * Self[3,1]));

   Result[0,1] := determinant * (Self[2,1] * (Self[0,2] * Self[3,3] - Self[0,3] * Self[3,2]) +
                                 Self[2,2] * (Self[0,3] * Self[3,1] - Self[0,1] * Self[3,3]) +
                                 Self[2,3] * (Self[0,1] * Self[3,2] - Self[0,2] * Self[3,1]));

   Result[0,2] := determinant * (Self[3,1] * (Self[0,2] * Self[1,3] - Self[0,3] * Self[1,2]) +
                                 Self[3,2] * (Self[0,3] * Self[1,1] - Self[0,1] * Self[1,3]) +
                                 Self[3,3] * (Self[0,1] * Self[1,2] - Self[0,2] * Self[1,1]));

   Result[0,3] := determinant * (Self[0,1] * (Self[1,3] * Self[2,2] - Self[1,2] * Self[2,3]) +
                                 Self[0,2] * (Self[1,1] * Self[2,3] - Self[1,3] * Self[2,1]) +
                                 Self[0,3] * (Self[1,2] * Self[2,1] - Self[1,1] * Self[2,2]));

   Result[1,0] := determinant * (Self[1,2] * (Self[2,0] * Self[3,3] - Self[2,3] * Self[3,0]) +
                                 Self[1,3] * (Self[2,2] * Self[3,0] - Self[2,0] * Self[3,2]) +
                                 Self[1,0] * (Self[2,3] * Self[3,2] - Self[2,2] * Self[3,3]));

   Result[1,1] := determinant * (Self[2,2] * (Self[0,0] * Self[3,3] - Self[0,3] * Self[3,0]) +
                                 Self[2,3] * (Self[0,2] * Self[3,0] - Self[0,0] * Self[3,2]) +
                                 Self[2,0] * (Self[0,3] * Self[3,2] - Self[0,2] * Self[3,3]));

   Result[1,2] := determinant * (Self[3,2] * (Self[0,0] * Self[1,3] - Self[0,3] * Self[1,0]) +
                                 Self[3,3] * (Self[0,2] * Self[1,0] - Self[0,0] * Self[1,2]) +
                                 Self[3,0] * (Self[0,3] * Self[1,2] - Self[0,2] * Self[1,3]));

   Result[1,3] := determinant * (Self[0,2] * (Self[1,3] * Self[2,0] - Self[1,0] * Self[2,3]) +
                                 Self[0,3] * (Self[1,0] * Self[2,2] - Self[1,2] * Self[2,0]) +
                                 Self[0,0] * (Self[1,2] * Self[2,3] - Self[1,3] * Self[2,2]));

   Result[2,0] := determinant * (Self[1,3] * (Self[2,0] * Self[3,1] - Self[2,1] * Self[3,0]) +
                                 Self[1,0] * (Self[2,1] * Self[3,3] - Self[2,3] * Self[3,1]) +
                                 Self[1,1] * (Self[2,3] * Self[3,0] - Self[2,0] * Self[3,3]));

   Result[2,1] := determinant * (Self[2,3] * (Self[0,0] * Self[3,1] - Self[0,1] * Self[3,0]) +
                                 Self[2,0] * (Self[0,1] * Self[3,3] - Self[0,3] * Self[3,1]) +
                                 Self[2,1] * (Self[0,3] * Self[3,0] - Self[0,0] * Self[3,3]));

   Result[2,2] := determinant * (Self[3,3] * (Self[0,0] * Self[1,1] - Self[0,1] * Self[1,0]) +
                                 Self[3,0] * (Self[0,1] * Self[1,3] - Self[0,3] * Self[1,1]) +
                                 Self[3,1] * (Self[0,3] * Self[1,0] - Self[0,0] * Self[1,3]));

   Result[2,3] := determinant * (Self[0,3] * (Self[1,1] * Self[2,0] - Self[1,0] * Self[2,1]) +
                                 Self[0,0] * (Self[1,3] * Self[2,1] - Self[1,1] * Self[2,3]) +
                                 Self[0,1] * (Self[1,0] * Self[2,3] - Self[1,3] * Self[2,0]));

   Result[3,0] := determinant * (Self[1,0] * (Self[2,2] * Self[3,1] - Self[2,1] * Self[3,2]) +
                                 Self[1,1] * (Self[2,0] * Self[3,2] - Self[2,2] * Self[3,0]) +
                                 Self[1,2] * (Self[2,1] * Self[3,0] - Self[2,0] * Self[3,1]));

   Result[3,1] := determinant * (Self[2,0] * (Self[0,2] * Self[3,1] - Self[0,1] * Self[3,2]) +
                                 Self[2,1] * (Self[0,0] * Self[3,2] - Self[0,2] * Self[3,0]) +
                                 Self[2,2] * (Self[0,1] * Self[3,0] - Self[0,0] * Self[3,1]));

   Result[3,2] := determinant * (Self[3,0] * (Self[0,2] * Self[1,1] - Self[0,1] * Self[1,2]) +
                                 Self[3,1] * (Self[0,0] * Self[1,2] - Self[0,2] * Self[1,0]) +
                                 Self[3,2] * (Self[0,1] * Self[1,0] - Self[0,0] * Self[1,1]));

   Result[3,3] := determinant * (Self[0,0] * (Self[1,1] * Self[2,2] - Self[1,2] * Self[2,1]) +
                                 Self[0,1] * (Self[1,2] * Self[2,0] - Self[1,0] * Self[2,2]) +
                                 Self[0,2] * (Self[1,0] * Self[2,1] - Self[1,1] * Self[2,0]));
end;

function TMatrix4Helper.GetDeterminant: single;
begin
   Result := (Self[0,0] * Self[1,1] - Self[0,1] * Self[1,0]) * (Self[2,2] * Self[3,3] - Self[2,3] * Self[3,2]) -
             (Self[0,0] * Self[1,2] - Self[0,2] * Self[1,0]) * (Self[2,1] * Self[3,3] - Self[2,3] * Self[3,1]) +
             (Self[0,0] * Self[1,3] - Self[0,3] * Self[1,0]) * (Self[2,1] * Self[3,2] - Self[2,2] * Self[3,1]) +
             (Self[0,1] * Self[1,2] - Self[0,2] * Self[1,1]) * (Self[2,0] * Self[3,3] - Self[2,3] * Self[3,0]) -
             (Self[0,1] * Self[1,3] - Self[0,3] * Self[1,1]) * (Self[2,0] * Self[3,2] - Self[2,2] * Self[3,0]) +
             (Self[0,2] * Self[1,3] - Self[0,3] * Self[1,2]) * (Self[2,0] * Self[3,1] - Self[2,1] * Self[3,0]);
end;

{ TBoundingBoxHelper }

function TBoundingBoxHelper.IsZero(): boolean;
begin
   Result := (CompareDWord(Self[0], vmvZero3f, 3) = 0) and (CompareDWord(Self[1], vmvZero3f, 3) = 0);
end;

procedure TBoundingBoxHelper.AssignPoint(const p: TVector3f; size: Single);
begin
   Self[0][0] := p[0] + size;
   Self[0][1] := p[1] + size;
   Self[0][2] := p[2] + size;

   Self[1][0] := p[0] - size;
   Self[1][1] := p[1] - size;
   Self[1][2] := p[2] - size;
end;

procedure TBoundingBoxHelper.AssignPoint(const x, y, z: single; size: Single);
begin
   Self[0][0] := x + size;
   Self[0][1] := y + size;
   Self[0][2] := y + size;

   Self[1][0] := x - size;
   Self[1][1] := y - size;
   Self[1][2] := z - size;
end;

END.
