{
   oxeduAssets, oxed asset management
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAssets;

INTERFACE

   USES
      uStd, StringUtils;

TYPE

   { oxedTAssets }

   oxedTAssets = record
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

INITIALIZATION
   TSimpleStringList.Initialize(oxedAssets.IgnoreFileTypes, 256);
   TSimpleStringList.Initialize(oxedAssets.ProjectIgnoreFileTypes, 256);

   oxedAssets.IgnoreFileTypes.Add('.pas');
   oxedAssets.IgnoreFileTypes.Add('.pp');
   oxedAssets.IgnoreFileTypes.Add('.inc');
   oxedAssets.IgnoreFileTypes.Add('.gitignore');
   oxedAssets.IgnoreFileTypes.Add('.blend');
   oxedAssets.IgnoreFileTypes.Add('.temp');
   oxedAssets.IgnoreFileTypes.Add('.tmp');

END.
