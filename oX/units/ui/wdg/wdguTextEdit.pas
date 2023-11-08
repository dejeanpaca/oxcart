{
   wdguTextEdit, text editor widget
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT wdguTextEdit;

INTERFACE

   USES
      uStd, StringUtils, uTiming, uColors, uLog, uFile, uFiles,
      {app}
      appuKeys, appuRegional,
      {oX}
      oxuTypes, oxuFont,
      {ui}
      uiuDraw, uiuWidget, uiWidgets, uiuWidgetRender, uiuRegisteredWidgets, uiuTypes, uiuWindowTypes,
      wdguBase, wdguInputBox;

TYPE
   { wdgTTextEdit }

   wdgTTextEdit = class(uiTWidget)
      public
         {text is read only}
         ReadOnly,
         {is the text edit container custom drawn}
         CustomDrawnContainer,
         {custom drawn cursor}
         CustomDrawnCursor,
         {can you move the cursor past the end of line}
         CursorPastEndOfLine: boolean;

         {current line}
         CurrentLine: StdString;

         ib: record
            CursorPos,
            CursorOfs,
            LinePos,
            MaxChars,
            MaxLines,
            Fw,
            Fh,
            TextOffset,
            VerticalOffset,
            VerticalSpacing,
            LineOffset,
            {text position that'll be kept if the user moves through lines}
            TargetTextPosition: loopint;
         end;

         Lines: TSimpleStringList;

         {callback when text is changed}
         OnTextChanged: procedure(wdg: wdgTTextEdit);

         {input box type}
         InputType: wdgTInputBoxType;
         {cursor type}
         InputCursorType: wdgTInputBoxCursorType;
         {restricted character set if input type is WDG_INPUT_BOX_TYPE_RESTRICTED}
         CharacterSet: array of char;
         {is the restricted character set case sensitive}
         CaseSensitiveCharacterSet: boolean;

         constructor Create(); override;

         function Key(var keyEvent: appTKeyEvent): boolean; override;

         procedure Render(); override;

         {load a file}
         function Load(const fn: StdString): boolean;
         {load a file}
         function Load(const text: TStringArray): boolean;

         {clears a text box}
         procedure Clear();
         {sets input home position}
         procedure GoToHome();
         procedure GoToEnd();
         procedure GoToTop();
         procedure GoToBottom();
         procedure PageDown();
         procedure PageUp();

         {call text changed handlers}
         procedure CallTextChanged();
         {set current line}
         procedure ChangeCurrentLine(newLinePosition: loopint);

         protected
            procedure SetCursorPos(newPos: loopint);
            procedure ibOnLoad();
            procedure ibUpdate();
            procedure SizeChanged(); override;
            procedure FontChanged(); override;
   end;

   { wdgTTextEditGlobal }

   wdgTTextEditGlobal = object(specialize wdgTBase<wdgTTextEdit>)
   end;

VAR
   wdgTextEdit: wdgTTextEditGlobal;

IMPLEMENTATION

{ wdgTTextEdit }

constructor wdgTTextEdit.Create();
begin
   inherited;

   SetCursorPos(1);

   Lines.Increment := 1024;
   CursorPastEndOfLine := true;
   { NOTE: Padding should also include borders }
   SetPadding(3);
end;

function wdgTTextEdit.Key(var keyEvent: appTKeyEvent): boolean;
var
   c: char;
   what: longword;
   k: appTKey;
   changed: boolean;

procedure doAdd();
var
   i: loopint;

begin
   if(Length(CurrentLine) < 255) then begin
      if(ib.CursorPos > Length(CurrentLine)) then begin
         for i := ib.CursorPos to Length(CurrentLine) do
            Insert(' ', CurrentLine, ib.CursorPos);
      end;

      Insert(c, CurrentLine, ib.CursorPos);
      SetCursorPos(ib.CursorPos + 1);
   end;

   changed := true;
end;

procedure doDel();
begin
   if(Length(CurrentLine) > 0) and (ib.CursorPos <= Length(CurrentLine)) then begin
      Delete(CurrentLine, ib.CursorPos, 1);

      changed := true;
   end;
end;

procedure doLeft();
begin
   if(ib.CursorPos > 1) then
      SetCursorPos(ib.CursorPos - 1);
end;

procedure doRight();
begin
   if((ib.CursorPos <= Length(CurrentLine)) or CursorPastEndOfLine) then
      SetCursorPos(ib.CursorPos + 1);
end;

procedure doUp();
begin
   if(ib.LinePos > 0) then
      ChangeCurrentLine(ib.LinePos - 1);
end;

procedure doDown();
begin
   if(ib.LinePos < Lines.n - 1) then
      ChangeCurrentLine(ib.LinePos + 1);
end;

procedure doBackspace();
begin
   if(Length(CurrentLine) > 0) and (ib.CursorPos > 1) then begin
      if(ib.CursorPos <= Length(CurrentLine) + 1) then
         Delete(CurrentLine, ib.CursorPos - 1, 1);

      if(ib.CursorPos > 1) then
         SetCursorPos(ib.CursorPos - 1);

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
   c := appk.Translate(k);

   {if the translation succeeded we have a character to add to the string}
   if(c <> #0) then begin
      if(not ReadOnly) and (not k.Released()) then begin
         if(InputType = wdgINPUT_BOX_TYPE_NORMAL) then begin
            doAdd();
         end else if(InputType = wdgINPUT_BOX_TYPE_NUMERICAL) then begin
            if(c in appNUMERICAL_CHARS) then
               doAdd();
         end else if(InputType = wdgINPUT_BOX_TYPE_FLOAT) then begin
            if(appRegional.IsFloatCharacter(c)) then
               doAdd();
         end else if(InputType = wdgINPUT_BOX_TYPE_RESTRICTED) then begin
            if(inCharacterSet(c)) then
               doAdd();
         end;
      end;
   {else we'll process the key}
   end else begin
      if(k.Equal(kcBACKSPACE)) then begin
         if(not ReadOnly) and k.IsPressed() then
            doBackspace();
      end else if(k.Equal(kcDEL)) then begin
         if(not ReadOnly) and k.IsPressed() then
            doDel();
      end else if(k.Equal(kcLEFT)) then begin
         if(k.IsPressed()) then
            doLeft()
      end else if(k.Equal(kcRIGHT)) then begin
         if(k.IsPressed()) then
            doRight();
      end else if(k.Equal(kcUP)) then begin
         if(k.IsPressed()) then
            doUp();
      end else if(k.Equal(kcDOWN)) then begin
         if(k.IsPressed()) then
            doDown();
      end else if(k.Equal(kcHOME)) then begin
         {go to start/end of input}
         if(k.IsPressed()) then begin
            if(not k.State.IsSet(kmALT)) then
               GoToHome()
            else
               GoToTop();
         end;
      end else if(k.Equal(kcEND)) then begin
         if(k.IsPressed()) then begin
            if(not k.State.IsSet(kmALT)) then
               GoToEnd()
            else
               GoToBottom();
         end;
      end else if(k.Equal(kcPGUP)) then begin
         if(k.Released()) then
            PageUp();
      end else if(k.Equal(kcPGDN)) then begin
         if(k.Released()) then
            PageDown();
      end else if(k.Equal(kcEND) or k.Equal(kcNUMENTER)) then begin
         {confirm entry}
         what := wdghINPUTBOX_CONFIRM_PRESSED;

         if(k.Released()) then
            what := wdghINPUTBOX_CONFIRM;

         if(Control(what) = -1) then
            Result := false;
      end else if(k.Equal(kcESC)) then begin
         what := wdghINPUTBOX_ESCAPE_PRESSED;

         if(k.Released()) then
            what := wdghINPUTBOX_ESCAPE;

         if(Control(what) = -1) then
            Result := false;
      end else if(k.Equal(kcU, kmCONTROL)) then begin
         {clear any text before current position}
         if(not ReadOnly) and (k.Released()) then begin
            if(ib.CursorPos > 1) then begin
               changed := true;
               delete(CurrentLine, 1, ib.CursorPos);
               GoToHome();
            end;
         end else
            Result := false;
      {other unprocessed key}
      end else
         Result := false;
   end;

   {call text changed callbac}
   if(changed) then
      CallTextChanged();
end;

procedure wdgTTextEdit.Render();
var
   f: oxTFont;
   x,
   y,
   i,
   current,
   cursorWidth: loopint;
   renderProperties: TBitSet;
   surfaceColor,
   borderColor: TColor4ub;
   s: StdString;

begin
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

   f.Start();
   SetColorBlended(wdgscINPUT_TEXT);

   x := RPosition.x + ib.TextOffset;
   y := RPosition.y - ib.VerticalOffset - ib.Fh;

   for i := 0 to ib.MaxLines do begin
      current := i + ib.LineOffset;

      if(current < Lines.n) then begin
         if(ib.LinePos <> current) then
            s := Copy(Lines.List[current], ib.CursorOfs + 1, ib.MaxChars + 1)
         else
            s := Copy(CurrentLine, ib.CursorOfs + 1, ib.MaxChars + 1);

         oxf.GetSelected().Write(x, y, s);
      end;

      dec(y, ib.Fh + ib.VerticalSpacing);
      {since we rendere an extra line to fill the bottom space, break if we can't show it}
      if(y <= RPosition.y - Dimensions.h) then
         break;
   end;

   oxf.Stop();

   {render the input cursor}
   if(not CustomDrawnCursor) then begin
      if (IsSelected()) and (timer.Cur() mod 1000 > 500) then begin
         SetColor(wdgscINPUT_CURSOR);

         if(InputCursorType = wdgINPUT_BOX_CURSOR_NORMAL) then
            cursorWidth := 2
         else
            cursorWidth := f.GetWidth();

         x := RPosition.x + ib.TextOffset + (ib.CursorPos - 1 - ib.CursorOfs) * ib.Fw;
         y := RPosition.y - ((ib.LinePos - ib.LineOffset) * (ib.Fh + ib.VerticalSpacing)) - ib.VerticalOffset;

         if(x + cursorWidth - 1 >= RPosition.x + Dimensions.w) then
            cursorWidth := round(RPosition.x + Dimensions.w - x);

         uiDraw.Box(x, y, x + cursorWidth - 1, y - ib.Fh);
      end;
   end else
      Control(wdghINPUTBOX_DRAW_CURSOR);
end;

function wdgTTextEdit.Load(const fn: StdString): boolean;
var
   f: TFile;
   newLines: TStringArray;

begin
   Result := false;

   fFile.Init(f);
   f.Open(fn);
   if(f.Error = 0) then begin
      Lines.Dispose();

      if(f.ReadStrings(newLines) = eNONE) then begin
         Load(newLines);

         Result := true;
      end else
         log.e('Failed to read: ' + fn + ': ' + f.GetErrorString());
   end else
      log.e('Failed to open: ' + fn + ': ' + f.GetErrorString());

   f.Close();
end;

function wdgTTextEdit.Load(const text: TStringArray): boolean;
var
   i: loopint;

begin
   Result := false;

   Lines.AllocateInc(Length(text));

   for i := 0 to Length(text) - 1 do begin
      Lines[i] := text[i];
   end;

   Lines.n := Length(text);

   if(Lines.n > 0) then
      CurrentLine := Lines.List[0];

   ibOnLoad();
   ibUpdate();
   ChangeCurrentLine(0);
end;

procedure wdgTTextEdit.Clear();
begin
   CurrentLine := '';
   SetCursorPos(1);
   ib.CursorOfs := 0;

   GoToEnd();
end;

procedure wdgTTextEdit.GoToHome();
begin
   if(ib.CursorPos <> 1) then begin
      SetCursorPos(1);
   end;
end;

procedure wdgTTextEdit.GoToEnd();
begin
   SetCursorPos(Length(CurrentLine) + 1);
end;

procedure wdgTTextEdit.GoToTop();
begin
   if(Lines.n > 0) then
      ChangeCurrentLine(0);
end;

procedure wdgTTextEdit.GoToBottom();
begin
   if(Lines.n > 0) then
      ChangeCurrentLine(Lines.n - 1);
end;

procedure wdgTTextEdit.PageDown();
begin
   ChangeCurrentLine(ib.LinePos + ib.MaxLines);
end;

procedure wdgTTextEdit.PageUp();
begin
   ChangeCurrentLine(ib.LinePos - ib.MaxLines);
end;

procedure wdgTTextEdit.CallTextChanged();
begin
   if(WdgControl <> nil) then
      WdgControl(Self, wdghINPUTBOX_CHANGED);

   if(OnTextChanged <> nil) then
      OnTextChanged(Self);
end;

procedure wdgTTextEdit.ChangeCurrentLine(newLinePosition: loopint);
var
   previousTarget: loopint;

begin
   if(ib.LinePos > 0) and (ib.LinePos < Lines.n) then
      Lines[ib.LinePos] := CurrentLine;

   ib.LinePos := newLinePosition;

   if(ib.LinePos >= Lines.n) then
      ib.LinePos := Lines.n - 1;

   if(ib.LinePos < 0) then
      ib.LinePos := 0;

   if(ib.LinePos < Lines.n) then
      CurrentLine := Lines.List[ib.LinePos]
   else
      CurrentLine := '';

   if(ib.LineOffset >= ib.LinePos) then
      ib.LineOffset := ib.LinePos;

   if(ib.LinePos > ib.LineOffset + ib.MaxLines - 1) then
      ib.LineOffset := ib.LinePos - ib.MaxLines + 1;

   if(not CursorPastEndOfLine) then begin
      previousTarget := ib.TargetTextPosition;
      if(ib.CursorPos > Length(CurrentLine)) then begin
         SetCursorPos(Length(CurrentLine));
      end else begin
         if(ib.TargetTextPosition <> ib.CursorPos) then
            SetCursorPos(ib.TargetTextPosition);
      end;
      ib.TargetTextPosition := previousTarget;
   end;
end;

procedure wdgTTextEdit.SetCursorPos(newPos: loopint);
begin
   ib.CursorPos := newPos;

   if(ib.CursorPos < 1) then
      ib.CursorPos := 1;

   ib.TargetTextPosition := ib.CursorPos;

   if(ib.CursorOfs >= ib.CursorPos) then
      ib.CursorOfs := ib.CursorPos - 1;

   if(ib.CursorOfs + ib.MaxChars + 1 < ib.CursorPos) then
      ib.CursorOfs := ib.CursorPos - ib.MaxChars - 1;

   if(ib.CursorOfs < 0) then
      ib.CursorOfs := 0;
end;

procedure wdgTTextEdit.ibOnLoad();
begin
   ib.CursorPos := 1;
   ib.TargetTextPosition := 1;
   ib.CursorOfs := 0;
   ib.LineOffset := 0;
   ib.LinePos := 0;
end;

procedure wdgTTextEdit.ibUpdate();
var
   f: oxTFont;

begin
   {figure out the maximum number of characters}
   f := CachedFont;

   if(f <> nil) then begin
      ib.Fw := f.GetWidth();
      ib.Fh := f.GetHeight();
      ib.TextOffset := PaddingLeft;
      ib.VerticalOffset := PaddingTop;

      if(ib.Fw <> 0) then
         ib.MaxChars := (Dimensions.w - ib.TextOffset - PaddingRight) div (ib.Fw)
      else
         ib.MaxChars := 1;

      if(ib.Fh <> 0) then
         ib.MaxLines := (Dimensions.h - ib.VerticalOffset - PaddingBottom) div (ib.Fh + ib.VerticalSpacing)
      else
         ib.MaxLines := 1;
   end;
end;

procedure wdgTTextEdit.SizeChanged();
begin
   ibUpdate();
end;

procedure wdgTTextEdit.FontChanged();
begin
   inherited FontChanged();
   ib.VerticalSpacing := CachedFont.GetHeight() div 8;
end;

INITIALIZATION
   wdgTextEdit.Create('text_edit');
   wdgTextEdit.Internal.SkinDescriptor := wdgInputBox.Internal.SkinDescriptor;

END.
