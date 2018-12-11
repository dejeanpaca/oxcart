{
   wdguProgressBar, progress bar widget for the UI
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT wdguProgressBar;

INTERFACE

   USES
      uStd, uColors, uTiming,
      {oX}
      oxuTypes, oxuFont,
      {ui}
      uiuTypes, uiuWindowTypes, uiuWidget, uiWidgets, uiuDraw, uiuWidgetRender;

CONST
   wdgscPROGRESS_BAR_SURFACE = 0;
   wdgscPROGRESS_BAR = 1;

   wdgProgressBarSkinColorDescriptor: array[0..1] of uiTWidgetSkinColorDescriptor = (
      (
         Name: 'surface';
         Color: (255, 255, 255, 255)
      ),
      (
         Name: 'bar';
         Color: (0, 153, 255, 204)
      )
   );

   wdgProgressBarSkinDescriptor: uiTWidgetSkinDescriptor = (
      Name: 'progressbar';

      nColors: Length(wdgProgressBarSkinColorDescriptor);
      nImages: 0;
      nBools: 0;
      nStrings: 0;

      Colors: @wdgProgressBarSkinColorDescriptor;
      Images: nil;
      Bools: nil;
      Strings: nil;
      Setup: nil
   );

TYPE

   { wdgTProgressBar }

   wdgTProgressBar = class(uiTWidget)
      Speed: longword;
      Progress: oxTProgressIndicatorData;

      constructor Create; override;

      procedure Render(); override;

      {Sets maximum value for a progress bar.
       -1 is a special value and denotes progress with undefined duration (continuous animation).}
      function SetMaximum(max: longint): wdgTProgressBar;
      function SetCurrent(curr: longint): wdgTProgressBar;
      {set the progress as a ratio (0 .. 1)}
      function SetRatio(ratio: single): wdgTProgressBar;
      {set the progress as a ratio (0 .. 1)}
      function SetPercentage(p: single): wdgTProgressBar;
      {set the progress bar as undefined}
      function Undefined(): wdgTProgressBar;
   end;

   wdgTProgressBarGlobal = record
      {adds a ProgressBar to a window}
      function Add(const Pos: oxTPoint; const Dim: oxTDimensions;
                  max: longint = 100): wdgTProgressBar;
   end;

VAR
   wdgProgressBar: wdgTProgressBarGlobal;

IMPLEMENTATION

VAR
   internal: uiTWidgetClass;

constructor wdgTProgressBar.Create;
begin
   inherited;

   Speed := 2500;
   oxTProgressIndicatorData.Init(Progress);
end;

procedure wdgTProgressBar.Render();
var
   r: oxTRect;
   cur,
   undefinedPos, {at what position the undefined bar is at}
   leftover, {how much of undefined bar is left over not visible (rendered again from the beginning to make it seem seamless)}
   maxw: loopint; {maximum width, not including borders}
   p: single;
   s: String;
   f: oxTFont;

begin
   if(Dimensions.w = 0) or (Dimensions.h = 0) then
      exit;

   uiRenderWidget.Box(uiTWidget(self), GetColor(wdgscPROGRESS_BAR_SURFACE), uiTWindow(wnd).Skin.Colors.Border,
      wdgRENDER_BLOCK_ALL or wdgRENDER_BLOCK_SIMPLE);

   maxw := Dimensions.w - 2;

   r.x := RPosition.x + 1;
   r.y := RPosition.y - 1;
   r.h := Dimensions.h - 2;
   r.w := maxw;

   SetColor(wdgscPROGRESS_BAR);

   {undefined progress bar}
   if(Progress.ShowProgressWith = oxPROGRESS_INDICATOR_NONE) then begin
      if(Speed = 0) then
         exit;

      r.w := round((Dimensions.w - 2) / 3);
      cur := timer.Cur() mod Speed;

      p := 1 / Speed * cur;

      undefinedPos := round((maxw) * p);

      r.x := r.x + undefinedPos;

      if(undefinedPos + r.w > maxw) then begin
         leftover := undefinedPos + r.w - maxw;
         r.w := r.w - leftover;
      end else
         leftover := 0;

      uiDraw.Box(r);

      if(leftover > 0) then begin
         r.x := RPosition.x + 1;
         r.w := leftover;

         uiDraw.Box(r);
      end;
   end else begin
      p := 0;

      {get ratio progress from set source}

      if(Progress.ShowProgressWith = oxPROGRESS_INDICATOR_ITEMS) then begin
         if(Progress.ItemsDone > 0) then begin
            p := (1 / Progress.ItemsTotal) * Progress.ItemsDone;
         end;
      end else if (Progress.ShowProgressWith = oxPROGRESS_INDICATOR_PERCENTAGE) then
         p := Progress.Percentage / 100
      else if (Progress.ShowProgressWith = oxPROGRESS_INDICATOR_RATIO) then
         p := Progress.Ratio;

      {correct ratio to not go out of bounds}
      if(p < 0) then
         p := 0
      else if(p > 1) then
         p := 1;

      {render progress bar if any progress made}
      r.w := round(p * maxw);

      if(r.w > 0) then
         uiDraw.Box(r);
   end;

   s := Progress.ToString();

   if(s <> '') then begin
      f := CachedFont;
      r.Assign(RPosition, Dimensions);

      f.Start();
      SetColorBlendedEnabled(uiTWindow(wnd).Skin.Colors.InputText, uiTWindow(wnd).Skin.DisabledColors.InputText);
      f.WriteCentered(s, r);
      oxf.Stop();
   end;
end;

procedure InitWidget();
begin
   internal.Instance := wdgTProgressBar;
   internal.SkinDescriptor := @wdgProgressBarSkinDescriptor;
   {class}
   internal.Done();
end;

function wdgTProgressBarGlobal.Add(const Pos: oxTPoint; const Dim: oxTDimensions;
            max: longint = 100): wdgTProgressBar;

begin
   Result := wdgTProgressBar(uiWidget.Add(internal, Pos, Dim));

   if(Result <> nil) then
      Result.SetMaximum(max);
end;

function wdgTProgressBar.SetMaximum(max: longint): wdgTProgressBar;
begin
   Progress.ItemsDone := 0;
   Progress.ItemsTotal := max;
   Progress.ShowProgressWith := oxPROGRESS_INDICATOR_ITEMS;

   Result := self;
end;

function wdgTProgressBar.SetCurrent(curr: longint): wdgTProgressBar;
begin
   Progress.ItemsDone := curr;
   Progress.ShowProgressWith := oxPROGRESS_INDICATOR_ITEMS;

   Result := self;
end;

function wdgTProgressBar.SetRatio(ratio: single): wdgTProgressBar;
begin
   Progress.SetRatio(ratio);
   Progress.ShowProgressWith := oxPROGRESS_INDICATOR_RATIO;

   Result := Self;
end;

function wdgTProgressBar.SetPercentage(p: single): wdgTProgressBar;
begin
   Progress.SetPercentage(p);
   Progress.ShowProgressWith := oxPROGRESS_INDICATOR_PERCENTAGE;

   Result := Self;
end;

function wdgTProgressBar.Undefined(): wdgTProgressBar;
begin
   Progress.ItemsTotal := 0;
   Progress.ItemsDone := 0;
   Progress.ShowProgressWith := oxPROGRESS_INDICATOR_NONE;
   Result := Self;
end;


INITIALIZATION
   internal.Register('widget.progressbar', @InitWidget);

END.
