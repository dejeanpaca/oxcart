{
   oxeduProjectSettings, project settings for projects
   Copyright (C) 2017. Dejan Boras

   Started On:    04.05.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectSettings;

INTERFACE

   USES
      sysutils, uStd, uLog, udvars, dvaruFile, uFileUtils,
      uAppInfo,
      {oxed}
      uOXED, oxeduProject, oxeduPackage,
      oxeduMessages, oxeduSettings;

CONST
   OXED_PROJECT_SETTINGS_FILE = 'settings.dvar';

TYPE

   { oxedTProjectSettings }

   oxedTProjectSettings = record
      class function GetFn(): StdString; static;

      class procedure Load(); static;
      class procedure Save(); static;
   end;

IMPLEMENTATION

VAR
   dvGroup: TDVarGroup;

   dvName,
   dvShortName,
   dvIdentifier,
   dvOrganization,
   dvOrganizationShort,
   dvMainUnit,
   dvRunParameter,
   dvFeature,
   dvLineEndings: TDVar;

   stringValue: StdString;

{ oxedTProjectSettings }

class function oxedTProjectSettings.GetFn(): StdString;
begin
   Result := oxedProject.GetConfigFilePath(OXED_PROJECT_SETTINGS_FILE);
end;

procedure UpdateVars();
begin
   dvName.Update(oxedProject.Name);
   dvShortName.Update(oxedProject.ShortName);
   dvIdentifier.Update(oxedProject.Identifier);
   dvOrganization.Update(oxedProject.Organization);
   dvOrganizationShort.Update(oxedProject.OrganizationShort);
   dvMainUnit.Update(oxedProject.MainUnit);
   dvLineEndings.Update(oxedProject.LineEndings);
end;

class procedure oxedTProjectSettings.Load();
begin
   UpdateVars();

   dvarf.ReadText(dvGroup, GetFn());

   if(oxedProject.Name = '') then begin
      oxedProject.Name := 'project';
      oxedMessages.w('Project name not valid, reset to default');
   end;

   if(oxedProject.Identifier = '') then begin
      oxedProject.SetIdentifier(oxedProject.Name);

      oxedMessages.w('Project identifier not valid, reset to default');
   end;

   if(oxedProject.NormalizedIdentifier(oxedProject.Identifier) <> oxedProject.Identifier) then begin
      oxedProject.SetIdentifier(oxedProject.Name);

      oxedMessages.w('Project identifier not valid, reset to default');
   end;

   if(oxedProject.LineEndings = '') then
      oxedProject.LineEndings := oxedSettings.LineEndings;
end;

class procedure oxedTProjectSettings.Save();
begin
   UpdateVars();

   dvarf.WriteText(dvGroup, GetFn());
end;

procedure dvRunParameterNotify(var context: TDVarNotificationContext);
begin
   if(context.What = DVAR_NOTIFICATION_READ) then
      oxedProject.RunParameters.Add(stringValue)
   else if(context.What = DVAR_NOTIFICATION_WRITE) then begin
      context.Result := 0;

      dvarPFileData(context.f)^.Write(context.Parent, dvRunParameter, oxedProject.RunParameters.List, oxedProject.RunParameters.n);
   end;
end;

procedure dvFeatureNotify(var context: TDVarNotificationContext);
begin
   if(context.What = DVAR_NOTIFICATION_READ) then
      oxedProject.Features.Add(stringValue)
   else if(context.What = DVAR_NOTIFICATION_WRITE) then begin
      context.Result := 0;

      dvarPFileData(context.f)^.Write(context.Parent, dvFeature, oxedProject.Features.List, oxedProject.Features.n);
   end;
end;

procedure dvMainUnitNotify(var context: TDVarNotificationContext);
begin
   if(context.What = DVAR_NOTIFICATION_WRITE) then begin
      context.Result := 0;

      if(oxedProject.MainUnit <> '') then
         dvarPFileData(context.f)^.Write(context.Parent, context.DVar^, oxedProject.MainUnit);
   end;
end;

INITIALIZATION
   dvar.Init(dvGroup);
   dvGroup.Name := 'project';

   dvGroup.Add(dvName, 'name', dtcSTRING, @oxedProject.Name);
   dvGroup.Add(dvShortName, 'short_name', dtcSTRING, @oxedProject.ShortName);
   dvGroup.Add(dvIdentifier, 'identifier', dtcSTRING, @oxedProject.Identifier);
   dvGroup.Add(dvOrganization, 'organization', dtcSTRING, @oxedProject.Organization);
   dvGroup.Add(dvOrganizationShort, 'organization_short', dtcSTRING, @oxedProject.OrganizationShort);
   dvGroup.Add(dvLineEndings, 'line_endings', dtcSTRING, @oxedProject.LineEndings);

   dvGroup.Add(dvMainUnit, 'main_unit', dtcSTRING, @oxedProject.MainUnit, [dvarNOTIFY_WRITE]);
   dvMainUnit.pNotify := @dvMainUnitNotify;

   dvGroup.Add(dvRunParameter, 'run_parameter', dtcSTRING, @stringValue, [dvarNOTIFY_WRITE]);
   dvRunParameter.pNotify := @dvRunParameterNotify;

   dvGroup.Add(dvFeature, 'feature', dtcSTRING, @stringValue, [dvarNOTIFY_WRITE]);
   dvFeature.pNotify := @dvFeatureNotify;

END.
