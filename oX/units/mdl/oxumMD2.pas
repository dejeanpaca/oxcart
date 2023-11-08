{
   oxumMD2, MD2 model loader
   Copyright (C) 2011. Dejan Boras

   Started On:    06.06.2007.
}

{$INCLUDE oxdefines.inc}
UNIT oxumMD2;

{MD2 Loader(Quake 2's model file).}

INTERFACE

   USES
      StringUtils,
      uFileHandlers, vmVector,
      {oX}
      oxuMaterials, oxuModel, oxuModelFile;

CONST
   md2cMaxTriangles              = 4096;
   md2cMaxVertices               = 2048;
   md2cMaxTexCoords              = 2048;
   md2cMaxFrames                 = 512;
   md2cMaxSkins                  = 32;
   md2cMaxFrameSize              = (md2cMaxVertices * 4 + 128);

   md2cID: array[0..3] of char   = ('I', 'D', 'P', '2');
   md2cVersion                   = 8;

TYPE
   md2PHeader = ^md2THeader;
   md2THeader = record
      ID, Version, {file ID(aka Magic Number), and the file version}
      skinW,
      skinH, {skin width and height}
      frameSize, {size of an frame}
      {number of: skins, vertices, texture coordinate, triangles, GL command, frames}
      nSkins,
      nVertices,
      nTexCoords,
      nTriangles,
      nglCommands,
      nFrames,
      {offset of data for: skins, texture coordinates, triangles, frames, gl commands, end}
      offsetSkins,
      offsetTexCoords,
      offsetTriangles,
      offsetFrames,
      offsetGLCommands,
      offsetEnd: uint32;
   end;

   md2TTriangle = record
      Vertex: array[0..2] of uint8;
      lightNormalIndex: uint8;
   end;

   md2TFace = record
      iVertex, iUVCoord: array[0..2] of uint16;
   end;

   md2TTexCoord = record
      u, v: uint16;
   end;

   md2PFrame = ^md2TFrame;
   md2TFrame = record
      scale, translate: TVector3;
      sName: string[15];
      Vertices: array[0..0] of md2TTriangle;
   end;

   md2TSkin = string[63];

   {all data is loaded into this structure, this is converted into the oxTModel structure}
   md2PModel = ^md2TModel;
   md2TModel = record
      Skins: array of md2TSkin;
      nglCommands: int32;
      glCommands: array of GLuint;
   end;

VAR
   oxmMD2Handler: oxTModelHandler;

IMPLEMENTATION

VAR
   md2Loader: fhTHandler; {loader information}
   md2Ext: fhTExtension;

TYPE
   md2PData = ^md2TData;
   md2TData = record
      Model: md2TModel;
      Header: md2THeader;
      AnimNames: array of string[15];
   end;

{INITIALIZE}
procedure md2Init(var ld: oxmTLoaderData);
var
   data: md2PData = nil;

begin
   new(data);
   if(data <> nil) then
      Zero(data^, SizeOf(md2TData))
   else
      oxmeRaise(eNO_MEMORY);

   ld.Data := data;
end;

{READ AND CHECK HEADER}
procedure md2ReadHeader(var ld: oxmTLoaderData);
var
   data: md2PData;
   hdr: md2PHeader;

begin
   data := ld.data;
   hdr := @data^.Header;

   oxmlBlockRead(ld, hdr^, sizeof(md2THeader));
   if(oxError <> 0) then exit;

   if(hdr^.ID <> uint32(md2cID)) then begin
      log.i('Not a valid MD2 file.');
      oxmeRaise(eINVALID_ENV);
      exit;
   end;

   {check version, if not 8 then quit}
   if(hdr^.Version <> md2cVersion) then begin
      log.i('Unsupported version: '+sf(hdr^.Version));
      oxmeRaise(eUnsupported);
      exit;
   end;

   {$IFDEF DO_EXTRA_LOGGING}
   log.i('MD2 Version: '+sf(md2Header.Version));
   {$ENDIF}
end;

{initialize the model}
procedure md2InitModel(var ld: oxmTLoaderData);
var
   nFrames: int32;
   data: md2PData;

begin
   data := ld.Data;

   nFrames := data^.Header.nFrames;

   oxmAddSubModel(ld.mdl^);
   if(oxError <> 0) then 
      exit;

   ld.submodel := ld.mdl^.SubModels[ld.mdl^.nSubModels-1];

   {we need the same amount of objects as there are frames,
   since the frames will be stored as objects}
   oxmAddObjects(ld.submodel^, nFrames);
   if(oxError = 0) then begin
      {now allocate memory to store animation names}
      SetLength(data^.AnimNames, nFrames);
   end;
end;

{read skin data}
procedure md2ReadSkinData(var ld: oxmTLoaderData);
var
   nSkins: int32;
   data: md2PData;

begin
   data := ld.data;

   nSkins := data^.Header.nSkins;
   {$IFDEF DO_EXTRA_LOGGING}
   log.i('MD2 Skins: '+sf(nSkins));
   {$ENDIF}
   if(nSkins > 0) then begin {only read in if there are skins available}
      {allocate memory}
      SetLength(data^.Model.Skins, nSkins);
      if(length(data^.Model.Skins) < nSkins) then begin 
         oxmeRaise(eNO_MEMORY); 
         exit; 
      end;

      {read in skin data}
      oxmlSeek(ld, data^.Header.offsetSkins);
      if(oxError <> 0) then 
         exit;
      oxmlBlockRead(ld, data^.Model.Skins[0], int64(sizeof(md2TSkin))*int64(nSkins));
   end;
end;

{read texture coordinate data}
procedure md2ReadTexCoordData(var ld: oxmTLoaderData);
Var
   TexCoords: array of md2TTexCoord = nil; {to store the texture coordinates}
   nTexCoords, i: int32;

   cFrame: oxmPObject;
   data: md2PData;

begin
   data := ld.data;

   nTexCoords := data^.Header.nTexCoords; {get the number of texture coordinates}
   {$IFDEF DO_EXTRA_LOGGING}
   log.i('MD2 Texture Coordinates: '+sf(nTexCoords));
   {$ENDIF}
   {Allocate enough memory for the texture coordinates, and check if there is a failure}
   SetLength(TexCoords, nTexCoords);
   if(length(TexCoords) < nTexCoords) then begin oxmeRaise(eNO_MEMORY); exit; end;

   {read in the texture coordinates}
   oxmlSeek(ld, data^.Header.offsetTexCoords);
   if(oxError <> 0) then 
      exit;
   oxmlBlockRead(ld, TexCoords[0], int64(sizeof(md2TTexCoord))*int64(nTexCoords));
   if(oxError <> 0) then 
      exit;

   {Now, it is required to convert the texture coordinates to oX native format.
   Since these are only required for the first frame(as they are identical in
   each other frame) they will be stored into the first frame.}

   cFrame := ld.submodel^.Objects[0];
   {assign memory for texture coordinates to the first frame}
   oxmAddObjectTexUV(cFrame^, nTexCoords);
   if(oxError <> 0) then 
      exit;

      {now, convert all texture coordinates}
   for i := 0 to cFrame^.nTexUV-1 do begin
      cFrame^.TexUV[i][0] := TexCoords[i].u / data^.Header.skinW;
      cFrame^.TexUV[i][1] := 1 - (TexCoords[i].v / data^.Header.skinH);
   end;

   {free memory used by TexCoords, since this data is within the model and
   is no longer required}
   SetLength(TexCoords, 0);
end;

{read face data}
procedure md2ReadFaceData(var ld: oxmTLoaderData);
var
   Faces: array of md2TFace = nil; {temporary storage of face data}
   nTriangles, i: int32;
   cFrame: oxmPObject;

   data: md2PData;

begin
   data := ld.data;

   nTriangles := data^.Header.nTriangles; {to cut down on code size}
   {$IFDEF DO_EXTRA_LOGGING}
   log.i('MD2 Faces: '+sf(nTriangles));
   {$ENDIF}

   {Same thing as with texture coordinates, face data will be loaded
   only once for the first frame, as it is the same for every other
   frame. (BTW, this saves quite some memory).}

   {allocate memory for face data}
   SetLength(Faces, nTriangles);
   if(length(Faces) < nTriangles) then begin 
      oxmeRaise(eNO_MEMORY); 
      exit; 
   end;

   {read in the face data}
   oxmlSeek(ld, data^.Header.offsetTriangles);
   if(oxError <> 0) then 
      exit;
   {$PUSH}{$HINTS OFF}
   oxmlBlockRead(ld, Faces[0], sizeof(md2TFace)*nTriangles);{$POP}
   if(oxError <> 0) then 
      exit;

   {Now, we(who is we?, I mean I) convert the data}

   cFrame := ld.submodel^.Objects[0];

   {first, allocate face data memory for the first frame}
   oxmAddObjectFaces(cFrame^, nTriangles);
   if(oxError <> 0) then 
      exit;

   oxmAddObjectFacesUV(cFrame^, nTriangles);
   if(oxError <> 0) then
      exit;

   {next, do the actual conversion, which is more of a reassignment than conversions}
   for i := 0 to cFrame^.nFaces-1 do begin
      cFrame^.Faces[i][0] := Faces[i].iVertex[0];
      cFrame^.Faces[i][1] := Faces[i].iVertex[1];
      cFrame^.Faces[i][2] := Faces[i].iVertex[2];

      cFrame^.FacesUV[i][0] := Faces[i].iUVCoord[0];
      cFrame^.FacesUV[i][1] := Faces[i].iUVCoord[1];
      cFrame^.FacesUV[i][2] := Faces[i].iUVCoord[2];
   end;

   {To finish it off, free the memory used by Faces}
   SetLength(Faces, 0);
end;

procedure md2ReadFrameData(var ld: oxmTLoaderData);
var
   Buffer: array[0..md2cMaxFrameSize-1] of uint8; {a buffer into which the current frame will be stored}
   tempFrame: md2PFrame;
   nFrames, nVertices, i, j: uint16;
   cFrame: oxmPObject;

   data: md2PData;

begin
   data := ld.data;

   nFrames := data^.Header.nFrames; nVertices := data^.Header.nVertices;
   {$IFDEF DO_EXTRA_LOGGING}
   log.i('Frames: '+sf(nFrames));
   {$ENDIF}

   tempFrame := @Buffer; {set the frame to point to the address of buffer, that way all data will be stored into the buffer}

   oxmlSeek(ld, data^.Header.offsetFrames); {go to the required position}
   if(oxError <> 0) then exit;
   {process all frames}
   for i := 0 to (nFrames-1) do begin
      {read in the current animation frame}
      oxmlBlockread(ld, tempFrame^, data^.Header.FrameSize);
      if(oxError <> 0) then
         exit;

      {now that we have the frame, we will have to convert it's data into the ox native
      model data}

      cFrame := ld.submodel^.Objects[i]; {get the current frame object}

		{place the animation name to the array of frame names, however, first the name
       must be converted into a regular pascal string}
      data^.AnimNames[i] := tempFrame^.sName;

      {allocate memory for vertices}
      oxmAddObjectVertices(cFrame^, nVertices);
      if(oxError <> 0) then
         exit;

      for j := 0 to nVertices-1 do begin
         {$R-}
         cFrame^.Vertices[j][0] :=
           (tempFrame^.Vertices[j].vertex[0] * tempFrame^.scale[0] + tempFrame^.translate[0]); {x}

         cFrame^.Vertices[j][1] :=
            (tempFrame^.Vertices[j].vertex[2] * tempFrame^.scale[2] + tempFrame^.translate[2]); {z}

         cFrame^.Vertices[j][2] :=
            -(tempFrame^.Vertices[j].vertex[1] * tempFrame^.scale[1] + tempFrame^.translate[1]); {y}
      end;
   end;
end;

{read in the OpenGL commands}
procedure md2ReadGLCommands(var ld: oxmTLoaderData);
var
   data: md2PData;
   nglCommands: int32;

begin
   data := ld.data;

   nglCommands := data^.Header.nglCommands;
   data^.Model.nglCommands := nglCommands;

   SetLength(data^.Model.glCommands, nglCommands);
   if(Length(data^.Model.glCommands) < nglCommands) then begin 
      oxmeRaise(eNO_MEMORY); 
      exit; 
   end;

   oxmlSeek(ld, data^.Header.offsetglCommands);
   if(oxError <> 0) then
      exit;

   oxmlBlockRead(ld, data^.Model.glCommands[0], int64(nglCommands)*(sizeof(GLuint)));
end;

{PROCESS}

{process animations}
procedure md2ProcessAnimations(var ld: oxmTLoaderData);
var
   data: md2PData;

   Anim: oxmTKRAnim; {anim information}
   sName: shortstring         = ''; {anim frame name}
   sNameNum: shortstring      = ''; {anim frame number}
   sPrevName: shortstring     = ''; {name of the previous anim}

   i, j: uint16;
   frameN: uint16             = 0; {frame number}

   valueN: int32              = 0;
   Code: int32; {temporary value storage, code for the string conversion routine}
   sLength, nDigits: uint8; {string length, number of digits in the string}

begin
   data := ld.data;

   {This routine process animation frames. By analyzing the animation frame
   names (md2AnimNames) it determines which animations there are, how much
   frames they have (and therefore also figure at which frame they start
   and end).}

   {$IFDEF DO_EXTRA_LOGGING}
   log.i('Processing animations...');
   {$ENDIF}

   {this is not really necessary, it serves just to shush the compiler}
   if(valueN > 0) then;

   for i := 0 to (ld.submodel^.nObjects-1) do begin
      {get the current frame name and it's length}
      sName    := data^.AnimNames[i];
      sLength  := uint8(sName[0]);

      {it is required to separate these two elements, animation name, and
      animation frame number, and this is a little bit tricky because frame
      names can also have a number at the end}

      {first we will go through all the letters to figure out where the numbers first appear}
      for j := 1 to sLength do begin
         val(sName[j  +1], valueN, Code);
         if(Code = 0) then
            break; {we found a number so break it}
      end;

      {Get the number of digits contained at the end of the name}
      nDigits := sLength-j;

      {although I am not quite sure if this is correct, I believe that if there are only two number digits,
      then the animation does not have a number in the name, and if there are three or more digits then
      we got an animation with a number in the name}
      if(nDigits >= 3) then begin
         sNameNum := copy(sName, sLength-1, 2);
         sName[0] := char(sLength-2);
      end else begin
         sNameNum := copy(sName, sLength-nDigits+1, nDigits);
         sName[0] := char(sLength-nDigits);
      end;

      val(sNameNum, frameN, Code);

      {now, check if the anim name is not the same as that from the previous frame,
      or if this is the last anim frame of the model}
      if(sName <> sPrevName) or (i = ld.submodel^.nObjects-1) then begin
         if(sPrevName <> '') then begin
            {add new empty animation structure}
            oxmAddKRAnim(ld.submodel^);
            if(oxError <> 0) then
               exit;

            {make the name of the new anim equal to the one from previous animation name}
            Anim.sName     := sPrevName;
            Anim.endFrame  := i; {the last frame of animation is j}
            {calculate the number of frames for this animation}
            Anim.nFrames   := Anim.startFrame - Anim.endFrame;

            {assign the animation}
            ld.submodel^.KRAnims[ld.submodel^.nKRAnims-1] := Anim;

            {initialize data for next animation}
            Zero(Anim, sizeof(oxmTKRAnim));
         end;

         {set the first frame of the next animation}
         Anim.StartFrame := frameN - 1 + i;
      end;

      sPrevName := sName;
   end;

   {$IFDEF DO_EXTRA_LOGGING}
   for i := 0 to submodel^.nKRAnims-1 do begin
      log.i('KR Animation Info: '+submodel^.KRAnims[i]^.sName+
            ' | Start: '+sf(submodel^.KRAnims[i]^.startFrame(,
            ' | End: '+sf(submodel^.KRAnims[i]^.endFrame));
   end;
   {$ENDIF}
end;

procedure md2DisposeSpecificData(var m: md2TModel);
begin
   {clean up all the dynamic arrays}
   if(m.Skins <> nil) then
      SetLength(m.Skins, 0);
   if(m.glCommands <> nil) then
      SetLength(m.glCommands, 0);
end;

procedure md2DisposeSpecificData(var model: oxTModel);
begin
   md2DisposeSpecificData(md2PModel(model.SpecificData)^);
   dispose(md2PModel(model.SpecificData));
end;

{de-initialization}
procedure md2DeInitialize(var ld: oxmTLoaderData);
var
   data: md2PData;

begin
   data              := ld.data;
   ld.mdl^.Version   := data^.Header.Version;

   {save the specific data}
   if(oxmcStoreSpecificData = true) then begin
      new(md2PModel(ld.mdl^.SpecificData));
      if(ld.mdl^.SpecificData <> nil) then
         move(data^.Model, ld.mdl^.SpecificData^, SizeOf(md2TModel));
   end;

   {free memory used by the md2 loader}
   if(data^.AnimNames <> nil) then begin
      SetLength(data^.AnimNames, 0); 
      data^.AnimNames := nil;
   end;

   dispose(md2PData(ld.data)); 
   ld.data := nil;
end;

{assign the material from the first skin with the model, if any}
procedure md2AssignMaterials(var ld: oxmTLoaderData);
var
   pMaterial: oxPMaterial;
   pObject: oxmPObject;

begin
   pMaterial := oxmGetFirstMaterial(ld.mdl^);
   if(pMaterial <> nil) then begin
      pObject := oxmGetFirstObject(ld.mdl^);
      if(pObject <> nil) then
         pObject^.matID := 1;
   end;
end;

{LOAD ROUTINE}
procedure md2Load(data: pointer);
var
   ld: oxmPLoaderData;

begin
   ld := data;

   { INITIALIZE }
   md2Init(ld^);

   {LOAD}
   {read header}
   md2ReadHeader(ld^);
   if(oxError <> 0) then
      exit; {exit if any errors have been detected}

   {initialize model data}
   md2InitModel(ld^);
   if(oxError <> 0) then
      exit;

   {read through the data}
   md2ReadSkinData(ld^);
   if(oxError <> 0) then
      exit;

   md2ReadTexCoordData(ld^);
   if(oxError <> 0) then
      exit;

   md2ReadFaceData(ld^);
   if(oxError <> 0) then
      exit;

   md2ReadFrameData(ld^);
   if(oxError <> 0) then
      exit;

   {PROCESS}
   md2ProcessAnimations(ld^);

   oxmlSetupSimpleSkins(ld^, '');
   if(oxError <> 0) then
      exit;
   md2AssignMaterials(ld^);

   ld^.mdl^.mHandler := @oxmMD2Handler;

   {DEINITIALIZE}
   md2DeInitialize(ld^);
end;

INITIALIZATION
   md2Ext.ext           := '.md2';
   md2Ext.Handler       := @md2Loader;

   md2Loader.Name       := 'MD2';
   md2Loader.Handle     := @md2Load;

   oxmLoaderInfo.RegisterExt(md2Ext);
   oxmLoaderInfo.RegisterHandler(md2Loader);

   oxmMD2Handler.Dispose := oxTModelHandlerDisposeProc(@md2DisposeSpecificData);
END.
