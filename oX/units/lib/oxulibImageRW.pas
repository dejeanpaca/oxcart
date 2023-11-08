{
   oxulibImageRW, includes image loaders/writers in library mode
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxulibImageRW;

INTERFACE

   USES
      uLog,
      uOX, oxuGlobalInstances,
      imguRW;

IMPLEMENTATION

procedure init();
var
   f: imgPFile;

begin
   f := oxExternalGlobalInstances^.FindInstancePtr('imgTFile');

   if(f <> nil) then begin
      imgFile.Readers := f^.Readers;
      imgFile.Writers := f^.Writers;
   end;
end;

INITIALIZATION
   ox.PreInit.Add('lib.image_loaders', @init);

END.
