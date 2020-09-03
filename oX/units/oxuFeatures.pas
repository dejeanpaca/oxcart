{
   oxuFeatures, ox features
   Copyright (c) 2018. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuFeatures;

INTERFACE

   USES
      sysutils, uStd;

TYPE
   oxPFeatureDescriptor = ^oxTFeatureDescriptor;
   oxTFeaturePDescriptorList = specialize TSimpleList<oxPFeatureDescriptor>;

   { oxTFeatureDescriptor }

   oxTFeatureDescriptor = record
      Name,
      Description,
      Symbol: string;

      IncludeByDefault: boolean;

      {platforms on which this feature is always excluded}
      ExcludedPlatforms: TStringArray;
      {platforms on which this feature is only included}
      IncludedPlatforms: TStringArray;
      {platforms on which this feature is disabled by default (but can be enabled)}
      DisabledPlatforms: TStringArray;

      function SetExcludedPlatforms(const excluded: array of string): oxPFeatureDescriptor;
      function SetIncludedPlatforms(const included: array of string): oxPFeatureDescriptor;
      {sets platforms for which this feature is disabled by default (but can be enabled)}
      function SetDisabledPlatforms(const disabled: array of string): oxPFeatureDescriptor;
      function IsExcluded(const platform: string): boolean;
      function IsIncluded(const platform: string): boolean;
      function IsEnabled(const platform: string): boolean;

      class procedure Initialize(out f: oxTFeatureDescriptor); static;
   end;

   oxTFeatureList = specialize TSimpleList<oxTFeatureDescriptor>;

   { oxTFeatureListHelper }

   oxTFeatureListHelper = record helper for oxTFeatureList
      {find a feature by its name}
      function FindByName(const name: string): oxPFeatureDescriptor;
   end;

   { oxTFeaturePDescriptorListHelper }

   oxTFeaturePDescriptorListHelper = record helper for oxTFeaturePDescriptorList
      {find a feature by its name}
      function FindByName(const name: string): oxPFeatureDescriptor;
   end;

   { oxTFeaturesGlobal }

   oxTFeaturesGlobal = record
      List: oxTFeatureList;

      function Add(const name, description, symbol: string): oxPFeatureDescriptor;
      function BuildFeatureSymbols(platform: string; isLibrary: boolean = false): TStringArray;
      function GetSupportedFeatures(platform: string; isLibrary: boolean = false): oxTFeaturePDescriptorList;
      function IsSupportedFeature(const feature: oxTFeatureDescriptor;
         platform: string; isLibrary: boolean = false): boolean;

      {find a feature by its name}
      function FindByName(const name: string): oxPFeatureDescriptor;
   end;

VAR
   oxFeatures: oxTFeaturesGlobal;

IMPLEMENTATION

{ oxTFeatureListHelper }

function oxTFeatureListHelper.FindByName(const name: string): oxPFeatureDescriptor;
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      if(List[i].Name = name) then
         exit(@List[i]);
   end;

   Result := nil;
end;

{ oxTFeaturePDescriptorListHelper }

function oxTFeaturePDescriptorListHelper.FindByName(const name: string): oxPFeatureDescriptor;
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      if(List[i]^.Name = name) then
         exit(List[i]);
   end;

   Result := nil;
end;


{ oxTFeatureDescriptor }

function oxTFeatureDescriptor.SetExcludedPlatforms(const excluded: array of string): oxPFeatureDescriptor;
var
   i: loopint;

begin
   SetLength(ExcludedPlatforms, Length(excluded));

   for i := 0 to High(excluded) do begin
      ExcludedPlatforms[i] := excluded[i];
   end;

   Result := @Self;
end;

function oxTFeatureDescriptor.SetIncludedPlatforms(const included: array of string): oxPFeatureDescriptor;
var
   i: loopint;

begin
   SetLength(IncludedPlatforms, Length(included));

   for i := 0 to High(included) do begin
      IncludedPlatforms[i] := included[i];
   end;

   Result := @Self;
end;

function oxTFeatureDescriptor.SetDisabledPlatforms(const disabled: array of string): oxPFeatureDescriptor;
var
   i: loopint;

begin
   SetLength(DisabledPlatforms, Length(disabled));

   for i := 0 to High(disabled) do begin
      DisabledPlatforms[i] := disabled[i];
   end;

   Result := @Self;
end;

function oxTFeatureDescriptor.IsExcluded(const platform: string): boolean;
var
   i: loopint;

begin
   for i := 0 to High(ExcludedPlatforms) do begin
      if(ExcludedPlatforms[i] = platform) then
         exit(true);
   end;

   Result := false;
end;

function oxTFeatureDescriptor.IsIncluded(const platform: string): boolean;
var
   i: loopint;

begin
   if(Length(IncludedPlatforms) > 0) then begin
      for i := 0 to High(IncludedPlatforms) do begin
         if(IncludedPlatforms[i] = platform) then
            exit(true);
      end;

      exit(false);
   end;

   for i := 0 to High(ExcludedPlatforms) do begin
      if(ExcludedPlatforms[i] = platform) then
         exit(false);
   end;

   Result := true;
end;

function oxTFeatureDescriptor.IsEnabled(const platform: string): boolean;
var
   i: loopint;

begin
   if(Length(DisabledPlatforms) > 0) then begin
      for i := 0 to High(DisabledPlatforms) do begin
         if(DisabledPlatforms[i] = platform) then
            exit(false);
      end;
   end;

   Result := true;
end;

class procedure oxTFeatureDescriptor.Initialize(out f: oxTFeatureDescriptor);
begin
   ZeroOut(f, SizeOf(f));
   f.IncludeByDefault := true;
end;

{ oxTFeaturesGlobal }

function oxTFeaturesGlobal.Add(const name, description, symbol: string): oxPFeatureDescriptor;
var
   descriptor: oxTFeatureDescriptor;

begin
   oxTFeatureDescriptor.Initialize(descriptor);

   descriptor.Name := name;
   descriptor.Description := description;
   descriptor.Symbol := symbol;

   List.Add(descriptor);
   Result := List.GetLast();
end;

function oxTFeaturesGlobal.BuildFeatureSymbols(platform: string; isLibrary: boolean): TStringArray;
var
   i: loopint;
   plist: oxTFeaturePDescriptorList;

begin
   plist := GetSupportedFeatures(platform, isLibrary);
   Result := nil;

   if(plist.n > 0) then begin
      SetLength(Result, plist.n);

      for i := 0 to plist.n - 1 do begin
         Result[i] := plist.List[i]^.Symbol;
      end;
   end;
end;

function oxTFeaturesGlobal.GetSupportedFeatures(platform: string; isLibrary: boolean): oxTFeaturePDescriptorList;
var
   i: loopint;

begin
   Result.Initialize(Result);

   for i := 0 to List.n - 1 do begin
      if(IsSupportedFeature(List.List[i], platform, isLibrary)) then
         Result.Add(@List.List[i]);
   end;
end;

function oxTFeaturesGlobal.IsSupportedFeature(const feature: oxTFeatureDescriptor;
   platform: string; isLibrary: boolean): boolean;

begin
   if(feature.IsIncluded(platform)) then begin
      if(isLibrary and feature.IsExcluded('library')) then
         Result := false
      else
         Result := true;
   end else
      Result := false;
end;

function oxTFeaturesGlobal.FindByName(const name: string): oxPFeatureDescriptor;
begin
   Result := List.FindByName(name);
end;

INITIALIZATION
   oxFeatures.List.Initialize(oxFeatures.List);

   oxFeatures.Add('renderer.gl', 'OpenGL renderer', 'OX_RENDERER_GL');

   oxFeatures.Add('renderer.dx11', 'DirectX 11 renderer', 'OX_RENDERER_DX11')^.
      SetIncludedPlatforms(['windows'])^.IncludeByDefault := false;

   oxFeatures.Add('renderer.console', 'Console renderer', 'OX_RENDERER_CONSOLE')^.
      SetExcludedPlatforms(['android'])^.IncludeByDefault := false;

   oxFeatures.Add('renderer.vulkan', 'Vulkan renderer', 'OX_RENDERER_VULKAN')^.IncludeByDefault := false;

   oxFeatures.Add('controllers', 'Controller support', 'OX_FEATURE_CONTROLLERS');

   oxFeatures.Add('html_log', 'html log support', 'OX_FEATURE_HTML_LOG')^.
      SetDisabledPlatforms(['android']);

   oxFeatures.Add('audio', 'Audio support', 'OX_FEATURE_AUDIO');

   oxFeatures.Add('audio.al', 'OpenAL audio support', 'OX_FEATURE_AL_AUDIO')^.
      SetExcludedPlatforms(['android']);

   oxFeatures.Add('ui', 'UI support', 'OX_FEATURE_UI');

   oxFeatures.Add('freetype', 'Freetype font loading support', 'OX_FEATURE_FREETYPE')^.
      SetExcludedPlatforms(['android']);

   oxFeatures.Add('console', 'in-engine console', 'OX_FEATURE_CONSOLE')^.
      SetDisabledPlatforms(['android']);

   oxFeatures.Add('wnd.about', 'About window', 'OX_FEATURE_WND_ABOUT')^.
      SetDisabledPlatforms(['library', 'android']);

   oxFeatures.Add('wnd.settings', 'Settings window', 'OX_FEATURE_WND_SETTINGS')^.
      SetDisabledPlatforms(['library', 'android']);

   oxFeatures.Add('scene', 'Scene support', 'OX_FEATURE_SCENE');

   oxFeatures.Add('models', 'Model support', 'OX_FEATURE_MODELS');

END.
