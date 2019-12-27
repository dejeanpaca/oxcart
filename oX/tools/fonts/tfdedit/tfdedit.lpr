{$MODE OBJFPC}{$H+}
PROGRAM tfdedit;

USES
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, frmuMain
  {}
  {$IFNDEF NO_LOGGING}, uLog{$ENDIF}, uFiles;

{$R *.res}

BEGIN
   {$IFNDEF NO_LOGGING}
   log.InitStd('tfdedit.log', 'TFDEdit', logcREWRITE);
   {$ENDIF}

   Application.Initialize();
      Application.CreateForm(TfrmMain, frmMain);
   Application.Run();
END.

