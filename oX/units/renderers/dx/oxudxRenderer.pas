{
   oxudxRenderer, DirectX renderer base
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxdefines.inc}

{$IFNDEF OX_RENDERER_DX11}
   {$FATAL Included dx renderer, with no OX_RENDERER_DX11 defined}
{$ENDIF}

{$IFNDEF WINDOWS}
   {$FATAL dx renderer is only available on windows}
{$ENDIF}

UNIT oxudxRenderer;

INTERFACE

   USES
      windows, uStd, vmVector, uColors,
      oxuWindowTypes, oxuRenderer, oxuRenderers, oxudxRendererWindow, oxuWindowsOS, oxuWindow,
      {dx}
      DX12.D3D11, DX12.DXGI, DX12.D3DCommon,
      DX12.D3DX10;

TYPE
   { oxdxTRenderer }

   oxdxTRenderer = class (oxTRenderer)
      procedure OnInitialize(); override;

      {windows}
      procedure SetupData(wnd: oxTWindow); override;
      function SetupWindow(wnd: oxTWindow): boolean; override;
      function PreInitWIndow({%H-}wnd: oxTWindow): boolean; override;
      function InitWindow(window: oxTWindow): boolean; override;
      function DeInitWindow(wnd: oxTWindow): boolean; override;
      procedure LogWindow(wnd: oxTWindow); override;
      function ContextWindowRequired(): boolean; override;


      {rendering}
      procedure SwapBuffers({%H-}wnd: oxTWindow); override;
      procedure Viewport(x, y, w, h: longint); override;

      procedure Clear(clearBits: longword); override;
      procedure ClearColor(c: TColor4f); override;

      procedure SetProjectionMatrix(const m: TMatrix4f); override;

      constructor Create(); override;
  end;
   
VAR
   oxdxRenderer: oxdxTRenderer;

IMPLEMENTATION

{ oxdxTRenderer }

procedure oxdxTRenderer.OnInitialize();
begin
end;

function oxdxTRenderer.InitWindow(window: oxTWindow): boolean;
var
   featureLevel: array[0..0] of TD3D_FEATURE_LEVEL;
   pBackBuffer: ID3D11Texture2D;

   swapchainDescriptor: TDXGI_SWAP_CHAIN_DESC;
   depthDescriptor: TD3D11_TEXTURE2D_DESC;
   depthStateDescriptor: TD3D11_DEPTH_STENCIL_DESC;
   depthViewDescriptor: TD3D11_DEPTH_STENCIL_VIEW_DESC;
   rasterizerDescriptor: TD3D11_RASTERIZER_DESC;

   driverType: TD3D_DRIVER_TYPE;

   wnd: dxTRendererWindow;

function CheckFail(const message: string): boolean;
begin
   {$PUSH}{$R-}
   if(Failed(wnd.wd.LastError)) then begin
      wnd.CreateFail('dx > ' + message + ': ' + winos.FormatMessage(wnd.wd.LastError));
      exit(true);
   end;
   {$POP}

   result := false;
end;

begin
   result := false;
   wnd := dxTRendererWindow(window);

   { setup swapchain descriptor }

   ZeroOut(swapchainDescriptor, SizeOf(TDXGI_SWAP_CHAIN_DESC));

   swapchainDescriptor.BufferCount := 1;

   swapchainDescriptor.BufferDesc.Width := wnd.Dimensions.w;
   swapchainDescriptor.BufferDesc.Height := wnd.Dimensions.h;
   swapchainDescriptor.BufferDesc.Format := DXGI_FORMAT_R8G8B8A8_UNORM;

   swapchainDescriptor.BufferDesc.RefreshRate.Numerator := 0;
   swapchainDescriptor.BufferDesc.RefreshRate.Denominator := 1;

   swapchainDescriptor.BufferDesc.ScanlineOrdering := DXGI_MODE_SCANLINE_ORDER_UNSPECIFIED;
   swapchainDescriptor.BufferDesc.Scaling := DXGI_MODE_SCALING_UNSPECIFIED;

   swapchainDescriptor.BufferUsage := DXGI_USAGE_RENDER_TARGET_OUTPUT;

   swapchainDescriptor.OutputWindow := wnd.wd.h;

   swapchainDescriptor.SampleDesc.Count := 1;
   swapchainDescriptor.Windowed := true;
   swapchainDescriptor.SwapEffect := DXGI_SWAP_EFFECT_DISCARD;

   { set feature level }
   featureLevel[0] := D3D_FEATURE_LEVEL_11_0;

   driverType := D3D_DRIVER_TYPE_HARDWARE;
   if(wnd.gl.Software) then
      driverType := D3D_DRIVER_TYPE_SOFTWARE;

   { create device and swapchain}
   {$PUSH}
   wnd.wd.LastError := D3D11CreateDeviceAndSwapChain(
       nil,
       driverType,
       0,
       0,
       {$R-}@featureLevel,
       1,
       D3D11_SDK_VERSION,
       @swapchainDescriptor,
       wnd.dx.Swapchain,
       wnd.dx.Device,
       wnd.dx.CurrentFeatureLevel,
       wnd.dx.DC);
   {$POP}

   if(CheckFail('failed to create device and swapchain')) then
      exit(false);

   { get first backbuffer }
   wnd.wd.LastError :=  wnd.dx.Swapchain.GetBuffer(0, ID3D11Texture2D, pBackBuffer);
   if(CheckFail('failed to create first backbuffer')) then
      exit(false);

   { create render target view }
   wnd.wd.LastError := wnd.dx.Device.CreateRenderTargetView(pBackBuffer, nil, wnd.dx.RenderTargetView);
   if(CheckFail('failed to create render target view')) then
      exit(false);

   { setup depth buffer descriptor }
   ZeroOut(depthDescriptor, SizeOf(depthDescriptor));

   depthDescriptor.Width := wnd.Dimensions.w;
   depthDescriptor.Height := wnd.Dimensions.h;
   depthDescriptor.MipLevels := 1;
   depthDescriptor.ArraySize := 1;
   depthDescriptor.Format := DXGI_FORMAT_D24_UNORM_S8_UINT;
   depthDescriptor.SampleDesc.Count := 1;
   depthDescriptor.SampleDesc.Quality := 0;
   depthDescriptor.Usage := D3D11_USAGE_DEFAULT;
   depthDescriptor.BindFlags := ord(D3D11_BIND_DEPTH_STENCIL);
   depthDescriptor.CPUAccessFlags := 0;
   depthDescriptor.MiscFlags := 0;

   { create depth buffer }
   wnd.wd.LastError := wnd.dx.Device.CreateTexture2D(depthDescriptor, nil, wnd.dx.DepthStencilBuffer);
   if(CheckFail('failed to create depth buffer')) then
      exit(false);

   { setup depth stencil state descriptor }

   ZeroOut(depthStateDescriptor, SizeOf(depthStateDescriptor));

   depthStateDescriptor.DepthEnable := true;
   depthStateDescriptor.DepthWriteMask := D3D11_DEPTH_WRITE_MASK_ALL;
   depthStateDescriptor.DepthFunc := D3D11_COMPARISON_LESS;
   depthStateDescriptor.StencilEnable := true;
   depthStateDescriptor.StencilReadMask := $FF;
   depthStateDescriptor.StencilWriteMask := $FF;

   depthStateDescriptor.FrontFace.StencilFailOp := D3D11_STENCIL_OP_KEEP;
   depthStateDescriptor.FrontFace.StencilDepthFailOp := D3D11_STENCIL_OP_INCR;
   depthStateDescriptor.FrontFace.StencilPassOp := D3D11_STENCIL_OP_KEEP;
   depthStateDescriptor.FrontFace.StencilFunc := D3D11_COMPARISON_ALWAYS;

   depthStateDescriptor.BackFace.StencilFailOp := D3D11_STENCIL_OP_KEEP;
   depthStateDescriptor.BackFace.StencilDepthFailOp := D3D11_STENCIL_OP_DECR;
   depthStateDescriptor.BackFace.StencilPassOp := D3D11_STENCIL_OP_KEEP;
   depthStateDescriptor.BackFace.StencilFunc := D3D11_COMPARISON_ALWAYS;

   { create depth-stencil state object }
   wnd.wd.LastError := wnd.dx.Device.CreateDepthStencilState(depthStateDescriptor, wnd.dx.DepthStencilState);
   if(CheckFail('failed to create depth stencil state')) then
      exit(false);

   { set depth-stencil state }
   wnd.dx.DC.OMSetDepthStencilState(wnd.dx.DepthStencilState, 1);

   { setup depth-stencil view descriptor }
   ZeroOut(depthViewDescriptor, SizeOf(depthViewDescriptor));

   depthViewDescriptor.Format := DXGI_FORMAT_D24_UNORM_S8_UINT;
   depthViewDescriptor.ViewDimension := D3D11_DSV_DIMENSION_TEXTURE2D;
   depthViewDescriptor.Texture2D.MipSlice := 0;

   { create depth-stencil view }
   wnd.wd.LastError :=
      wnd.dx.Device.CreateDepthStencilView(wnd.dx.DepthStencilBuffer, @depthViewDescriptor, wnd.dx.DepthStencilView);
   if(CheckFail('failed to create depth-stencil view')) then
      exit(false);

   { bind render target view and depth-stencil view}
   wnd.dx.DC.OMSetRenderTargets(1, @wnd.dx.RenderTargetView, wnd.dx.DepthStencilView);

   { setup rasterizer state descriptor }
   ZeroOut(rasterizerDescriptor, SizeOf(rasterizerDescriptor));

   rasterizerDescriptor.AntialiasedLineEnable := true;
   rasterizerDescriptor.CullMode := D3D11_CULL_BACK;
   rasterizerDescriptor.DepthBias := 0;
   rasterizerDescriptor.DepthBiasClamp := 0;
   rasterizerDescriptor.DepthClipEnable := true;
   rasterizerDescriptor.FillMode := D3D11_FILL_SOLID;
   rasterizerDescriptor.FrontCounterClockwise := false;
   rasterizerDescriptor.MultisampleEnable := false;
   rasterizerDescriptor.ScissorEnable := false;
   rasterizerDescriptor.SlopeScaledDepthBias := 0;

   { create rasterizer state object }
   wnd.wd.LastError := wnd.dx.Device.CreateRasterizerState(rasterizerDescriptor, wnd.dx.RasterizerState);
   if(CheckFail('failed to create rasterizer state object')) then
      exit(false);

   { set rasterizer state }
   wnd.dx.DC.RSSetState(wnd.dx.RasterizerState);

   { setup viewport }
   ZeroOut(wnd.dx.Viewport, SizeOf(wnd.dx.Viewport));
   wnd.dx.Viewport.Width := wnd.Dimensions.w;
   wnd.dx.Viewport.Height := wnd.Dimensions.h;
   wnd.dx.Viewport.MinDepth := 0;
   wnd.dx.Viewport.MaxDepth := 1;
   wnd.dx.Viewport.TopLeftX := 0;
   wnd.dx.Viewport.TopLeftY := 0;

   { set viewport }
   wnd.dx.DC.RSSetViewports(1, @wnd.dx.Viewport);

   { create a projection matrix }
   D3DXMatrixPerspectiveFovLH(@wnd.dx.ProjMatrix, 2 * vmcPI / 4, wnd.Dimensions.w / wnd.Dimensions.h, 0.5, 1000);

   result := true;
end;

function oxdxTRenderer.DeInitWindow(wnd: oxTWindow): boolean;
begin
   result := true;
end;


procedure oxdxTRenderer.SetupData(wnd: oxTWindow);
begin
end;

function oxdxTRenderer.SetupWindow(wnd: oxTWindow): boolean;
begin
   result := true;
end;

function oxdxTRenderer.PreInitWIndow(wnd: oxTWindow): boolean;
begin
   result := true;
end;

procedure oxdxTRenderer.LogWindow(wnd: oxTWindow);
begin
end;

function oxdxTRenderer.ContextWindowRequired(): boolean;
begin
   result := false;
end;

procedure oxdxTRenderer.SwapBuffers(wnd: oxTWindow);
var
   dxwnd: dxTRendererWindow;

begin
   dxwnd := dxTRendererWindow(wnd);

   if(dxwnd.gl.VSync) then
      dxwnd.dx.Swapchain.Present(1, 0)
   else
      dxwnd.dx.Swapchain.Present(0, 0);
end;

procedure oxdxTRenderer.Viewport(x, y, w, h: longint);
begin
end;

procedure oxdxTRenderer.Clear(clearBits: longword);
var
   wnd: dxTRendererWindow;

begin
   wnd := dxTRendererWindow(oxWindow.Current);

   {clear color}
   wnd.dx.DC.ClearRenderTargetView(wnd.dx.RenderTargetView, wnd.dx.ClearColor);

   {clear depth buffer}
   wnd.dx.DC.ClearDepthStencilView(wnd.dx.DepthStencilView, Ord(D3D11_CLEAR_DEPTH), 1, 0);
end;

procedure oxdxTRenderer.ClearColor(c: TColor4f);
begin
   dxTRendererWindow(oxWindow.Current).dx.ClearColor := c;
end;

procedure oxdxTRenderer.SetProjectionMatrix(const m: TMatrix4f);
begin
   {TODO: Implement}
end;

constructor oxdxTRenderer.Create();
begin
   inherited;

   Id := 'renderer.dx';
   Name := 'DirectX';
   WindowInstance := dxTRendererWindow;

   Init.Init(Id);
end;

procedure DeInitialize();
begin
   FreeObject(oxdxRenderer);
end;

INITIALIZATION
   oxdxRenderer := oxdxTRenderer.Create();

   oxRenderers.Register(oxdxRenderer);
   oxRenderers.Init.dAdd('renderer.dx', @DeInitialize);

END.
