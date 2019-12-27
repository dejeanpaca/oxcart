{
   Started On:    11.03.2011.
}

{$MODE OBJFPC}{$H+}
UNIT frmuMain;

INTERFACE

USES
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons,
  {}
  uStd, StringUtils, uFile, uOX, oxuTFD;

TYPE

  { TfrmMain }

  TfrmMain = class(TForm)
     btnLoad: TBitBtn;
     btnSave: TBitBtn;
     btnQuit: TBitBtn;
     btnCheck: TBitBtn;
     edBase: TEdit;
     edTex: TEdit;
     edAuthor: TEdit;
     edWidth: TEdit;
     edName: TEdit;
     edHeight: TEdit;
     edSpacingX: TEdit;
     edSpacingY: TEdit;
     edChars: TEdit;
     edcpline: TEdit;
     edLines: TEdit;
     lblBase: TLabel;
     lblName: TLabel;
     lblTex: TLabel;
     lblAuthor: TLabel;
     lblDescription: TLabel;
     lblWidth: TLabel;
     lblLines: TLabel;
     lblHeight: TLabel;
     lblSpacingX: TLabel;
     lblSpacingY: TLabel;
     lblChars: TLabel;
     lblcpline: TLabel;
     mDescription: TMemo;
     dlgOpen: TOpenDialog;
     dlgSave: TSaveDialog;
     procedure btnCheckClick(Sender: TObject);
     procedure btnLoadClick(Sender: TObject);
     procedure btnQuitClick(Sender: TObject);
     procedure btnSaveClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

VAR
  frmMain: TfrmMain;
  tfd: oxTTFD;

IMPLEMENTATION

{$R *.lfm}

function PrepareTFD(): boolean;
var
   f: TfrmMain;
   i, code: longint;
   errm: string = '';

begin
   f := frmMain;
   result := false;

   tfd.name := f.edName.Text;
   if(tfd.name = '') then
      errm := #10'Font name should not be empty.';

   tfd.TextureName := f.edTex.Text;
   if(tfd.TextureName = '') then
      errm := #10'Texture name should not be empty.';

   tfd.author := f.edAuthor.Text;

   {prepare description}
   tfd.description := '';
   if(f.mDescription.Lines.Count > 0) then begin
      for i := 0 to (f.mDescription.Lines.Count-1) do begin
         if(i > 0) then
            tfd.description := tfd.description + #10 + f.mDescription.Lines[i]
         else
            tfd.description := f.mDescription.Lines[i];
      end;
   end;

   {width}
   val(f.edWidth.Text, tfd.width, code);
   if(code <> 0) then
      errm := errm + #10'Entered width is not a valid number.';

   val(f.edHeight.Text, tfd.height, code);
   if(code <> 0) then
      errm := errm + #10'Entered height is not a valid number.';

   val(f.edSpacingX.Text, tfd.spacex, code);
   if(code <> 0) then
      errm := errm + #10'Entered horizontal spacing is not a valid number.';

   val(f.edSpacingY.Text, tfd.spacey, code);
   if(code <> 0) then
      errm := errm + #10'Entered vertical spacing is not a valid number.';

   val(f.edBase.Text, tfd.base, code);
   if(code <> 0) then
      errm := errm + #10'Entered base is not a valid number.';

   val(f.edChars.Text, tfd.chars, code);
   if(code <> 0) then
      errm := errm + #10'Entered character count is not a valid number.';

   val(f.edcpline.Text, tfd.cpline, code);
   if(code <> 0) then
      errm := errm + #10'Entered characters per line is not a valid number.';

   val(f.edLines.Text, tfd.lines, code);
   if(code <> 0) then
      errm := errm + #10'Entered line count is not a valid number.';

   if(errm = '') then
      result := true
   else
      MessageDlg('Input errors',
      'One or more errors were encountered in your input:'+errm,
      mtError, [mbOk], 0);
end;

procedure SetTFD();
var
   f: TfrmMain;

begin
   f := frmMain;

   { attributes }
   f.edWidth.Text       := sf(tfd.Width);
   f.edHeight.Text      := sf(tfd.Height);
   f.edSpacingX.Text    := sf(tfd.SpaceX);
   f.edSpacingY.Text    := sf(tfd.SpaceY);
   f.edChars.Text       := sf(tfd.Chars);
   f.edcpline.Text      := sf(tfd.CPLine);
   f.edLines.Text       := sf(tfd.Lines);
   f.edBase.Text        := sf(tfd.Base);

   { strings }
   f.edName.Text        := tfd.Name;
   f.edTex.Text         := tfd.TextureName;
   f.edAuthor.Text      := tfd.Author;
   f.mDescription.Lines.Clear();

   { description }
   repeat
      f.mDescription.Lines.Add(CopyToDel(tfd.Description, #10));
   until (tfd.description = '');
end;

{ TfrmMain }

procedure TfrmMain.btnQuitClick(Sender: TObject);
begin
   Close();
end;

procedure TfrmMain.btnSaveClick(Sender: TObject);
var
   error: TError;

begin
   if(PrepareTFD()) then begin
      if(dlgSave.Execute()) then begin
         error := oxTFD.Save(tfd, dlgSave.FileName);
         if(error <> 0) then begin
            MessageDlg('Error saving TFD', 'Error codes: ' + eGetCodeName(error), mtError, [mbOK], 0);
         end;
      end;
   end;
end;

procedure TfrmMain.btnLoadClick(Sender: TObject);
var
   error: TError;

begin
   if(dlgOpen.Execute()) then begin
      error := oxTFD.Load(tfd, dlgOpen.FileName);
      if(error <> 0) then begin
         MessageDlg('Error loading TFD', 'Error codes: ' + eGetCodeName(error), mtError, [mbOK], 0);
      end;
      SetTFD();
   end;
end;

procedure TfrmMain.btnCheckClick(Sender: TObject);
begin
   if(PrepareTFD()) then
      MessageDlg('Ok', 'Everything seems to be ok.', mtInformation, [mbOK], 0);
end;

END.
