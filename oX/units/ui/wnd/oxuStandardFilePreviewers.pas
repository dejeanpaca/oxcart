{
   oxuStandardFilePreviewers, standard file previewers
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuStandardFilePreviewers;

INTERFACE

   USES
      {ox}
      oxuTypes,
      uiWidgets, wdguTextEdit,
      oxuFilePreviewWindow;

TYPE

   { oxuiTTextFilePreviewWindow }

   oxuiTTextFilePreviewWindow = class(oxuiTFilePreviewWindow)
      wdg: record
         Text: wdgTTextEdit;
      end;

      procedure OnCreateWidgets(); override;
   end;

IMPLEMENTATION

{ oxuiTTextFilePreviewWindow }

procedure oxuiTTextFilePreviewWindow.OnCreateWidgets();
begin
   wdg.Text := wdgTextEdit.Add(oxNullPoint, oxNullDimensions);
   wdg.Text.FillWindow();

   wdg.Text.ReadOnly := true;
   wdg.Text.Load(CurrentFile);
end;

INITIALIZATION
   oxTFilePreviewWindow.AddHandler('.txt', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.inc', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.pas', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.pp', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.h', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.c', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.cs', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.cpp', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.html', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.xml', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.yml', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.yaml', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.json', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.js', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.java', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.php', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.gitignore', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.gitmodules', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.md', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.dvar', oxuiTTextFilePreviewWindow);
   oxTFilePreviewWindow.AddHandler('.config', oxuiTTextFilePreviewWindow);

END.
