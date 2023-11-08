{$INCLUDE oxheader.inc}
UNIT frmuMain;

INTERFACE

USES
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Buttons, StdCtrls, BGRABitmap, BGRABitmapTypes,
  { units }
  oxuTFD, uFontEd, frmuFontDetails, ufhStandard;

TYPE

   { TfrmMain }

   TfrmMain = class(TForm)
     btnFontDetails: TBitBtn;
     btnFont: TBitBtn;
     btnSave: TBitBtn;
     btnUpdateChars: TButton;
     cbAutoupdate: TCheckBox;
     cbDrawGrid: TCheckBox;
     cbVerticalCorrection: TCheckBox;
     cbHorizontalCentering: TCheckBox;
     dlgFont: TFontDialog;
     edOfsH: TEdit;
     edCharCount: TEdit;
     edCharBase: TEdit;
     edSpcH: TEdit;
     edOfsV: TEdit;
     edHeight: TEdit;
     edSpcV: TEdit;
     edPerRow: TEdit;
     edCharWidth: TEdit;
     edRows: TEdit;
     edCharHeight: TEdit;
     edWidth: TEdit;
     gbTextureSize: TGroupBox;
     gbOrder: TGroupBox;
     lblOffset: TLabel;
     lblCharCount: TLabel;
     lblCharBase: TLabel;
     lblOffset1: TLabel;
     lblRows: TLabel;
     lblCharWidth: TLabel;
     lblTexHeight: TLabel;
     lblTexWidth: TLabel;
     shpTex: TShape;
     procedure btnFontClick({%H-}Sender: TObject);
     procedure btnFontDetailsClick({%H-}Sender: TObject);
     procedure btnSaveClick({%H-}Sender: TObject);
     procedure btnUpdateClick({%H-}Sender: TObject);
     procedure cbAutoupdateChange({%H-}Sender: TObject);
     procedure cbDrawGridChange({%H-}Sender: TObject);
     procedure cbHorizontalCenteringChange({%H-}Sender: TObject);
     procedure cbVerticalCorrectionChange({%H-}Sender: TObject);
     procedure edCharBaseChange({%H-}Sender: TObject);
     procedure edCharCountChange({%H-}Sender: TObject);
     procedure edCharHeightChange({%H-}Sender: TObject);
     procedure edCharWidthChange({%H-}Sender: TObject);
     procedure edHeightChange({%H-}Sender: TObject);
     procedure edOfsHChange({%H-}Sender: TObject);
     procedure edOfsVChange({%H-}Sender: TObject);
     procedure edPerRowChange({%H-}Sender: TObject);
     procedure edRowsChange({%H-}Sender: TObject);
     procedure edWidthChange({%H-}Sender: TObject);
     procedure shpTexPaint({%H-}Sender: TObject);
   private
      { private declarations }
   public
      { public declarations }
   end;

VAR
   frmMain: TfrmMain;

   ofsH, ofsV{, PerRow, CharWidth, CharHeight, CharBase, CharCount, spacingH, spacingV}: longint;
   Autoupdate, DrawGrid, VerticalCorrection, HorizontalCentering: boolean;
   texW, texH: longint;

IMPLEMENTATION

{$R *.lfm}

{ TfrmMain }

procedure SetTextureSize(w, h: longint);
begin
   if(w = 0) then
      w := texW;
   if(h = 0) then 
      h := texH;

   if(w <> texW) or (h <>texH) then begin
      if(tex <> nil) then 
         tex.Free();
      texW := w; 
      texH := h;
      tex := TBGRABitmap.Create(w, h);
   end;
end;

procedure UpdateTex();
begin
   frmMain.shpTex.Invalidate();
end;

procedure CreateTex();
var
   i, j, c, px, py, mx, my, cw, ch: longint;
   chr: char;

begin
   tex.FontName := frmMain.dlgFont.Font.Name;
   if(tex.FontName = '') then 
      exit;

   tex.Canvas.Font := frmMain.dlgFont.Font;

   tex.Canvas.Brush.Color  := clWhite;
   tex.Canvas.Pen.Color    := clWhite;
   tex.Canvas.Rectangle(0, 0, tex.Width, tex.Height);
   tex.AlphaFillRect(0, 0, tex.Width, tex.Height, 0);

   tex.FontAntialias := true;
   tex.FontHeight    := frmMain.dlgFont.Font.Height;

   for j := 0 to (tfd.lines-1) do
      for i := 0 to (tfd.cpline-1) do begin
         c := (j*tfd.cpline) + i + tfd.base;
         if(c > tfd.base+tfd.chars) then 
            break;

         chr := char(c);

         cw := tex.Canvas.Font.GetTextWidth(chr);
         ch := tex.Canvas.Font.GetTextHeight(chr);

         mx := 0;
         if(HorizontalCentering) then begin
            if(cw < tfd.width) then begin
               mx := (tfd.width - cw - 1) div 2;
            end;
         end;

         my := 0;
         if(VerticalCorrection) then begin
            if(ch < tfd.height) then begin
               my := tfd.height - ch;
            end;
         end;

         px := i * tfd.width + ofsH + mx;
         py := j * tfd.height + ofsV + my;

         tex.TextOut(px, py, chr,  ColorToBGRA(ColorToRGB(clWhite)), taLeftJustify);
      end;

   if(DrawGrid) then begin
      for i := 0 to (tfd.lines-1) do begin
         tex.DrawLine(i * tfd.width, 0, i * tfd.width, tex.height, ColorToBGRA(ColorToRGB(clWhite)), true);
      end;

      for i := 0 to (tfd.cpline-1) do begin
         tex.DrawLine(0, i * tfd.height, tex.width, i * tfd.height, ColorToBGRA(ColorToRGB(clWhite)), true);
      end;
   end;

   UpdateTex();
end;

procedure TfrmMain.btnFontClick(Sender: TObject);
begin
   if(dlgFont.Execute()) then begin
      CreateTex();
      UpdateTex();
   end;
end;

procedure TfrmMain.btnFontDetailsClick(Sender: TObject);
begin
   frmFontDetails.ShowModal();
end;

procedure TfrmMain.btnSaveClick(Sender: TObject);
begin
   tex.SaveToFile('font.png');
   oxTFD.Save(tfd, 'font.tfd');
end;

procedure TfrmMain.btnUpdateClick(Sender: TObject);
var
   i, w, h, code: longint;

begin
   {texture width}
   w := 0;
   val(edWidth.Text, i, code);
   if(code = 0) then 
      w := i;

   {texture height}
   h := 0;
   val(edHeight.Text, i, code);
   if(code = 0) then 
      h := i;

   SetTextureSize(w, h);

   {character width}
   val(edCharWidth.Text, i, code);
   if(code = 0) then 
      tfd.width := i;
   if(tfd.width < 2) then 
      tfd.width := 2;

   {character height}
   val(edCharHeight.Text, i, code);
   if(code = 0) then 
      tfd.height := i;
   if(tfd.height < 2) then 
      tfd.height := 2;

   {character per row}
   val(edPerRow.Text, i, code);
   if(code = 0) then 
      tfd.cpline := i;
   if(tfd.cpline < 1) then 
      tfd.cpline := 1;

   {character rows}
   val(edRows.Text, i, code);
   if(code = 0) then 
      tfd.lines := i;
   if(tfd.lines < 1) then 
      tfd.lines := 1;

   {character base}
   val(edCharBase.Text, i, code);
   if(code = 0) then 
      tfd.base := i;
   if(tfd.base < 0) then 
      tfd.base := 0;

   {character count}
   val(edCharCount.Text, i, code);
   if(code = 0) then 
      tfd.chars := i;
   if(tfd.chars < 1) then 
      tfd.chars := 1;

   {horizontal offset}
   val(edOfsH.Text, i, code);
   if(code = 0) then 
      ofsH := i;

   {vertical offset}
   val(edOfsV.Text, i, code);
   if(code = 0) then 
      ofsV := i;

   {horizontal spacing}
   val(edSpcH.Text, i, code);
   if(code = 0) then 
      tfd.spacex := i;
   if(tfd.spacex < 0) then 
      tfd.spacex := 0;

   {vertical spacing}
   val(edSpcV.Text, i, code);
   if(code = 0) then 
      tfd.spacey := i;
   if(tfd.spacey < 0) then 
      tfd.spacey := 0;

   CreateTex();
end;

procedure TfrmMain.cbAutoupdateChange(Sender: TObject);
begin
   Autoupdate := cbAutoupdate.Checked;
end;

procedure TfrmMain.cbDrawGridChange(Sender: TObject);
begin
   DrawGrid := cbDrawGrid.Checked;
   CreateTex();
end;

procedure TfrmMain.cbHorizontalCenteringChange(Sender: TObject);
begin
   HorizontalCentering := cbHorizontalCentering.Checked;
   CreateTex();
end;

procedure TfrmMain.cbVerticalCorrectionChange(Sender: TObject);
begin
   VerticalCorrection := cbVerticalCorrection.Checked;
   CreateTex();
end;

procedure PaintTex();
var
   shp: TShape;
   rect: TRect;

begin
   shp := frmMain.shpTex;

   rect.Top    := 0;
   rect.Left   := 0;
   rect.Bottom := tex.Height;
   rect.Right  := tex.Width;

   tex.Draw(shp.Canvas, rect);
end;

procedure TfrmMain.shpTexPaint(Sender: TObject);
begin
   PaintTex();
end;

{ ON CHANGE CALLBACKS }
procedure perfromAutoupdate();
begin
   if(Autoupdate) then begin
      CreateTex();
      PaintTex();
   end;
end;

procedure TfrmMain.edWidthChange(Sender: TObject);
begin
   perfromAutoupdate();
end;

procedure TfrmMain.edCharBaseChange(Sender: TObject);
begin
   perfromAutoupdate();
end;

procedure TfrmMain.edCharCountChange(Sender: TObject);
begin
   perfromAutoupdate();
end;

procedure TfrmMain.edCharHeightChange(Sender: TObject);
begin
   perfromAutoupdate();
end;

procedure TfrmMain.edCharWidthChange(Sender: TObject);
begin
   perfromAutoupdate();
end;

procedure TfrmMain.edHeightChange(Sender: TObject);
begin
   perfromAutoupdate();
end;

procedure TfrmMain.edOfsHChange(Sender: TObject);
begin
   perfromAutoupdate();
end;

procedure TfrmMain.edOfsVChange(Sender: TObject);
begin
   perfromAutoupdate();
end;

procedure TfrmMain.edPerRowChange(Sender: TObject);
begin
   perfromAutoupdate();
end;

procedure TfrmMain.edRowsChange(Sender: TObject);
begin
   perfromAutoupdate();
end;


INITIALIZATION
   SetTextureSize(512, 512);
   tfd.cpline  := 16;
   tfd.lines   := 16;
   tfd.width   := 8;
   tfd.height  := 8;
   tfd.base    := 0;
   tfd.chars   := 256;
   ofsH        := 0;
   ofsV        := 0;

   tfd.TextureName := 'font.png';
END.
