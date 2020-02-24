{
   oxuWindowsPlatformBase, base Windows OS specific functionality
   Copyright (c) 2018. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuWindowsPlatformBase;

INTERFACE

   USES
      uStd,
      {oX}
      {%H-}oxuPlatform,
      oxuWindowsOS,
      {ui}
      uiuTypes, uiuWindowTypes,
      {windows}
      Windows;

TYPE
   { oxTWindowsPlatformBase }

   oxTWindowsPlatformBase = class(oxTPlatform)
      Cursors: record
         Normal,
         Input,
         Busy,
         Denied,
         Hand,
         ResizeTB,
         ResizeLR,
         ResizeTRBL,
         ResizeTLBR: HCURSOR;
      end;

      function MessageBox(wParent: uiTWindow;
         const Title, Say: StdString; Style: uiTMessageBoxStyle; Buttons: longword): longword; override;

      procedure LoadCursor(var c: HCURSOR; cursorName: {$IFDEF UNICODE}PWideChar{$ELSE}PAnsiChar{$ENDIF});
      procedure LoadCursor(cursorType: uiTCursorType); override;
      procedure SetCursor(cursorType: uiTCursorType); override;
   end;

IMPLEMENTATION

function oxTWindowsPlatformBase.MessageBox(wParent: uiTWindow; const Title, Say: StdString;
   Style: uiTMessageBoxStyle; Buttons: longword): longword;
begin
   result := winos.MessageBox(wParent, Title, Say, Style, Buttons);
end;

procedure oxTWindowsPlatformBase.LoadCursor(var c: HCURSOR; cursorName: {$IFDEF UNICODE}PWideChar{$ELSE}PAnsiChar{$ENDIF});
begin
   if(c = 0) then
      c := Windows.LoadCursor(0, cursorName);
end;

procedure oxTWindowsPlatformBase.LoadCursor(cursorType: uiTCursorType);
begin
   if(cursorType = uiCURSOR_TYPE_NORMAL) or (cursorType = uiCURSOR_TYPE_DEFAULT) then
      LoadCursor(Cursors.Normal, windows.IDC_ARROW)
   else if(cursorType = uiCURSOR_TYPE_INPUT) then
      LoadCursor(Cursors.Input, windows.IDC_IBEAM)
   else if(cursorType = uiCURSOR_TYPE_BUSY) then
      LoadCursor(Cursors.Busy, windows.IDC_WAIT)
   else if(cursorType = uiCURSOR_TYPE_DENIED) then
      LoadCursor(Cursors.Denied, windows.IDC_NO)
   else if(cursorType = uiCURSOR_TYPE_HAND) then
      LoadCursor(Cursors.Hand, windows.IDC_HAND)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TB) then
      LoadCursor(Cursors.ResizeTB, windows.IDC_SIZENS)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_LR) then
      LoadCursor(Cursors.ResizeLR, windows.IDC_SIZEWE)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TLBR) then
      LoadCursor(Cursors.ResizeTLBR, windows.IDC_SIZENWSE)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TRBL) then
      LoadCursor(Cursors.ResizeTRBL, windows.IDC_SIZENESW)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TL) then begin
      if(Cursors.ResizeTLBR = 0) then
         LoadCursor(Cursors.ResizeTLBR, windows.IDC_SIZENWSE);
   end else if(cursorType = uiCURSOR_TYPE_RESIZE_TR) then begin
      if(Cursors.ResizeTRBL = 0) then
         LoadCursor(Cursors.ResizeTRBL, windows.IDC_SIZENESW);
   end else if(cursorType = uiCURSOR_TYPE_RESIZE_BL) then begin
      if(Cursors.ResizeTRBL = 0) then
         LoadCursor(Cursors.ResizeTRBL, windows.IDC_SIZENESW);
   end else if(cursorType = uiCURSOR_TYPE_RESIZE_BR) then begin
      if(Cursors.ResizeTLBR = 0) then
         LoadCursor(Cursors.ResizeTLBR, windows.IDC_SIZENWSE);
   end;
end;

procedure oxTWindowsPlatformBase.SetCursor(cursorType: uiTCursorType);
begin
   if(cursorType = uiCURSOR_TYPE_DEFAULT) or (cursorType = uiCURSOR_TYPE_NORMAL) then
      Windows.SetCursor(Cursors.Normal)
   else if(cursorType = uiCURSOR_TYPE_INPUT) then
      Windows.SetCursor(Cursors.Input)
   else if(cursorType = uiCURSOR_TYPE_BUSY) then
      Windows.SetCursor(Cursors.Busy)
   else if(cursorType = uiCURSOR_TYPE_DENIED) then
      Windows.SetCursor(Cursors.Denied)
   else if(cursorType = uiCURSOR_TYPE_HAND) then
      Windows.SetCursor(Cursors.Busy)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TB) then
      Windows.SetCursor(Cursors.ResizeTB)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_LR) then
      Windows.SetCursor(Cursors.ResizeLR)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TLBR) then
      Windows.SetCursor(Cursors.ResizeTLBR)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TRBL) then
      Windows.SetCursor(Cursors.ResizeTRBL)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TL) then
      Windows.SetCursor(Cursors.ResizeTLBR)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_BR) then
      Windows.SetCursor(Cursors.ResizeTLBR)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TR) then
      Windows.SetCursor(Cursors.ResizeTRBL)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_BL) then
      Windows.SetCursor(Cursors.ResizeTRBL)
   else
      Windows.SetCursor(Cursors.Normal);
end;

END.
