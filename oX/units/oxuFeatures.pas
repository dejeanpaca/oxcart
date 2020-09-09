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

   { oxTFeaturePlatforms }

   oxTFeaturePlatforms = record
      {platforms on which this feature is always excluded}
      Excluded: TStringArray;
      {platforms on which this feature is only included}
      Included: TStringArray;
      {platforms on which this feature is disabled by default (but can be enabled)}
      Disabled: TStringArray;

      procedure SetExcluded(const newExcluded: array of StdString);
      procedure SetIncluded(const newIncluded: array of StdString);
      {sets platforms for which this feature is disabled by default (but can be enabled)}
      procedure SetDisabled(const newDisabled: array of StdString);
      function IsExcluded(const platform: StdString): boolean;
      function IsIncluded(const platform: StdString): boolean;
      function IsEnabled(const platform: StdString): boolean;

      function IsSupported(const platform: StdString; isLibrary: boolean = false): boolean;
   end;

   { oxTFeatureDescriptor }

   oxTFeatureDescriptor = record
      Name,
      Description,
      Symbol: string;

      IncludeByDefault: boolean;

      Platforms: oxTFeaturePlatforms;

      class procedure Initialize(out f: oxTFeatureDescriptor); static;

      function SetExcluded(const newExcluded: array of StdString): oxPFeatureDescriptor;
      function SetIncluded(const newIncluded: array of StdString): oxPFeatureDescriptor;
      {sets platforms for which this feature is disabled by default (but can be enabled)}
      function SetDisabled(const newDisabled: array of StdString): oxPFeatureDescriptor;
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

      function Add(const name, description, symbol: StdString): oxPFeatureDescriptor;
      function BuildFeatureSymbols(const platform: StdString; isLibrary: boolean = false): TStringArray;
      function GetSupported(const platform: StdString; isLibrary: boolean = false): oxTFeaturePDescriptorList;
      function IsSupported(const feature: oxTFeatureDescriptor;
         const platform: StdString; isLibrary: boolean = false): boolean;

      {find a feature by its name}
      function FindByName(const name: StdString): oxPFeatureDescriptor;
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


{ oxTFeaturePlatforms }

procedure  oxTFeaturePlatforms.SetExcluded(const newExcluded: array of StdString);
var
   i: loopint;

begin
   SetLength(Excluded, Length(newExcluded));

   for i := 0 to High(excluded) do begin
      Excluded[i] := newExcluded[i];
   end;
end;

procedure  oxTFeaturePlatforms.SetIncluded(const newIncluded: array of StdString);
var
   i: loopint;

begin
   SetLength(Included, Length(newIncluded));

   for i := 0 to High(included) do begin
      Included[i] := newIncluded[i];
   end;
end;

procedure oxTFeaturePlatforms.SetDisabled(const newDisabled: array of StdString);
var
   i: loopint;

begin
   SetLength(Disabled, Length(newDisabled));

   for i := 0 to High(disabled) do begin
      Disabled[i] := newDisabled[i];
   end;
end;

function oxTFeaturePlatforms.IsExcluded(const platform: StdString): boolean;
var
   i: loopint;

begin
   for i := 0 to High(Excluded) do begin
      if(Excluded[i] = platform) then
         exit(true);
   end;

   Result := false;
end;

function oxTFeaturePlatforms.IsIncluded(const platform: StdString): boolean;
var
   i: loopint;

begin
   if(Length(Included) > 0) then begin
      for i := 0 to High(Included) do begin
         if(Included[i] = platform) then
            exit(true);
      end;

      exit(false);
   end;

   for i := 0 to High(Excluded) do begin
      if(Excluded[i] = platform) then
         exit(false);
   end;

   Result := true;
end;

function oxTFeaturePlatforms.IsEnabled(const platform: StdString): boolean;
var
   i: loopint;

begin
   if(Length(Disabled) > 0) then begin
      for i := 0 to High(Disabled) do begin
         if(Disabled[i] = platform) then
            exit(false);
      end;
   end;

   Result := true;
end;

function oxTFeaturePlatforms.IsSupported(const platform: StdString; isLibrary: boolean): boolean;
var
   p: StdString;

begin
   p := platform;

   if(p = 'win32') or (p = 'win64') then
      p := 'windows';

   if(IsIncluded(p)) then begin
      if(isLibrary and IsExcluded('library')) then
         Result := false
      else
         Result := true;
   end else
      Result := false;
end;

class procedure oxTFeatureDescriptor.Initialize(out f: oxTFeatureDescriptor);
begin
   ZeroOut(f, SizeOf(f));
   f.IncludeByDefault := true;
end;

function oxTFeatureDescriptor.SetExcluded(const newExcluded: array of StdString): oxPFeatureDescriptor;
begin
   Platforms.SetExcluded(newExcluded);
   Result := @Self;
end;

function oxTFeatureDescriptor.SetIncluded(const newIncluded: array of StdString): oxPFeatureDescriptor;
begin
   Platforms.SetIncluded(newIncluded);
   Result := @Self;
end;

function oxTFeatureDescriptor.SetDisabled(const newDisabled: array of StdString): oxPFeatureDescriptor;
begin
   Platforms.SetDisabled(newDisabled);
   Result := @Self;
end;

{ oxTFeaturesGlobal }

function oxTFeaturesGlobal.Add(const name, description, symbol: StdString): oxPFeatureDescriptor;
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

function oxTFeaturesGlobal.BuildFeatureSymbols(const platform: StdString; isLibrary: boolean): TStringArray;
var
   i: loopint;
   plist: oxTFeaturePDescriptorList;

begin
   plist := GetSupported(platform, isLibrary);
   Result := nil;

   if(plist.n > 0) then begin
      SetLength(Result, plist.n);

      for i := 0 to plist.n - 1 do begin
         Result[i] := plist.List[i]^.Symbol;
      end;
   end;
end;

function oxTFeaturesGlobal.GetSupported(const platform: StdString; isLibrary: boolean): oxTFeaturePDescriptorList;
var
   i: loopint;

begin
   Result.Initialize(Result);

   for i := 0 to List.n - 1 do begin
      if(IsSupported(List.List[i], platform, isLibrary)) then
         Result.Add(@List.List[i]);
   end;
end;

function oxTFeaturesGlobal.IsSupported(const feature: oxTFeatureDescriptor;
   const platform: StdString; isLibrary: boolean): boolean;

begin
   Result := feature.Platforms.IsSupported(platform, isLibrary);
end;

function oxTFeaturesGlobal.FindByName(const name: StdString): oxPFeatureDescriptor;
begin
   Result := List.FindByName(name);
end;

INITIALIZATION
   oxFeatures.List.Initialize(oxFeatures.List);

   oxFeatures.Add('renderer.gl', 'OpenGL renderer', 'OX_RENDERER_GL');

   oxFeatures.Add('renderer.dx11', 'DirectX 11 renderer', 'OX_RENDERER_DX11')^.
      SetIncluded(['windows'])^.IncludeByDefault := false;

   oxFeatures.Add('renderer.console', 'Console renderer', 'OX_RENDERER_CONSOLE')^.
      SetExcluded(['android'])^.IncludeByDefault := false;

   oxFeatures.Add('renderer.vulkan', 'Vulkan renderer', 'OX_RENDERER_VULKAN')^.IncludeByDefault := false;

   oxFeatures.Add('controllers', 'Controller support', 'OX_FEATURE_CONTROLLERS');

   oxFeatures.Add('html_log', 'html log support', 'OX_FEATURE_HTML_LOG')^.
      Platforms.SetDisabled(['android']);

   oxFeatures.Add('audio', 'Audio support', 'OX_FEATURE_AUDIO');

   oxFeatures.Add('audio.al', 'OpenAL audio support', 'OX_FEATURE_AL_AUDIO')^.
      Platforms.SetExcluded(['android']);

   oxFeatures.Add('ui', 'UI support', 'OX_FEATURE_UI');

   oxFeatures.Add('freetype', 'Freetype font loading support', 'OX_FEATURE_FREETYPE')^.
      Platforms.SetExcluded(['android']);

   oxFeatures.Add('console', 'in-engine console', 'OX_FEATURE_CONSOLE')^.
      Platforms.SetDisabled(['android']);

   oxFeatures.Add('wnd.about', 'About window', 'OX_FEATURE_WND_ABOUT')^.
      Platforms.SetDisabled(['library', 'android']);

   oxFeatures.Add('wnd.settings', 'Settings window', 'OX_FEATURE_WND_SETTINGS')^.
      Platforms.SetDisabled(['library', 'android']);

   oxFeatures.Add('scene', 'Scene support', 'OX_FEATURE_SCENE');

   oxFeatures.Add('models', 'Model support', 'OX_FEATURE_MODELS');

END.
