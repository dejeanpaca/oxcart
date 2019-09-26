{
   oxuRendererVulkan, Vulkan Renderer
   Copyright (C) 2016. Dejan Boras

   Started On:    28.11.2016.
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
