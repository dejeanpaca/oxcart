{
   oxuTexPax, texture packing
   Copyright (C) 2013. Dejan Boras
   
   Started On:    07.04.2013.

   Reference: https://github.com/jakesgordon/bin-packing/
}

{$INCLUDE oxdefines.inc}
UNIT oxuTexPax;

INTERFACE

   USES
      uStd, uImage, imguRW, imguOperations, StringUtils,
         oxuFile, oxufPackedTexture;

CONST
   oxeTEXTURE_PACKER_SIZE_INVALID        = 100;

TYPE
   oxPTexturePackerNode = ^oxTTexturePackerNode;

   oxTTexturePackerNode = record
      used: boolean; {is the node used}
     
      x, 
      y, 
      w, 
      h: longint; {horizontal/vertical position, width/height}
      
      right,
      down: oxPTexturePackerNode;
   end;

   oxPTexturePackerImage  = ^oxTTexturePackerImage;
   oxTTexturePackerImage = record
      filename: string;
      width,
      height: longint;
      fit: oxPTexturePackerNode;
      image: imgPImage;

      errorCode, 
      packerErrorCode: longint;
   end;

   { oxTTexturePacker }

   oxTTexturePacker = class
      textures: array of oxTTexturePackerImage;

      root: oxPTexturePackerNode;
      {target image to be built out of the textures}
      target: imgTImage;

      {fill with random color instead of images}
      fillRandom: boolean;
      {fill with random color on error}
      fillRandomOnError: boolean;

      {filename into which the target image was written}
      outFileName: string;

      {are there any textures with transparency (alpha channel)}
      hasTransparentTextures: boolean;
      {has the image been built}
      imageBuilt: boolean;
   public
      constructor create();
      destructor Destroy(); override;

      { TEXTURES }

      {sort the textures, default implementation should suffice and uses quicksort}
      procedure sortTextures(); virtual;
      {adds a texture file}
      function addTexture( const fn: string ): oxPTexturePackerImage;

      {loads texture image}
      procedure loadTexture(var img: oxTTexturePackerImage);
      {loads all textures}
      procedure loadTextures();
      {disposes of textures}
      procedure disposeTextures();

      { FITTING (building a binary tree) }

      {fits all textures}
      procedure fitAll();
      {fits a single texture}
      procedure fit( var texture: oxTTexturePackerImage );

      { node management }

      function  findNode( const node: oxTTexturePackerNode; w, h: longint ): oxPTexturePackerNode;
      function  splitNode( var node: oxTTexturePackerNode; w, h: longint ): oxPTexturePackerNode;

      function  growNode( w, h: longint ): oxPTexturePackerNode;
      function  growRight( w, h: longint ): oxPTexturePackerNode;
      function  growDown( w, h: longint ): oxPTexturePackerNode;

      function  getNode(): oxPTexturePackerNode; static;
      function  getNode( x, y, w, h: longint ): oxPTexturePackerNode; static;
      procedure disposeNode(var node: oxPTexturePackerNode);

      { IMAGE }
      {builds the final image}
      procedure buildImage();
      {fits a single texture into the image}
      procedure fitImage(var img: oxTTexturePackerImage);
      {fits the texture are into the image with a random color instead of the image contents}
      procedure fitImageRandomColor(var img: oxTTexturePackerImage);
      {writes the image into a file (image writers must be included)}
      procedure writeImage(const fn: string);
      {disposes of the final image}
      procedure disposeImage();

      { STORE }

      {store the packed data into JSON}
      function outputJSON(const fn: string): longint;

      {store the packed data into oX format}
      function outputOX(const fn: string): longint;

   private
      procedure quicksort();
   end;

IMPLEMENTATION

constructor oxTTexturePacker.create;
begin
end;

destructor oxTTexturePacker.Destroy();
begin
   inherited;

   disposeTextures();
   disposeImage();
   disposeNode(root);
end;

{ TEXTURES }

{quick sort the texture list by size, from largest to smallest}
procedure sort(var ar: array of oxTTexturePackerImage; lo, up: longint);
var
   i, j: longint;
   temp: oxTTexturePackerImage;

begin
   while(up > lo) do begin
      i := lo;
      j := up;
      temp := ar[lo];
      {split the array in two}
      while(i < j) do begin
         while((ar[j].width * ar[j].height) < (temp.width * temp.height)) do
            j := j - 1;
         ar[i] := ar[j];
         while(i < j) and ((ar[i].width * ar[i].height) >= (temp.width * temp.height)) do
            i := i + 1;
         ar[j] := ar[i];
      end;
      ar[i] := temp;
      {sort recursively}
      sort(ar, lo, i - 1);
      lo := i + 1;
   end;
end;

procedure oxTTexturePacker.quicksort();
begin
   sort(textures, low(textures), high(textures));
end;

procedure oxTTexturePacker.sortTextures();
begin
   quicksort();
end;

function oxTTexturePacker.addTexture(const fn: string): oxPTexturePackerImage;
var
   n: longint;
   tex: oxPTexturePackerImage;

begin
   n := length(textures) + 1;

   SetLength(textures, n);
   tex := @textures[n-1];

   tex^.filename := fn;

   result := tex;
end;

procedure oxTTexturePacker.loadTexture(var img: oxTTexturePackerImage);
begin
   if(img.image = nil) then begin
      img.image := imgMake();

      if(img.image <> nil) then begin
         img.errorCode := imgLoad(img.image^, img.filename);

         if(img.errorCode = 0) then begin
            imgSetOrigin(img.image^, imgcORIGIN_TL);

            if(imgHasAlpha(img.image^)) then begin
               hasTransparentTextures := true;
               imgTransform(img.image^, PIXF_BGRA);
            end else
               imgTransform(img.image^, PIXF_BGR);

            if(img.image <> nil) then begin
               img.width   := img.image^.width;
               img.height  := img.image^.height;
            end;
         end;
      end else
         img.errorCode := eNO_MEMORY;
   end;
end;

procedure oxTTexturePacker.loadTextures();
var
   i: longint;

begin
   for i := 0 to length(textures) - 1 do begin
      loadTexture(textures[i]);
   end;
end;

procedure oxTTexturePacker.disposeTextures;
var
   i: longint;

begin
   if(length(textures) > 0) then begin
      for i := 0 to length(textures)-1 do begin
         if(textures[i].image <> nil) then begin
            imgDispose(textures[i].image);
         end;
      end;

      SetLength(textures, 0);
   end;
end;


{ FITTING }

procedure oxTTexturePacker.fitAll();
var
   w, h, i, n: longint;

begin
   n := length(textures);

   if (n > 0) then begin
      w     := textures[0].Width;
      h     := textures[0].Height;

      root  := getNode(0, 0, w, h);

      for i := 0 to (n - 1) do begin
         fit(textures[i]);
      end;
   end;
end;

procedure oxTTexturePacker.fit(var texture: oxTTexturePackerImage);
var
   node: oxPTexturePackerNode;

begin
   node := findNode(root^, texture.width, texture.height);
   if(node <> nil) then
      texture.fit := splitNode(node^, texture.width, texture.height);
   else
      texture.fit := growNode(texture.width, texture.height);
end;

function oxTTexturePacker.findNode(const node: oxTTexturePackerNode; w, h: longint): oxPTexturePackerNode;
var
   sub: oxPTexturePackerNode;

begin
   if (@node <> nil) then begin
      if (node.used) then begin
         sub := findNode(node.right^, w, h);
         if (sub <> nil) then
            exit(sub)
         else
            exit(findNode(node.down^, w, h));
      end else if ((w <= node.w) and (h <= node.h)) then
         exit(@node);
   end;

   result := nil;
end;

function oxTTexturePacker.splitNode(var node: oxTTexturePackerNode; w, h: longint): oxPTexturePackerNode;
begin
   node.used   := true;

   node.down   := getNode(node.x,      node.y + h, node.w,        node.h - h);
   node.right  := getNode(node.x + w,  node.y,     node.w - w,    h);

   result      := @node;
end;

function oxTTexturePacker.growNode(w, h: longint): oxPTexturePackerNode;
var
   canGrowDown, canGrowRight, shouldGrowRight, shouldGrowDown: boolean;

begin
   canGrowDown       := w <= root^.w;
   canGrowRight      := h <= root^.h;

   shouldGrowRight   := canGrowRight and  (root^.h >= (root^.w + w));
   shouldGrowDown    := canGrowDown  and  (root^.w >= (root^.h + h));

   if (shouldGrowRight) then
      result := growRight(w, h)
   else if (shouldGrowDown) then
      result := growDown(w, h)
   else if (canGrowRight) then
      result := growRight(w, h)
   else if (canGrowDown) then
      result := growDown(w, h)
   else
      result := nil;
end;

function oxTTexturePacker.growRight(w, h: longint): oxPTexturePackerNode;
var
   node, sub: oxPTexturePackerNode;

begin
   node := getNode(0, 0, root^.w + w, root^.h);
   node^.used  := true;
   node^.right := getNode(root^.w, 0, w, root^.h);
   node^.down  := root;

   root := node;

   sub := findNode(root^, w, h);
   if (sub <> nil) then
      result := splitNode(sub^, w, h)
   else
      result := nil;
end;

function oxTTexturePacker.growDown(w, h: longint): oxPTexturePackerNode;
var
   node, sub: oxPTexturePackerNode;

begin
   node := getNode(0, 0, root^.w, root^.h + h);
   node^.used  := true;
   node^.right := root;
   node^.down  := getNode(0, root^.h, root^.w, h);

   root := node;

   sub := findNode(root^, w, h);
   if (sub <> nil) then
      result := splitNode(sub^, w, h)
   else
      result := nil;
end;

function oxTTexturePacker.getNode(): oxPTexturePackerNode;
var
   node: oxPTexturePackerNode = nil;

begin
   new(node);
   if (node <> nil) then
      ZeroOut(node^, SizeOf(oxTTexturePackerNode));

   result := node;
end;

function oxTTexturePacker.getNode(x, y, w, h: longint): oxPTexturePackerNode;
var
   node: oxPTexturePackerNode;

begin
   node := getNode();

   if (node <> nil) then begin
      node^.x := x;
      node^.y := y;
      node^.w := w;
      node^.h := h;
   end;

   result := node;
end;

procedure oxTTexturePacker.disposeNode(var node: oxPTexturePackerNode);
begin
   if(node <> nil) then begin
      if(node^.right <> nil) then
         disposeNode(node^.right);

      if(node^.down <> nil) then
         disposeNode(node^.down);

      dispose(node);
      node := nil;
   end;
end;

{ IMAGE }

procedure oxTTexturePacker.buildImage();
var
   i, pixF: longint;

begin
   if(root <> nil) then begin
      if(not hasTransparentTextures) then
         pixF := PIXF_BGR
      else
         pixF := PIXF_BGRA;

      imgCreateBlank(target, root^.w, root^.h, pixF);
      target.Origin := imgcORIGIN_TL;

      if(fillRandom or fillRandomOnError) then begin
         randomize();
      end;

      for i := 0 to length(textures)-1 do
         fitImage(textures[i]);

      imageBuilt := true;
   end;
end;

procedure oxTTexturePacker.fitImage(var img: oxTTexturePackerImage);
begin
   if(img.fit <> nil) then begin
      {load the image, if not already}
      loadTexture(img);

      if(not fillRandom) then begin
         if(img.errorCode = 0) then begin
            if(img.image <> nil) then begin
               if(img.width = img.image^.width) and (img.height = img.image^.height) and (img.width > 0) and (img.height > 0) then begin
                  {copy image to the target}
                  imgCopyArea(img.image^, target, 0, 0, img.fit^.x, img.fit^.y, img.width, img.height);
               end else begin
                  img.errorCode := oxeTEXTURE_PACKER_SIZE_INVALID;
               end;
            end else begin
               img.errorCode := eINVALID;
            end;
         end;

         if(img.errorCode <> 0) and (fillRandomOnError) then begin
            fitImageRandomColor(img);
         end;
      end else begin
         fitImageRandomColor(img);
      end;
   end;
end;

procedure oxTTexturePacker.fitImageRandomColor(var img: oxTTexturePackerImage);
var
   c: qword;
   color: array[0..3] of byte absolute c;

begin
   if(img.fit <> nil) then begin
      color[0] := random(256);
      color[1] := random(256);
      color[2] := random(256);
      color[3] := 255;

      if(img.width > 0) and (img.height > 0) then
         imgFill(target, img.fit^.x, img.fit^.y, img.width, img.height, c);
   end;
end;

procedure oxTTexturePacker.writeImage(const fn: string);
begin
   if(fn <> '') then begin
      if(outFileName = '') then
         outFileName := fn;

      if(target.image <> nil) then begin
         imgWrite(target, fn);
      end;
   end;
end;

procedure oxTTexturePacker.disposeImage();
begin
   imgDispose(target);
end;

{ STORE }

function oxTTexturePacker.outputJSON(const fn: string): longint;
var
   f: text;
   i,
   n, 
   errorCode: longint;

procedure writeTexture(id: longint; var tex: oxTTexturePackerImage);
begin
   if(tex.fit <> nil) then begin
      writeln(f, #9'"tex_'+sf(id)+'": {');

      writeln(f, #9#9'"fn": "' + tex.filename + '",');
      writeln(f, #9#9'"x": ' + sf(tex.fit^.x) + ',');
      writeln(f, #9#9'"y": ' + sf(tex.fit^.y) + ',');
      writeln(f, #9#9'"w": ' + sf(tex.width) + ',');
      writeln(f, #9#9'"h": ' + sf(tex.height));

      if(id < n-1) then
         writeln(f, #9'},')
      else
         writeln(f, #9'}');
   end;
end;

procedure cleanup();
var
   closeErrorCode: longint;

begin
   close(f);
   closeErrorCode := ioresult();
   if(errorCode = 0) then
      errorCode := closeErrorCode;
end;

begin
   FileRewrite(f, fn);
   errorCode := ioerror();
   if(errorCode = 0) then begin
      n := length(textures);

      writeln(f, '{');

      writeln(f, #9'"count": ' + sf(n) + ',');
      write(f, #9'"target": "' + outFileName + '"');
      if(n > 0) then
         writeln(f, ',');

      for i := 0 to n - 1 do
         writeTexture(i, textures[i]);

      writeln(f, '}');
      cleanup();
   end;

   result := errorCode;
end;

function oxTTexturePacker.outputOX(const fn: string): longint;
begin
   result := 0;
end;

END.
