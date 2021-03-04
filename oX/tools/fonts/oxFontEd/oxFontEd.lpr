{$INCLUDE oxheader.inc}
PROGRAM oxFontEd;

USES
   {$IFDEF UNIX}{$IFDEF UseCThreads}
   cthreads,
   {$ENDIF}{$ENDIF}
   Interfaces, // this includes the LCL widgetset
   Forms, frmuMain, frmuFontDetails
   { you can add units after this };

{$R *.res}

BEGIN
   Application.Initialize();
      Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmFontDetails, frmFontDetails);
   Application.Run();
END.

