{
   oxeduProjectSettings, project settings for projects
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduProjectSettings;

INTERFACE

   USES
      sysutils, uStd, uLog, udvars, dvaruFile, uFileUtils,
      uAppInfo,
      {oxed}
      uOXED, oxeduProject, oxeduPackage, oxeduProjectConfigurationFileHelper, oxeduPlatform,
      oxeduConsole, oxeduSettings;

CONST
   OXED_PROJECT_SETTINGS_FILE = 'settings.dvar';

VAR
   oxedProjectSettingsFile: oxedTProjectConfigurationFileHelper;

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
   dvLineEndings,
   dvPlatformEnabled: TDVar;

   stringValue: StdString;

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

procedure validateLoad();
begin
   if(oxedProject.Name = '') then begin
      oxedProject.Name := 'project';
      oxedConsole.w('Project name not valid, reset to default');
   end;

   if(oxedProject.Identifier = '') then begin
      oxedProject.SetIdentifier(oxedProject.Name);

      oxedConsole.w('Project identifier not valid, reset to default');
   end;

   if(oxedProject.NormalizedIdentifier(oxedProject.Identifier) <> oxedProject.Identifier) then begin
      oxedProject.SetIdentifier(oxedProject.Name);

      oxedConsole.w('Project identifier not valid, reset to default');
   end;

   if(oxedProject.LineEndings = '') then
      oxedProject.LineEndings := oxedSettings.LineEndings;
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

procedure dvPlatformEnabledNotify(var context: TDVarNotificationContext);
var
   i: loopint;
   platform: oxedTPlatform;

begin
   if(context.What = DVAR_NOTIFICATION_READ) then begin
      platform := oxedPlatforms.FindById(stringValue);

      if(platform <> nil) and (platform.Id <> 'editor') then
         oxedPlatforms.Enable(platform);
   end else if(context.What = DVAR_NOTIFICATION_WRITE) then begin
      context.Result := 0;

      for i := 1 to oxedPlatforms.List.n - 1 do begin
         platform := oxedPlatforms.List[i];

         if(platform.Enabled) then
            dvarPFileData(context.f)^.Write(context.Parent, dvPlatformEnabled, platform.Id);
      end;
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

   dvGroup.Add(dvRunParameter, 'run_parameter', dtcSTRING, @stringValue, [dvarNOTIFY_READ, dvarNOTIFY_WRITE]);
   dvRunParameter.pNotify := @dvRunParameterNotify;

   dvGroup.Add(dvFeature, 'feature', dtcSTRING, @stringValue, [dvarNOTIFY_READ, dvarNOTIFY_WRITE]);
   dvFeature.pNotify := @dvFeatureNotify;

   dvGroup.Add(dvPlatformEnabled, 'platform_enabled', dtcSTRING, @stringValue, [dvarNOTIFY_READ, dvarNOTIFY_WRITE]);
   dvPlatformEnabled.pNotify := @dvPlatformEnabledNotify;

   oxedProjectSettingsFile.Create(dvGroup);
   oxedProjectSettingsFile.FileName := OXED_PROJECT_SETTINGS_FILE;

   oxedProjectSettingsFile.BeforeLoad := @UpdateVars;
   oxedProjectSettingsFile.AfterLoad := @validateLoad;
   oxedProjectSettingsFile.BeforeSave := @UpdateVars;

END.
