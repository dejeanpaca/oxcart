{
   oxuDefaultSplashScreen, default splash screen
   Copyright (C) 2019. Dejan Boras

   Started On:    29.04.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxuDefaultSplashScreen;

INTERFACE

   USES
      vmVector,
      {ox}
      oxuTransform, oxuRenderer, oxuRender, oxuRenderUtilities, oxuMaterial, oxuTypes,
      oxuSplashScreen;

TYPE
   { oxTDefaultSplashScreen }

   oxTDefaultSplashScreen = class(oxTBasicSplashScreen)
      Projection: TMatrix4f;
      Rotation: TVector3f;

      protected
         Initialized: boolean;
      public

      constructor Create(); override;

      procedure Load(); override;
      procedure Update(); override;
      procedure RenderContent(); override;
   end;

IMPLEMENTATION

{ oxTDefaultSplashScreen }

constructor oxTDefaultSplashScreen.Create();
begin
   inherited Create();

   ClearBits := oxrBUFFER_CLEAR_COLOR;
   {$IFDEF DEBUG}
   DisplayTime := 0;
   {$ENDIF}
end;

procedure oxTDefaultSplashScreen.Load();
begin
   inherited Load;

   if(AssociatedWindow = nil) then
      exit;

   Projection := oxTTransform.PerspectiveFrustum(60, AssociatedWindow.Dimensions.w / AssociatedWindow.Dimensions.h, 0.5, 100.0);

   Initialized := true;
end;

procedure oxTDefaultSplashScreen.Update();
begin
   Rotation[0] := Rotation[0] + 90  * TimeFlow;
   Rotation[1] := Rotation[1] + 45  * TimeFlow;
   Rotation[2] := Rotation[2] + 180 * TimeFlow;
end;

procedure oxTDefaultSplashScreen.RenderContent();
begin
   if(Initialized) then begin
      oxRenderer.SetProjectionMatrix(Projection);

      oxTransform.Identity();
      oxTransform.Translate(0, 0, -5.0);
      oxTransform.Rotate(Rotation);

      oxTransform.Apply();

      oxCurrentMaterial.ApplyColor('color', 1.0, 1.0, 1.0, 1.0);

      oxRenderingUtilities.Cube();
   end;

   inherited RenderContent;
end;

INITIALIZATION
   oxSplashScreen.StartupInstance := oxTDefaultSplashScreen;

END.
