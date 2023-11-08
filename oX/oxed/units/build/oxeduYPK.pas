{
   oxeduYPK
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduYPK;

INTERFACE

   USES
      {ypk}
      ypkuFS, ypkuBuilder,
      {oxed}
      uOXED, oxeduBuild;

TYPE
   oxedTYPK = record
      Builder: ypkTBuilder;
   end;

VAR
   oxedYPK: oxedTYPK;

IMPLEMENTATION

procedure onAssets();
begin
   oxedYPK.Builder.Reset();
end;

procedure initialize();
begin
   ypkTBuilder.Initialize(oxedYPK.Builder);
end;

procedure deinitialize();
begin
   oxedYPK.Builder.Dispose();
end;

INITIALIZATION
   oxed.Init.Add('ypk', @initialize, @deinitialize);
   oxedBuild.OnAssets.Add(@onAssets);

END.
