{
   wdguInputBox, input box widget
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT wdguInputBox;

INTERFACE

   USES
      sysutils, uStd, uTiming, uColors,
      {app}
      appuKeys, appuMouse, appuRegional,
      {oX}
      oxuTypes, oxuFont, oxuPlatform,
      {ui}
      uiuDraw, uiuWidget, uiuWindowTypes, uiuSkinTypes,
      uiWidgets, uiuWidgetRender, uiuTypes,
      wdguBase;

CONST
   {text should not be set as the Original text}
   wdgINPUT_BOX_NOT_ORIGINAL              = $0001;
   {assume text did not change (will not call text changed handler)}
   wdgINPUT_BOX_NO_TEXT_CHANGE            = $0002;

   wdghINPUTBOX_CONFIRM_PRESSED           = $0001;
   wdghINPUTBOX_CONFIRM                   = $0002;
   wdghINPUTBOX_ESCAPE_PRESSED            = $0001;
   wdghINPUTBOX_ESCAPE                    = $0002;
   wdghINPUTBOX_CHANGED                   = $0003;
   wdghINPUTBOX_DRAW_CONTAINER            = $0004;
   wdghINPUTBOX_DRAW_TEXT                 = $0005;
   wdghINPUTBOX_DRAW_CURSOR               = $0006;

CONST
   wdgscINPUT_SURFACE          = 0;
   wdgscINPUT_TEXT             = 1;
   wdgscINPUT_CURSOR           = 2;
   wdgscINPUT_PLACEHOLDER      = 3;
   wdgscINPUT_BORDER           = 4;
   wdgscINPUT_BORDER_SELECTED  = 5;

   wdgInputSkinColorDescriptor: array[0..5] of uiTWidgetSkinColorDescriptor = (
      (
         Name: 'surface';
         Color: (255, 255, 255, 255)
      ),
      (
         Name: 'text';
         Color: (0, 0, 0, 255)
      ),
      (
         Name: 'cursor';
         Color: (0, 0, 0, 255)
      ),
      (
         Name: 'placeholder';
         Color: (192, 192, 192, 255)
      ),
      (
         Name: 'border';
         Color: (0, 0, 0, 255)
      ),
      (
         Name: 'border_selected';
         Color: (0, 0, 255, 255)
      )
   );

   wdgInputSkinDescriptor: uiTWidgetSkinDescriptor = (
      Name: 'input';

      nColors: 6;
      nImages: 0;
      nBools: 0;
      nStrings: 0;

      Colors: @wdgInputSkinColorDescriptor;
      Images: nil;
      Bools: nil;
      Strings: nil;
      Setup: nil
   );

TYPE
   wdgTInputBoxType = (
      wdgINPUT_BOX_TYPE_NORMAL,
      wdgINPUT_BOX_TYPE_NUMERICAL,
      wdgINPUT_BOX_TYPE_FLOAT,
      {restrict to custom character set}
      wdgINPUT_BOX_TYPE_RESTRICTED
   );

   wdgTInputBoxCursorType = (
      wdgINPUT_BOX_CURSOR_NORMAL,
      wdgINPUT_BOX_CURSOR_BLOCK
   );

   { wdgTInputBox }

   wdgTInputBox = class(uiTWidget)
      public
         CustomDrawnContainer,
         CustomDrawnText,
         CustomDrawnCursor,
         {make the box read only}
         ReadOnly: boolean;

         {callback when text is changed}
         OnTextChanged: procedure(wdg: wdgTInputBox);

         {input box type}
         InputType: wdgTInputBoxType;
         {cursor type}
         InputCursorType: wdgTInputBoxCursorType;
         {restricted character set if input type is WDG_INPUT_BOX_TYPE_RESTRICTED}
         CharacterSet: array of char;
         {is the restricted character set case sensitive}
         CaseSensitiveCharacterSet: boolean;

      constructor Create(); override;
      destructor Destroy; override;

      procedure Render(); override;
      procedure Point(var e: appTMouseEvent; x, {%H-}y: longint); override;
      function Key(var keyEvent: appTKeyEvent): boolean; override;
      procedure Action(what: uiTWidgetEvents); override;

      {get computed dimensions}
      procedure GetComputedDimensions(out d: oxTDimensions); override;

      {sets the input-box text}
      procedure SetText(const txt: StdString; setProperties: longword = 0);
      procedure SetPlaceholder(const newPlaceholder: StdString);
      {get the input-box text}
      function GetText(): StdString;
      {clears a text box}
      procedure Clear();
      {sets input home position}
      procedure GoToHome();
      procedure GoToEnd();

      {handle confirmation}
      function OnConfirm(): boolean; virtual;
      {handle escape}
      function OnEscape(): boolean; virtual;

      {call text changed handlers}
      procedure CallTextChanged();

      protected
         Original,
         Placeholder: StdString;
         Content: StdString;

         ib: record
            CursorPos,
            CursorOfs,
            MaxChars,
            Fw,
            Spacing,
            TextOffset: longint;
         end;

      procedure ibUpdate();
      procedure SizeChanged; override;
   end;

   wdgTInputBoxOnChangeMethod = procedure(wdg: wdgTInputBox);

   { wdgTInputBoxGlobal }

   wdgTInputBoxGlobal = class(specialize wdgTBase<wdgTInputBox>)
      Internal: uiTWidgetClass; static;

      {adds a input-box to a window}
      function Add(const Initial: StdString;
                  const Pos: oxTPoint; const Dim: oxTDimensions): wdgTInputBox;

      {checks if a char is allowed for floating point numbers}
      class function IsFloat(c: char): boolean; static;
   end;

VAR
   wdgInputBox: wdgTInputBoxGlobal;

IMPLEMENTATION

procedure wdgTInputBox.Render();
var
   r: oxTRect;
   f: oxTFont;
   s: StdString;
   cursorWidth: longint;

   renderProperties: longword;

   surfaceColor,
   borderColor: TColor4ub;

   x: single;

begin
   s := '';

   {render input-box block}
   renderProperties := wdgRENDER_BLOCK_SURFACE or wdgRENDER_BLOCK_BORDER;

   if(not CustomDrawnContainer) then begin
      surfaceColor := GetColor(wdgscINPUT_SURFACE);

      if(not IsSelected()) then
         borderColor := GetColor(wdgscINPUT_BORDER)
      else
         borderColor := GetColor(wdgscINPUT_BORDER_SELECTED);

      uiRenderWidget.Box(uiTWidget(self), surfaceColor, borderColor, renderProperties, uiTWindow(wnd).opacity)
   end else
      Control(wdghINPUTBOX_DRAW_CONTAINER);

   f := CachedFont;

   {render input box content, if any}
   if(not CustomDrawnText) then begin
      if(f <> nil) and ((Placeholder <> '') or (Content <> '')) then begin
         r.x := RPosition.x + ib.TextOffset;
         r.y := RPosition.y;
         r.w := Dimensions.w - 1 - ib.TextOffset;
         r.h := Dimensions.h;

         f.Start();

         if(Content <> '') then begin
            s := copy(Content, ib.CursorOfs + 1, ib.MaxChars);
            SetColorBlended(wdgscINPUT_TEXT);
         end else if(Placeholder <> '') then begin
            s := copy(Placeholder, 1, ib.MaxChars);
            SetColorBlended(wdgscINPUT_PLACEHOLDER);
         end;

         f.WriteCentered(s, r, [oxfpCenterVertical]);

         oxf.Stop();
      end;
   end else
      Control(wdghINPUTBOX_DRAW_TEXT);

   {render the input cursor}
   if(not CustomDrawnCursor) then begin
      if (IsSelected()) and (timer.Cur() mod 1000 > 500) then begin
         SetColor(wdgscINPUT_CURSOR);

         if(InputCursorType = wdgINPUT_BOX_CURSOR_NORMAL) then
            cursorWidth := 2
         else
            cursorWidth := f.GetWidth();

         x := RPosition.x + ib.TextOffset + (ib.CursorPos - 1 - ib.CursorOfs) * f.GetWidth(0);

         if(x + cursorWidth - 1 >= RPosition.x + Dimensions.w) then
            cursorWidth := round(RPosition.x + Dimensions.w - x);

         uiDraw.Box(x,
            RPosition.y - 2,
            x + cursorWidth - 1,
            RPosition.y - Dimensions.h + 3);
      end;
   end else
      Control(wdghINPUTBOX_DRAW_CURSOR);
end;

procedure wdgTInputBox.Point(var e: appTMouseEvent; x, {%H-}y: longint);
var
   _pos: longint;

begin
   if(e.Action = appmcPRESSED) then begin
      if(e.Button = appmcLEFT) then begin
         if(ib.Fw <> 0) then
            _pos := (x - ib.TextOffset) div ib.Fw
         else
            _pos := 0;

         ib.CursorPos := ib.CursorOfs + _pos + 1;
         if(ib.CursorPos < 1) then
            ib.CursorPos := 1;

         if(ib.CursorPos > Length(Content) + 1) then
            ib.CursorPos := length(Content) + 1;
      end;
   end;
end;

function wdgTInputBox.Key(var keyEvent: appTKeyEvent): boolean;
var
   c: char;
   what: longword;
   k: appTKey;
   changed: boolean;

procedure doAdd();
begin
   if(Length(Content) < 255) then begin
      insert(c, Content, ib.CursorPos);
      inc(ib.CursorPos);

      if((ib.CursorPos - 1) - ib.CursorOfs > ib.MaxChars) then
         inc(ib.CursorOfs);
   end;

   changed := true;
end;

procedure doDel();
begin
   if(Length(Content) > 0) and (ib.CursorPos <= Length(Content)) then begin
      Delete(Content, ib.CursorPos, 1);

      changed := true;
   end;
end;

procedure doLeft();
var
   i: longint;

begin
   if(ib.CursorPos > 1) then begin
      dec(ib.CursorPos);

      if(ib.CursorPos <= ib.CursorOfs) and (ib.CursorOfs > 0) then begin
         i := 1;
         dec(ib.CursorOfs, i);
      end;
   end;
end;

procedure doRight();
begin
   if(ib.CursorPos <= Length(Content)) then begin
      inc(ib.CursorPos);

      if((ib.CursorPos - 1) - ib.CursorOfs > ib.MaxChars) then
         inc(ib.CursorOfs);
   end;
end;

procedure doBackspace();
begin
   if(Length(Content) > 0) and (ib.CursorPos > 1)then begin
      Delete(Content, ib.CursorPos - 1, 1);

      if(ib.CursorPos > 1) then
         dec(ib.CursorPos);

      if(ib.CursorPos <= ib.CursorOfs + 2) then begin
         if(ib.CursorOfs > ib.MaxChars - 1) then
            dec(ib.CursorOfs, ib.MaxChars - 1)
         else
            ib.CursorOfs := 0;
      end;

      changed := true;
   end;
end;

function inCharacterSet(c: char): boolean;
var
   i: loopint;

begin
   if(not CaseSensitiveCharacterSet) then begin
      for i := 0 to Length(CharacterSet) - 1 do begin
         if(LowerCase(CharacterSet[i]) = LowerCase(c)) then
            exit(true);
      end;
   end else begin
      for i := 0 to Length(CharacterSet) - 1 do begin
         if(CharacterSet[i] = c) then
            exit(true);
      end;
   end;

   Result := false;
end;

begin
   Result := true;
   changed := false;

   k := keyEvent.Key;

   {translate the key to a character}
   c := oxPlatform.TranslateKey(keyEvent);
   c := appk.Translate(k, c);

   {handle keys}
   if(k.Equal(kcBACKSPACE)) then begin
         if(not ReadOnly) and k.IsPressed() then
            doBackspace();
   end else if(k.Equal(kcDEL)) then begin
      if(not ReadOnly) and k.IsPressed() then
         doDel();
   end else if(k.Equal(kcLEFT)) then begin
      {move left/right}
      if(k.IsPressed()) then
         doLeft();
   end else if(k.Equal(kcRIGHT)) then begin
      if(k.IsPressed()) then
         doRight();
   end else if(k.Equal(kcHOME)) then begin
      {go to start/end of input}
      if(k.IsPressed()) then
         GoToHome();
   end else if(k.Equal(kcEND)) then begin
      if(k.IsPressed()) then
         GoToEnd();
   end else if(k.Equal(kcENTER) or k.Equal(kcNUMENTER)) then begin
      {confirm entry}
      if(k.Released()) then
         if(OnConfirm()) then
            exit(true);

      what := wdghINPUTBOX_CONFIRM_PRESSED;

      if(k.Released()) then
         what := wdghINPUTBOX_CONFIRM;

      Result := Control(what) <> -1;
   end else if(k.Equal(kcESC)) then begin
      if(k.Released()) then
         if(OnEscape()) then
            exit(true);

      what := wdghINPUTBOX_ESCAPE_PRESSED;

      if(k.Released()) then
         what := wdghINPUTBOX_ESCAPE;

      Result := Control(what) <> -1;
   end else if(k.Equal(kcU, kmCONTROL)) then begin
      {clear any text before current position}
      if(not ReadOnly) and (k.Released()) then begin
         if(ib.CursorPos > 1) then begin
            changed := true;
            delete(Content, 1, ib.CursorPos);
            GoToHome();
         end;
      end else
         Result := false;
   {other unprocessed key}
   end else begin
      if(c <> #0) then begin
         Result := true;
         if(not ReadOnly) and (not k.Released()) then begin
            if(InputType = wdgINPUT_BOX_TYPE_NORMAL) then begin
               doAdd();
            end else if(InputType = wdgINPUT_BOX_TYPE_NUMERICAL) then begin
               if(c in appNUMERICAL_CHARS) then
                  doAdd();
            end else if(InputType = wdgINPUT_BOX_TYPE_FLOAT) then begin;
               if(appRegional.IsFloatCharacter(c)) then
                  doAdd();
            end else if(InputType = wdgINPUT_BOX_TYPE_RESTRICTED) then begin
               if(inCharacterSet(c)) then
                  doAdd();
            end;
         end;
      end else
         Result := false;
   end;

   {call text changed callbac}
   if(changed) then
      CallTextChanged();
end;

constructor wdgTInputBox.Create();
begin
   inherited;

   ib.CursorPos := 1;
   ib.MaxChars := 1;

   CursorType := uiCURSOR_TYPE_INPUT;
end;

destructor wdgTInputBox.Destroy;
begin
   inherited Destroy;

   SetLength(CharacterSet, 0);
end;

{updates the input box}
procedure wdgTInputBox.ibUpdate();
var
   f: oxTFont;

begin
   ib.CursorPos := 1;
   ib.CursorOfs := 0;

   {figure out the maximum number of characters}
   f := CachedFont;
   if(f <> nil) then begin
      ib.Fw := f.GetWidth();
      ib.Spacing := f.GetHeight() div 3;
      ib.TextOffset  := 1 + ib.Spacing;

      if(ib.Fw <> 0) then begin
         ib.MaxChars := (Dimensions.w - (2 * ib.TextOffset)) div (ib.Fw);
      end else
         ib.MaxChars := 1;
   end;

   GoToEnd();
end;

procedure wdgTInputBox.SizeChanged;
begin
   ibUpdate();
end;

procedure wdgTInputBox.CallTextChanged();
begin
   if(WdgControl <> nil) then
      WdgControl(Self, wdghINPUTBOX_CHANGED);

   if(OnTextChanged <> nil) then
      OnTextChanged(Self);
end;

{widget action}
procedure wdgTInputBox.Action(what: uiTWidgetEvents);
begin
   if(what = uiwdgACTION_RESIZE) then
      ibUpdate();
end;

procedure wdgTInputBox.GetComputedDimensions(out d: oxTDimensions);
begin
   inherited GetComputedDimensions(d);

   d.w := Parent.Dimensions.w - Position.x - wdgDEFAULT_SPACING;
   d.h := CachedFont.GetHeight() + 12;
end;

procedure InitWidget();
begin
   wdgInputBox.Internal.SkinDescriptor := @wdgInputSkinDescriptor;
   wdgInputBox.Internal.Done(wdgTInputBox);

   wdgInputBox := wdgTInputBoxGlobal.Create(wdgInputBox.Internal);
end;

function wdgTInputBoxGlobal.Add(const Initial: StdString;
            const Pos: oxTPoint; const Dim: oxTDimensions): wdgTInputBox;

begin
   Result := wdgTInputBox(uiWidget.Add(internal, Pos, Dim));

   if(Result <> nil) then begin
      {setup the text}
      Result.SetText(Initial, 0);
      Result.AutoSize();

      Result.ibUpdate();
   end;
end;

class function wdgTInputBoxGlobal.IsFloat(c: char): boolean;
begin
   Result := (FormatSettings.DecimalSeparator = c) or (c in appFLOAT_CHARS);
end;

procedure wdgTInputBox.SetText(const txt: StdString; setProperties: longword);
var
   changed: boolean;

begin
   {if we change the text we must also reset the position}
   ib.CursorPos := 1;
   ib.CursorOfs := 0;

   changed := txt <> Content;

   {set the text}
   Content := txt;

   {set the txt as the original string}
   if(setProperties and wdgINPUT_BOX_NOT_ORIGINAL = 0) then
      Original := txt;

   GoToEnd();

   if(changed) and (setProperties and wdgINPUT_BOX_NO_TEXT_CHANGE = 0) then
      CallTextChanged();
end;

procedure wdgTInputBox.SetPlaceholder(const newPlaceholder: StdString);
begin
   Placeholder := newPlaceholder;
end;

function wdgTInputBox.GetText(): StdString;
begin
   Result := Content;
end;

procedure wdgTInputBox.Clear();
begin
   Content := '';
   ib.CursorPos := 1;
   ib.CursorOfs := 0;

   GoToEnd();
end;

procedure wdgTInputBox.GoToHome();
begin
   if(ib.CursorPos <> 1) then begin
      ib.CursorPos := 1;
      ib.CursorOfs := 0;
   end;
end;

procedure wdgTInputBox.GoToEnd();
begin
   ib.CursorPos := Length(Content) + 1;
   ib.CursorOfs := 0;

   if(ib.CursorPos >= ib.MaxChars) then
      ib.CursorOfs  := (ib.CursorPos - 1 ) - ib.MaxChars;
end;

function wdgTInputBox.OnConfirm(): boolean;
begin
   Result := false;
end;

function wdgTInputBox.OnEscape(): boolean;
begin
   Result := false;
end;

procedure setupSkin(s: TObject; wdgSkin: uiPWidgetSkin);
var
   skin: uiTSkin;

begin
   skin := uiTSkin(s);

   wdgSkin^.SetColor(wdgscINPUT_SURFACE, skin.Colors.InputSurface);
   wdgSkin^.SetColor(wdgscINPUT_TEXT, skin.Colors.InputText);
   wdgSkin^.SetColor(wdgscINPUT_CURSOR, skin.Colors.InputText);
   wdgSkin^.SetColor(wdgscINPUT_PLACEHOLDER, skin.Colors.InputPlaceholder);
   wdgSkin^.SetColor(wdgscINPUT_BORDER, skin.Colors.Border);
   wdgSkin^.SetColor(wdgscINPUT_BORDER_SELECTED, skin.Colors.SelectedBorder);
end;

INITIALIZATION
   wdgInputBox.Internal.Register('widget.inputbox', @InitWidget);
   wdgInputSkinDescriptor.Setup := @setupSkin;

END.
