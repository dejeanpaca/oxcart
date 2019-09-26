{
   oxuVulkanRenderer, oX Vulkan renderer base
   Copyright (C) 2016. Dejan Boras

   Started On:    28.11.2016.
}

{$INCLUDE oxdefines.inc}
{$INCLUDE oxfeaturedefines.inc}

{$IFNDEF OX_RENDERER_VULKAN}
   {$FATAL Included vulkan renderer, with no OX_RENDERER_VULKAN defined}
{$ENDIF}

UNIT oxuVulkanRenderer;

INTERFACE

   USES
      uStd, uImage,
      Vulkan,
      {ox}
      uOX, oxuRenderer, oxuRenderers, oxuWindowTypes;

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

   Id := 'renderer.vulkan';
   Name := 'Vulkan';
   WindowInstance := oxTVulkanWindow;

   Init.Init(Id);
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
   ox.PreInit.Add('ox.vulkan.renderer', @init, @deinit);

END.
