{
   oxeduFileInspectors, handles file inspectors
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduGenericFileInspector;

INTERFACE

   USES
      sysutils, uStd, uFileUtils,
      uBinarySize,
      {ox}
      oxuFileIcons,
      {ui}
      uiuFiles,
      uiWidgets, uiuWidget,
      wdguLabel, wdguWorkbar, wdguGroup, wdguImage, wdguFileList, wdguList,
      {oxed}
      uOXED, oxeduWindow, oxeduwndInspector,
      oxeduInspectFile;

TYPE

   { oxedTGenericFileInspector }

   oxedTGenericFileInspector = class(oxedTInspectFile)
      wdg: record
         Information: wdgTGroup;
         Icon: wdgTImage;
         Name,
         Size,
         Time,
         Attributes: wdgTLabel;
      end;

      procedure SetFile(const fn: StdString; fd: PFileDescriptor = nil); override;
      procedure Open(wnd: oxedTWindow); override;
      procedure SizeChanged(wnd: oxedTWindow); override;
   end;

VAR
   oxedGenericFileInspector: oxedTGenericFileInspector;

IMPLEMENTATION

procedure init();
begin
   oxedGenericFileInspector := oxedTGenericFileInspector.Create();
   oxedInspectFile.GenericInspector := oxedGenericFileInspector;
end;

procedure deinit();
begin
   if(oxedInspectFile.GenericInspector = oxedGenericFileInspector) then
      oxedInspectFile.GenericInspector := nil;

   FreeObject(oxedGenericFileInspector);
end;

{ oxedTGenericFileInspector }

procedure oxedTGenericFileInspector.SetFile(const fn: StdString; fd: PFileDescriptor);
var
   inspector: oxedTInspectorWindow;
   fileDescriptor: TFileDescriptor;
   attributes: TAppendableString = '';
   icon: wdgTListGlyph;

begin
   inspector := oxedTInspectorWindow(oxedInspector.Instance);

   if(fn <> '') then begin
      wdg.Name.Enable(true);
      wdg.Name.SetCaption(fn);

      wdg.Icon.SetVisible();

      if(fd = nil) then begin
         FileUtils.GetFileInfo(fn, fileDescriptor);
         fd := @fileDescriptor;
      end;

      icon := wdgFileList.GetFileIcon(fd^, false);
      wdg.Icon.SetImage(icon.Glyph);
      wdg.Icon.Color := icon.Color;

      attributes := '';
      if(fd^.IsHidden()) then
         attributes.Add('hidden');

      if(fd^.Attr and faSysFile{%H-} > 0) then
         attributes.Add('system', ',');

      if(fd^.Attr and faEncrypted{%H-} > 0) then
         attributes.Add('encrypted', ',');

      if(fd^.Attr and faCompressed{%H-} > 0) then
         attributes.Add('compressed', ',');

      if(fd^.Attr and faReadOnly{%H-} > 0) then
         attributes.Add('read-only', ',');

      wdg.Attributes.SetCaption(attributes);
      wdg.Attributes.SetVisibility(attributes <> '');

      if(not fd^.IsDirectory()) then
         wdg.Size.SetCaption('Size: ' + getiecByteSizeHumanReadable(fd^.Size));

      wdg.Size.SetVisibility(not fd^.IsDirectory());

      wdg.Time.SetCaption('Time: ' + uiTFiles.GetModifiedTime(fd^.Time, 0, true));
   end else begin
      wdg.Name.Enable(false);
      wdg.Name.SetCaption('');
      wdg.Size.SetInvisible();
      wdg.Size.SetCaption('');
      wdg.Icon.SetInvisible();
   end;

   SizeChanged(inspector);
end;

procedure oxedTGenericFileInspector.Open(wnd: oxedTWindow);
var
   inspector: oxedTInspectorWindow;
   group: oxedTInspectorWindowGroup;

begin
   inspector := oxedTInspectorWindow(wnd);

   { header }
   inspector.wdg.Header := wdgWorkbar.Add(oxedInspector.Instance);

   uiWidget.PushTarget();
   inspector.wdg.Header.SetTarget();

   wdg.Icon := wdgImage.Add();
   wdg.Name := wdgLabel.Add('');

   uiWidget.PopTarget();

   { transform group }
   group := inspector.AddGroup('Information');

   wdg.Information := group.Wdg;
   uiWidget.PushTarget();
   wdg.Information.SetTarget();

   wdg.Size := wdgLabel.Add('');
   wdg.Attributes := wdgLabel.Add('');
   wdg.Time := wdgLabel.Add('');

   uiWidget.PopTarget();

   SetFile('');
end;

procedure oxedTGenericFileInspector.SizeChanged(wnd: oxedTWindow);
var
   inspector: oxedTInspectorWindow;
   h: loopint;

begin
   inspector := oxedTInspectorWindow(wnd);
   inspector.wdg.Header.Move(0, wnd.Dimensions.h - 1);
   inspector.wdg.Header.Resize(wnd.Dimensions.w, 32);

   h := round(inspector.wdg.Header.Dimensions.h * 0.85);
   wdg.Icon.Resize(h, h);
   wdg.Icon.Move(wdgDEFAULT_SPACING, 20);
   wdg.Icon.SetPosition(wdgPOSITION_VERTICAL_CENTER);

   wdg.Name.MoveRightOf(wdg.Icon);
   wdg.Name.SetPosition(wdgPOSITION_VERTICAL_CENTER);
   wdg.Name.AutoSetDimensions(true);

   if(wdg.Attributes.Caption <> '') then begin
      wdg.Attributes.Move(wdgDEFAULT_SPACING, wdg.Information.Dimensions.h);
      wdg.Attributes.SetSize(wdgWIDTH_MAX_HORIZONTAL);

      wdg.Size.MoveBelow(wdg.Attributes, 0);
   end else
      wdg.Size.Move(wdgDEFAULT_SPACING, wdg.Information.Dimensions.h);

   wdg.Size.SetSize(wdgWIDTH_MAX_HORIZONTAL);

   wdg.Time.Move(uiWidget.LastRect.BelowOf(0, 0, false));
   wdg.Time.SetSize(wdgWIDTH_MAX_HORIZONTAL);
end;

INITIALIZATION
   oxed.Init.Add('inspector.file.generic', @init, @deinit);

END.
