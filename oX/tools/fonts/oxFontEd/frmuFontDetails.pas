{$MODE OBJFPC}{$H+}
UNIT frmuFontDetails;

INTERFACE

USES
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons,
  {units}
  uFontEd;

TYPE

  { TfrmFontDetails }

  TfrmFontDetails = class(TForm)
    btnOK: TBitBtn;
    btnRevert: TBitBtn;
    btnCancel: TBitBtn;
    edTexName: TEdit;
    edAuthor: TEdit;
    edFontName: TEdit;
    lblTexName: TLabel;
    lblAuthor: TLabel;
    lblDescription: TLabel;
    lblFontName: TLabel;
    mDescription: TMemo;
    procedure btnCancelClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnRevertClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

VAR
  frmFontDetails: TfrmFontDetails;

IMPLEMENTATION

{$R *.lfm}

{ TfrmFontDetails }

procedure TfrmFontDetails.btnCancelClick(Sender: TObject);
begin
  Close();
end;

procedure TfrmFontDetails.btnOKClick(Sender: TObject);
begin
   tfd.Author        := edAuthor.Text;
   tfd.TextureName   := edTexName.Text;
   tfd.Name          := edFontName.Text;
   tfd.Description   := mDescription.Lines.Text;

   Close();
end;

procedure Revert();
begin
   frmFontDetails.edAuthor.Text := tfd.Author;
   frmFontDetails.edTexName.Text := tfd.TextureName;
   frmFontDetails.edFontName.Text := tfd.Name;

   frmFontDetails.mDescription.Lines.Clear();
   frmFontDetails.mDescription.Append(tfd.Description);
end;

procedure TfrmFontDetails.btnRevertClick(Sender: TObject);
begin
   Revert();
end;

procedure TfrmFontDetails.FormShow(Sender: TObject);
begin
   Revert();
end;

END.
