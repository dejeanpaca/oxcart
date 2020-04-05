{
   oxumMDL, MDL(Quake) model loader
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxumMDL;

INTERFACE

   USES
      StringUtils, uFileHandlers,
      {ox}
      oxModel;

CONST
   mdlcID: array[0..3] of char   = ('I', 'D', 'P', 'O');
   mdlcVersion                   = 6;

VAR
   oxMDLHandler: oxTModelHandler;

IMPLEMENTATION

TYPE
   mdlTHeader = record
      ID: array[0..3] of char;
      Version: uint32;

      scale, origin: TVector3;
      radius: single;
      offsets: TVector3;
      nSkins, 
      skinWidth, 
      skinHeight,
      nVertices, 
      nTriangles, 
      nFrames, 
      typeSync, 
      Flags: int32;
      Size: single;
   end;

   {The skins structure cannot be described with a simple record,
   and must be interpreted by a routine. Here is the general
   description of the skin structure.

   Group: int32
   If this is 0 then there is only one skin,
   else there is a group of skins.

      [Skin Group] This only exists if Group is not 0
      nImages: int32; number of images(skins)
      Times: array[0..nImages-1] of single; timing for each image

   Skin: array of [0..(skinWidth*skinHeight*1)-1] of uint8;

   There can be more than one skin image depending on whether nImages
   is greater than 0, and that this is a skin group. The skins have
   PIXF_INDEX_8 pixel format}

   mdlTSkinVertex = record
      onseam, s, t: int32;
   end;

   mdlTiTriangle = record
      facesFront: int32;
      Vertices: TVector3i;
   end;

   mdlTTriangle = record
      packedPos: TVector3ub;
      lightNormalIdx: uint8;
   end;

   mdlPData = ^mdlTData;
   mdlTData = record
      mdlHeader: mdlTHeader;
      mdlAnimNames: array of string[15];
   end;

VAR
   mdlLoader: mlTLoader; {loader information}
   mdlExt: mlTExtension;

   submodel: oxPSubModel;

{LOADING}
procedure mdlLoad(data: pointer);
var
   ld: oxmPLoaderData;
   mdlData: mdlTData;

begin
   ld := data;
   ld^.data := @mdlData;
end;

INITIALIZATION
   mdlExt.ext        := '.mdl';
   mdlExt.Loader     := @mdlLoader;

   mdlLoader.Name    := 'QMDL';
   mdlLoader.Load    := @mdlLoad;

   oxmLoaderInfo.RegisterLoader(mdlLoader);
   oxmLoaderInfo.RegisterExt(mdlExt);
END.
