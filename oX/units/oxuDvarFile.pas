{
   oxuDvarFile, dvar file helper
   Copyright (C) 2020. Dejan Boras
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

      BeforeLoad,
      AfterLoad,
      BeforeSave,
      AfterSave: TProcedure;

      constructor Create(var useDvg: TDVarGroup);

      function GetFn(): StdString; virtual;
      procedure Load();
      procedure Save();
   end;

IMPLEMENTATION

{ oxTDvarFile }

constructor oxTDvarFile.Create(var useDvg: TDVarGroup);
begin
   Enabled := true;
   dvg := @useDvg;
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
      if(BeforeLoad <> nil) then
         BeforeLoad();

      fn := GetFn();
      dvarf.ReadText(dvg^, fn);
      log.v('Loaded: ' + fn);

      if(AfterLoad <> nil) then
         AfterLoad();
   end;
end;

procedure oxTDvarFile.Save();
var
   fn: StdString;

begin
   if Enabled and (dvg <> nil) then begin
      if(BeforeSave <> nil) then
         BeforeSave();

      fn := GetFn();
      dvarf.WriteText(dvg^, fn);
      log.v('Saved: ' + fn);

      if(AfterSave <> nil) then
         AfterSave();
   end;
end;

END.
