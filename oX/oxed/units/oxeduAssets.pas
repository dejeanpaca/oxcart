{
   oxeduAssets, oxed asset management
   Copyright (C) 2020. Dejan Boras

   TODO: Ignore oX data files which are not used
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAssets;

INTERFACE

   USES
      uStd, StringUtils, uLog,
      {ox}
      oxuPaths,
      {oxed}
      uOXED, oxeduPackage;

TYPE

   { oxedTAssets }

   oxedTAssets = record
      {a package containing oX data (assets)}
      oxDataPackage: oxedTPackage;

      {ignore these file types when building (don't copy over)}
      IgnoreFileTypes,
      ProjectIgnoreFileTypes: TSimpleStringList;

      function ShouldIgnore(const ext: StdString): boolean;
   end;

VAR
   oxedAssets: oxedTAssets;

IMPLEMENTATION

{ oxedTAssets }

function oxedTAssets.ShouldIgnore(const ext: StdString): boolean;
{$IFDEF WINDOWS}
var
   lext: StdString;
{$ENDIF}

begin
   {$IFDEF WINDOWS}
   lext := LowerCase(ext);

   if(IgnoreFileTypes.FindLowercase(lext) >= 0) or (ProjectIgnoreFileTypes.FindLowercase(lext) >= 0) then
     exit(true);
   {$ELSE}
   if(IgnoreFileTypes.Find(ext) >= 0) or (ProjectIgnoreFileTypes.Find(ext) >= 0) then
     exit(true);
   {$ENDIF}

   Result := false;
end;

procedure init();
begin
   oxedAssets.oxDataPackage.Id := 'ox';
   oxedAssets.oxDataPackage.Path := oxPaths.BasePath + 'data' + DirectorySeparator;
end;

INITIALIZATION
   oxed.Init.Add('assets', @init);

   TSimpleStringList.Initialize(oxedAssets.IgnoreFileTypes, 256);
   TSimpleStringList.Initialize(oxedAssets.ProjectIgnoreFileTypes, 256);

   oxedAssets.IgnoreFileTypes.Add('.pas');
   oxedAssets.IgnoreFileTypes.Add('.pp');
   oxedAssets.IgnoreFileTypes.Add('.inc');
   oxedAssets.IgnoreFileTypes.Add('.gitignore');
   oxedAssets.IgnoreFileTypes.Add('.blend');
   oxedAssets.IgnoreFileTypes.Add('.temp');
   oxedAssets.IgnoreFileTypes.Add('.tmp');
   oxedAssets.IgnoreFileTypes.Add('.md');

END.
