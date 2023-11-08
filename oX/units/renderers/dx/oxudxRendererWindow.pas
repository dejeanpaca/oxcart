{
   oxudxRendererWindow, DirectX renderer window types
   Copyright (C) 2016. Dejan Boras

   Started On:    07.02.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxudxRendererWindow;

INTERFACE

   USES
     uColors,
     oxuWindowsOS,
     {dx}
     DX12.D3D11, DX12.DXGI, DX12.D3DCommon,
     DX12.D3DX10;

TYPE
   { oxglTRendererWindow }

   { dxTRendererWindow }

   dxTRendererWindow = class(winosTWindow)
      dx: record
         { device }
         Device: ID3D11Device;
         {device context}
         DC: ID3D11DeviceContext;
         CurrentFeatureLevel: TD3D_FEATURE_LEVEL;

         { Swapchain }
         Swapchain: IDXGISwapChain;
         RenderTargetView: ID3D11RenderTargetView;

         { Depth, stencil and raster states }
         DepthStencilBuffer: ID3D11Texture2D;
         DepthStencilState: ID3D11DepthStencilState;
         DepthStencilView: ID3D11DepthStencilView;
         RasterizerState: ID3D11RasterizerState;
         Viewport: TD3D11_VIEWPORT;

         { Matrices }
         ProjMatrix: TD3DMATRIX;

         { Flag which signalizes that renderer is initialized }
         EnableVSync: Boolean;
         ClearColor: TColor4f;
      end;

      constructor Create; override;
   end;

IMPLEMENTATION

{ dxTRendererWindow }

constructor dxTRendererWindow.Create;
begin
   inherited Create;

   wd.NoDC := true;
end;

END.

