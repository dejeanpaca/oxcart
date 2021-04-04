{
   oxuglLibraryInfo, OpenGL information
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuglLibraryInfo;

INTERFACE

   USES
      uLog, uStd,
      {ox}
      oxuGlobalInstances,
      oxuglExtensions, oxuglRendererInfo;

procedure oglLibraryGetInformation();

IMPLEMENTATION

procedure oglLibraryGetInformation();
var
   info: oxglPRendererInfo;

begin
   info := oxExternalGlobalInstances^.FindInstancePtr('oxglTRendererInfo');

   if(info <> nil) then
      oxglRendererInfo := info^
   else
      log.w('Could not find reference to oxglTRendererInfo');

   oglExtensions.Get();
end;

INITIALIZATION

END.
