{
   oxuglRendererInfo, gl rendere information
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuglRendererInfo;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      oxuOGL, oxuWindow;

TYPE
   oxglPRendererInfo = ^oxglTRendererInfo;

   { oxglTRendererInfo }

   oxglTRendererInfo = object
      Properties: record
         Warned32NotSupported: boolean;
      end;

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

     function GetRequiredSettings(): oglTSettings;
     function GetExpectedSettings(): oglTSettings;
   end;

VAR
   oxglRendererInfo: oxglTRendererInfo;

IMPLEMENTATION

{ oxglTRendererInfo }

function oxglTRendererInfo.GetRequiredSettings(): oglTSettings;
begin
   if(not oxWindow.Current.oxProperties.Context) then
      Result := oglRequiredSettings
   else
      Result := oglContextSettings;
end;

function oxglTRendererInfo.GetExpectedSettings(): oglTSettings;
begin
   if(not oxWindow.Current.oxProperties.Context) then
      Result := oglDefaultSettings
   else
      Result := oglContextSettings;
end;

END.
