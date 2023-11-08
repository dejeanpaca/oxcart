{
   oxuglRendererInfo, gl rendere information
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuglRendererInfo;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      {ox}
      oxuOGL, oxuWindow
      {$IFDEF OX_LIBRARY_SUPPORT}
      , oxuGlobalInstances
      {$ENDIF};

TYPE
   oxglPRendererInfo = ^oxglTRendererInfo;

   { oxglTRendererInfo }

   oxglTRendererInfo = record
      Properties: record
         Warned32NotSupported: boolean;
      end;

      {is this a GLES renderer}
      GLES: boolean;

      Renderer,
      Vendor,
      sVersion: string;
      iVersion: longword;
      Version: oglTVersion;

      GLSL: record
         Version: string;
         Major,
         Minor,
         Compact: longword;
      end;

     Limits: record
         MaxTextureSize,
         MaxLights,
         MaxClipPlanes,
         MaxProjectionStackDepth,
         MaxModelViewStackDepth,
         MaxTextureStackDepth: GLuint;
      end;

     {get required version}
     function GetRequiredVersion(): oglTVersion;
     {get expected (default/target) version}
     function GetExpectedVersion(): oglTVersion;
   end;

VAR
   oxglRendererInfo: oxglTRendererInfo;

IMPLEMENTATION

{ oxglTRendererInfo }

function oxglTRendererInfo.GetRequiredVersion(): oglTVersion;
begin
   if(not oxWindow.Current.oxProperties.Context) then
      Result := oglRequiredVersion
   else
      Result := oglContextVersion;
end;

function oxglTRendererInfo.GetExpectedVersion(): oglTVersion;
begin
   if(not oxWindow.Current.oxProperties.Context) then
      Result := oglDefaultVersion
   else
      Result := oglContextVersion;
end;

INITIALIZATION
   {$IF NOT DEFINED(OX_LIBRARY) AND DEFINED(OX_LIBRARY_SUPPORT)}
   oxGlobalInstances.Add('oxglTRendererInfo', @oxglRendererInfo);
   {$ENDIF}

END.
