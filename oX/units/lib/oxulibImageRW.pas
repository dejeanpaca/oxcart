{
   oxulibImageRW, includes image loaders/writers in library mode
   Copyright (C) 2019. Dejan Boras

   Started On:    17.10.2019.
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
   f := oxExternalGlobalInstances.FindInstancePtr('imgTFile');

   if(f <> nil) then begin
      imgFile.Loaders := f^.Loaders;
      imgFile.Writers := f^.Writers;
   end else
      log.w('Could not find external imgTFile reference');
end;

INITIALIZATION
   ox.PreInit.Add('lib.image_loaders', @init);

END.
