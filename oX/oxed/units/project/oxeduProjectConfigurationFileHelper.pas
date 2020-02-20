{
   oxeduProjectConfigurationFileHelper, project configuration file helper
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectConfigurationFileHelper;

INTERFACE

   USES
      sysutils, uStd, udvars, dvaruFile,
      oxuDvarFile,
      {oxed}
      oxeduProject;

TYPE
   { oxedTProjectConfigurationFileHelper }

   oxedTProjectConfigurationFileHelper = object(oxTDvarFile)
      IsTemp: boolean;

      function GetFn(): StdString; virtual;
   end;

implementation

{ oxedTProjectConfigurationFileHelper }

function oxedTProjectConfigurationFileHelper.GetFn(): StdString;
begin
   if(not IsTemp) then
      Result := oxedProject.GetConfigFilePath(FileName)
   else
      Result := oxedProject.GetTempFilePath(FileName);
end;

INITIALIZATION

END.
