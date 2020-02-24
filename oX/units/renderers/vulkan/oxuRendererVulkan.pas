{
   oxuRendererVulkan, Vulkan Renderer
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxdefines.inc}

{$IFNDEF OX_RENDERER_VULKAN}
   {$FATAL Included vulkan renderer, with no OX_RENDERER_VULKAN defined}
{$ENDIF}
UNIT oxuRendererVulkan;

INTERFACE

   USES
      uStd,
      oxuVulkanRenderer;

IMPLEMENTATION

INITIALIZATION
   Pass();

END.
