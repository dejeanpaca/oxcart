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
{$IFNDEF MOBILE}
var
   base,
   path: StdString;
{$ENDIF}

begin
   {$IFNDEF MOBILE}
   base := 'data.ypk';
   path := oxPaths.Find(base);

   if(path <> '') then
      ypkfs.Add(path)
   else
      log.e('Could not find ' + base + ' pack file');
   {$ELSE}
      {$IFDEF ANDROID}
      oxAndroidAssets.Initialize();
      {$ENDIF}
   {$ENDIF}
end;

procedure deinit();
begin
   ypkfs.Unmount();
end;

INITIALIZATION
   ox.PreInit.Add('pack_mounter', @init, @deinit);

END.
