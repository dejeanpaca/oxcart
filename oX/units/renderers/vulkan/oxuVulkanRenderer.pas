{
   oxuVulkanRenderer, oX Vulkan renderer base
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxdefines.inc}

{$IFNDEF OX_RENDERER_VULKAN}
   {$FATAL Included vulkan renderer, with no OX_RENDERER_VULKAN defined}
{$ENDIF}

UNIT oxuVulkanRenderer;

INTERFACE

   USES
      uStd, uImage,
      Vulkan,
      {ox}
      uOX, oxuRenderer, oxuRenderers, oxuWindowTypes,
      {platform specific}
      {$IFDEF WINDOWS}windows, oxuWindowsPlatform{$ENDIF}
      {$IFDEF X11}oxuX11Platform{$ENDIF};

TYPE
   oxTVulkanWindow = class(oxTWindow)
   end;

   { oxTVulkanRenderer }

   oxTVulkanRenderer = class (oxTRenderer)
      constructor Create; override;

      procedure OnInitialize(); override;
  end;

VAR
   oxVulkanRenderer: oxTVulkanRenderer;

IMPLEMENTATION

{ oxTVulkanRenderer }

constructor oxTVulkanRenderer.Create;
begin
   inherited;

   Id := 'vulkan';
   Name := 'Vulkan';
   WindowInstance := oxTVulkanWindow;

   {$INCLUDE ../../ox_default_platform_instance.inc}
end;

procedure oxTVulkanRenderer.OnInitialize();
begin
end;

procedure init();
begin
   oxVulkanRenderer := oxTVulkanRenderer.Create();

   oxRenderers.Register(oxVulkanRenderer);
end;

procedure deinit();
begin
   FreeObject(oxVulkanRenderer);
end;

INITIALIZATION
   ox.PreInit.Add('renderer.vulkan', @init, @deinit);

END.
