{
   texpax, texture packer

   Started On:    02.04.2013.
   Last Update:   26.05f2.2013.
}

{$MODE OBJFPC}{$H+}
PROGRAM texpax;

   USES ConsoleUtils, ParamUtils, StringUtils, uFileStd,
      {image}
      uImage, imguRW, {$INCLUDE imgIncludeAllLoaders.inc}, imguwTGA,
      {oX}
      oxuTexPax, oxufPackedTexture, oxuPackedTexture;

VAR
   pack: oxTTexturePacker;
   outFileName: string = 'out.tga';

procedure haltProgram(const s: string);
begin
   if(s <> '') then
      conWriteln(s);
   halt(1);
end;

function params(const pstr: string; const lstr: string): boolean;
begin
   if(lstr = '-r') then begin
      pack.fillRandom := true;
   end else if(lstr = '-o') then begin
      outFileName := nextParameter();
      if(outFileName = '') then begin
         haltProgram('Missing outpout file name (-o)');
      end;
   end else begin
      pack.addTexture(pstr);
   end;

   result := true;
end;

procedure writeHelp();
begin
   conWriteln('texpax [options] file1 file2 file3 ...');
end;

procedure writeLoadFailedTextures();
var
   i: longint;

begin
   for i := 0 to length(pack.textures)-1 do begin
      if(pack.textures[i].errorCode <> 0) then begin
         conWriteln('Failed to load texture: '+pack.textures[i].filename+' with error code: '+dStr(pack.textures[i].errorCode));
      end;
   end;
end;

procedure writeTextureBuildFailures();
var
   i: longint;

begin
   for i := 0 to length(pack.textures)-1 do begin
      if(pack.textures[i].errorCode <> 0) then begin
         conWriteln('Failed to fit texture: '+pack.textures[i].filename+' with error code: '+dStr(pack.textures[i].errorCode));
      end;
   end;
end;

procedure saveJSON();
var
   errorCode: longint;

begin
   errorCode := pack.outputJSON(dExtractAllNoExt(outFileName)+'.json');
   if(errorCode <> 0) then begin
      writeln('Failed to save JSON with error code: ', errorCode);
   end;
end;

BEGIN
   pack := oxTTexturePacker.Create();

   ProcessParameters(@params);

   if(length(pack.textures) > 0) then begin
      pack.loadTextures();
      pack.sortTextures();
      writeLoadFailedTextures();

      pack.fitAll();
      if(pack.root <> nil)  then begin
         conWriteln('final image size: '+dStr(pack.root^.w) + 'x' + dStr(pack.root^.h));

         pack.buildImage();
         writeTextureBuildFailures();
         pack.writeImage('out.tga');
      end;
   end else begin
      conWriteln('No textures specified.');
      writeHelp();
      haltProgram('');
   end;

   saveJSON();

   pack.free();
END.
