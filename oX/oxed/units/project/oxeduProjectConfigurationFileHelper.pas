{
   oxeduProjectConfigurationFileHelper, project configuration file helper
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduProjectConfigurationFileHelper;

INTERFACE

   USES
      sysutils, uStd, udvars,
      oxuDvarFile,
      {oxed}
      oxeduProject;

TYPE
   { oxedTProjectConfigurationFileHelper }

   oxedTProjectConfigurationFileHelper = object(oxTDvarFile)
      {is this a temporary file}
      IsTemp,
      {is this a session file}
      IsSession: boolean;

      {get file name path based on the type above}
      function GetFn(): StdString; virtual;
   end;

implementation

{ oxedTProjectConfigurationFileHelper }

function oxedTProjectConfigurationFileHelper.GetFn(): StdString;
begin
   if(IsSession) then
      Result := oxedProject.GetSessionFilePath(FileName)
   else if(IsTemp) then
      Result := oxedProject.GetTempFilePath(FileName)
   else
      Result := oxedProject.GetConfigFilePath(FileName);
end;

INITIALIZATION

END.
