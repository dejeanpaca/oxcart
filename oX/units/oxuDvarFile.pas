{
   oxuDvarFile, dvar file helper
   Copyright (C) 2020. Dejan Boras

   Started On:    20.10.2020.
}

{$INCLUDE oxdefines.inc}
UNIT oxuDvarFile;

INTERFACE

   USES
      uStd, uLog, udvars, dvaruFile,
      appuPaths;

TYPE
   { oxTDvarFile }

   oxTDvarFile = object
      Enabled: boolean;
      dvg: PDVarGroup;
      {path to where the file will be stored (if empty configuration directory is used)}
      Path,
      {file name of the dvar file (can also include a relative path to Path)}
      FileName: StdString;

      constructor Create();

      function GetFn(): StdString; virtual;
      procedure Load();
      procedure Save();
   end;

IMPLEMENTATION

{ oxTDvarFile }

constructor oxTDvarFile.Create();
begin
   Enabled := true;
end;

function oxTDvarFile.GetFn(): StdString;
begin
   if(Path <> '') then
      Result := Path + FileName
   else
      Result := appPath.Configuration.Path + FileName;
end;

procedure oxTDvarFile.Load();
var
   fn: StdString;

begin
   if Enabled and (dvg <> nil) then begin
      fn := GetFn();
      dvarf.ReadText(dvg^, fn);
      log.v('Loaded: ' + fn);
   end;
end;

procedure oxTDvarFile.Save();
var
   fn: StdString;

begin
   if Enabled and (dvg <> nil) then begin
      fn := GetFn();
      dvarf.WriteText(dvg^, fn);
      log.v('Saved: ' + fn);
   end;
end;

END.
