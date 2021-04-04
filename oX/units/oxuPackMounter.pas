{
   oxuPackMounter
   Copyright (c) 2021. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuPackMounter;

INTERFACE

USES
   uStd, ypkuFS, uLog,
   {ox}
   uOX, oxuPaths
   {$IFDEF ANDROID}
   , oxuAndroidAssets
   {$ENDIF};

IMPLEMENTATION

procedure init();
var
   base,
     path: StdString;

begin
   base := 'data.ypk';
   path := oxPaths.Find(base);

   if(path <> '') then
      ypkfs.Add(path)
   else
      log.e('Could not find ' + base + ' pack file');
end;

procedure deinit();
begin
   ypkfs.Unmount();
end;

INITIALIZATION
   ox.PreInit.Add('pack_mounter', @init, @deinit);

END.
