{
   wdguFileList, file list widget
   Copyright (C) 2017. Dejan Boras

   Started On:    09.01.2017.

   TODO: Implement file icons
}

{$INCLUDE oxdefines.inc}
UNIT wdguFileList;

INTERFACE

   USES
      sysutils, uStd, uBinarySize, uFileUtils, StringUtils, uTiming, uColors,
      {app}
      appuKeys, appuMouse,
      {oX}
      oxuTypes, oxuFont, oxuFileIcons, oxuRender, oxuTexture, oxuRenderUtilities,
      {ui}
      uiuTypes, uiuWindowTypes, uiuSkinTypes, uiuFiles,
      uiuWidget, uiWidgets, uiuRegisteredWidgets, uiuDrawUtilities,
      wdguBase, wdguGrid, wdguList, wdguHierarchyList;

TYPE
   { wdgTFileList }

   wdgTFileList = class(wdgTStringGrid)
      CurrentPath,
      Pattern: StdString;
      Files: TFileDescriptorList;
      FileAttributes: LongInt;
      Today: TDateTime;

      {show file icons}
      ShowFileIcons,
      {list only directories}
      DirectoriesOnly,
      {include back navigation file}
      IncludeParentDirectoryLink,
      {show hidden files}
      ShowHiddenFiles: Boolean;

      Callbacks: record
         PathChange: TProcedure;
      end;

      constructor Create(); override;
      destructor Destroy(); override;

      procedure RenderStart(); override;
      procedure RenderColumn(index, columnIndex: loopint; var r: oxTRect); override;

      function GetValue(index, column: loopint): StdString; override;
      function GetFile(index, column: loopint): PFileDescriptor;
      function GetModifiedTime(givenTime: longint; full: boolean = false): StdString;
      function GetFilePath(index: loopint): StdString;

      {find everything in the given path}
      procedure FindAll(const path: StdString);
      {load the current directory}
      procedure LoadCurrent();
      {loads current path as empty (limit to current path)}
      procedure LoadCurrentEmpty();
      {reload the current directory}
      procedure Reload();

      {open directory with the specified file index (if not a directory it does nothing)}
      procedure OpenDirectory(index: loopint);
      {set into directories only mode}
      procedure SetDirectoriesOnly(enabled: boolean = true);

      function GetItemCount(): loopint; override;
      function GetGridItemCount(): loopint; override;

      function Key(var k: appTKeyEvent): boolean; override;

      {go to the parent directory}
      procedure GoUp();

      procedure RemoveAll(); override;

      protected
         procedure FileClicked(index: loopint; button: TBitSet = appmcLEFT); virtual;
         procedure FileDoubleClicked({%H-}index: loopint; {%H-}button: TBitSet); virtual;

         procedure GridItemClicked(index: loopint; button: TBitSet = appmcLEFT); override;
         procedure GridItemDoubleClicked(index: loopint; button: TBitSet); override;

         procedure OnPathChanged(); virtual;
         procedure OnGridHover(index: loopint); override;
   end;

   { wdgTFileGrid }

   wdgTFileGrid = class(wdgTFileList)
      constructor Create; override;
   end;

   { wdgTHierarchicalFileList }

   wdgTHierarchicalFileList = class(wdgTHierarchyList)
      {base path}
      Path,
      {pattern to match files against}
      Pattern: StdString;
      {all files}
      Files,
      {currently found files, temporarily stored}
      CurrentFiles: TFileDescriptorList;
      {attributes to match files against}
      FileAttributes: LongInt;

      {list only directories}
      DirectoriesOnly,
      {include back navigation file}
      IncludeParentDirectoryLink,
      {show hidden files}
      ShowHiddenFiles: Boolean;

      RootFile: StdString;
      BaseLevel: loopint;

      constructor Create; override;
      destructor Destroy; override;

      function GetValue(index: loopint): StdString; override;
      function GetGlyph(index: loopint): wdgTListGlyph; override;

      procedure Load; override;

      {loads current directory}
      procedure LoadCurrent();
      {loads current directory}
      procedure LoadCurrentEmpty();
      {load path}
      procedure LoadPath(const newPath: StdString);
      {load path}
      procedure LoadPathEmpty(const newPath: StdString);
      {expands path}
      procedure ExpandPath(const newPath: StdString);

      {get complete path for a given item}
      function GetPath(index: loopint): StdString;

      function GetSubItems(index: loopint; ref: pointer): TSimplePointerList; override;
      function Expandable(index: loopint): boolean; override;

      procedure RemoveAll; override;

      procedure Reload();

      procedure OnLoad(); virtual;

      protected
         procedure ExpandData(const items: TSimplePointerList; index: loopint); override;
         procedure CollapseData(index, count: loopint); override;

         {Return the index for the file reference matching the name and level, or -1 if nothing found.
         Can be given a starting point to speed up the process.}
         function FindFileReference(const name: StdString; fileLevel: loopint; startFrom: loopint = 0): loopint;
   end;

   { wdgTFileListGlobal }

   wdgTFileListGlobal = class(specialize wdgTBase<wdgTFileList>)
      Internal: uiTWidgetClass; static;
      DirectoryColor,
      FileColor: TColor4ub; static;

      {get the file icon for a given file descriptor}
      class function GetFileIcon(const f: TFileDescriptor): wdgTListGlyph; static;
   end;

   { wdgTFileGridGlobal }

   wdgTFileGridGlobal = class(specialize wdgTBase<wdgTFileGrid>)
      Internal: uiTWidgetClass; static;
      FileNameLines: loopint; static;

      protected
         procedure OnAdd(wdg: wdgTFileGrid); override;
   end;

   { wdgTHierarchicalFileListGlobal }

   wdgTHierarchicalFileListGlobal = class(specialize wdgTBase<wdgTHierarchicalFileList>)
      Internal: uiTWidgetClass; static;
   end;

VAR
   wdgFileList: wdgTFileListGlobal;
   wdgFileGrid: wdgTFileGridGlobal;
   wdgHierarchicalFileList: wdgTHierarchicalFileListGlobal;

IMPLEMENTATION

{ wdgTFileGrid }

constructor wdgTFileGrid.Create;
begin
   inherited Create;

   EnableGridMode(false);
end;

{ wdgTHierarchicalFileList }

constructor wdgTHierarchicalFileList.Create;
begin
   inherited Create;

   Clickable := true;
   HighlightHovered := true;
   HasGlyphs := true;
   OddColored := true;
   IncludeParentDirectoryLink := true;
   ManageData := true;

   FileAttributes := faAnyFile or faDirectory;
   Pattern := '*';

   CurrentFiles.InitializeValues(CurrentFiles);
   Files.InitializeValues(Files);
end;

destructor wdgTHierarchicalFileList.Destroy;
begin
   inherited Destroy;

   Files.Dispose();
end;

function wdgTHierarchicalFileList.GetValue(index: loopint): StdString;
begin
   Result := PFileDescriptor(Visible.List[index].Item)^.Name
end;

function wdgTHierarchicalFileList.GetGlyph(index: loopint): wdgTListGlyph;
begin
   Result := wdgFileList.GetFileIcon(Files.List[index]);
end;

procedure wdgTHierarchicalFileList.Load;
var
   items: TSimplePointerList;
   rootF: TFileDescriptor;

begin
   items.Initialize(items);

   if(RootFile = '') then begin
      BaseLevel := 0;

      items := GetSubItems(0, nil);

      ExpandTo(items, 0, 0);
   end else begin
      BaseLevel := 1;

      ZeroOut(rootF, SizeOf(rootF));
      rootF.Name := RootFile;
      rootF.Attr := rootF.Attr or faDirectory;

      CurrentFiles.Add(rootF);

      items.Allocate(1);
      items.List[0] := @CurrentFiles.List[0];
      items.n := 1;

      ExpandTo(items, 0, 0);

      items.Dispose();

      items := GetSubItems(0, nil);

      ExpandTo(items, 1, 1);

      BaseLevel := 1;
   end;

   items.Dispose();
   OnLoad();
end;

procedure wdgTHierarchicalFileList.LoadCurrent();
begin
   LoadPath(GetCurrentDir());
end;

procedure wdgTHierarchicalFileList.LoadCurrentEmpty();
begin
   LoadPathEmpty(GetCurrentDir());
end;

procedure wdgTHierarchicalFileList.LoadPath(const newPath: StdString);
begin
   path := newPath;

   Load();
end;

procedure wdgTHierarchicalFileList.LoadPathEmpty(const newPath: StdString);
begin
   LoadPath(newPath);
   Path := '';
end;

procedure wdgTHierarchicalFileList.ExpandPath(const newPath: StdString);
var
   current,
   restOfPath: StdString;
   index,
   currentLevel,
   currentIndex: loopint;

begin
   restOfPath := newPath;

   currentLevel := 0;
   index := -1;

   if(RootFile <> '') then begin
      currentLevel := 1;

      Expand(0);
   end;

   repeat
      current := CopyToDel(restOfPath, DirectorySeparator);

      {search from the previous index and set it as current}
      currentIndex := FindFileReference(current, currentLevel, index);
      if(currentIndex > -1) then begin
         if(Expandable(currentIndex)) then begin
            Expand(currentIndex);
            index := currentIndex;
         end else
            break;
      end else
         break;

      inc(currentLevel);
   until (restOfPath = '');

   {expand last known good index}
   if(index <> -1) then
      Expand(index);
end;

function wdgTHierarchicalFileList.GetPath(index: loopint): StdString;
var
   cur, l: loopint;
   currentPath: StdString = '';

begin
   if(RootFile <> '') and (index = 0) then
      exit('');

   l := Visible.List[index].Level;

   currentPath := Files.List[index].Name;

   cur := index;
   repeat
      if(Visible.List[cur].Level = l - 1) then begin
         l := Visible.List[cur].Level;

         currentPath := Files.List[cur].Name + DirectorySeparator + currentPath;
      end;

      dec(cur);
   until (l = BaseLevel) or (cur <= 0);

   if(currentPath <> '') then
      Result := currentPath + DirectorySeparator
   else
      Result := '';
end;

function wdgTHierarchicalFileList.GetSubItems(index: loopint; ref: pointer): TSimplePointerList;
var
   props: TBitSet;
   p: StdString;
   i: loopint;

begin
   if(ref = nil) or ((RootFile <> '') and (index = 0)) then begin
      if(Path <> '') then
         p := IncludeTrailingPathDelimiter(Path)
      else
         p := '';
   end else
      p := GetPath(index);

   props := 0;

   if(not IncludeParentDirectoryLink) or (p = '') then
      props := props or FILE_FIND_ALL_SKIP_PARENT_DIRECTORY_LINK;

   if(DirectoriesOnly) then
      props := props or FILE_FIND_ALL_ONLY_DIRECTORIES;

   if(ShowHiddenFiles) or (uiFiles.ShowHiddenFiles) then
      props := props or FILE_FIND_ALL_HIDDEN;

   CurrentFiles.Dispose();
   FileUtils.FindAll(p + Pattern, FileAttributes, CurrentFiles, props);

   uiFiles.SortFiles(CurrentFiles);

   if(CurrentFiles.n > 0) then begin
      Result.Initialize(Result, CurrentFiles.n);

      for i := 0 to (CurrentFiles.n - 1) do
         Result.Add(@CurrentFiles.List[i]);
   end else
      Result.InitializeEmpty(Result);
end;

function wdgTHierarchicalFileList.Expandable(index: loopint): boolean;
begin
   if(Files.List[index].IsDirectory()) or ((RootFile <> '') and (index = 0)) then begin
      if(Files.List[index].Attr and faContainsDirectoriesDetermined = 0) then begin
         if(FileUtils.ContainsDirectories(GetPath(index))) then begin
            Files.List[index].Attr.Prop(faContainsDirectories);
         end else
            Files.List[index].Attr.Clear(faContainsDirectories);

         Files.List[index].Attr.Prop(faContainsDirectoriesDetermined);
      end;

      Result := Files.List[index].Attr.IsSet(faContainsDirectories);
   end else
      Result := false;
end;

procedure wdgTHierarchicalFileList.RemoveAll;
begin
   Files.Dispose();

   inherited RemoveAll;
end;

procedure wdgTHierarchicalFileList.Reload();
begin
   RemoveAll();
   Load();
end;

procedure wdgTHierarchicalFileList.OnLoad();
begin

end;

procedure wdgTHierarchicalFileList.ExpandData(const items: TSimplePointerList; index: loopint);
var
   i: loopint;

begin
   Files.InsertRange(index, items.n);

   for i := 0 to (items.n - 1) do begin
      Files.List[index + i] := TFileDescriptor(items.List[i]^);
   end;

   {re-reference all items}
   for i := 0 to (Files.n - 1) do
      Visible.List[i].Item := @Files.List[i];

   CurrentFiles.Dispose();
end;

procedure wdgTHierarchicalFileList.CollapseData(index, count: loopint);
begin
   Files.RemoveRange(index, count);
end;

function wdgTHierarchicalFileList.FindFileReference(const name: StdString;
   fileLevel: loopint; startFrom: loopint): loopint;
var
   i: loopint;

begin
   {correct startFrom}
   if(startFrom < 0) or (startFrom > Files.n) then
      startFrom := 0;

   for i := startFrom to (Files.n - 1) do begin
      if(Visible.List[i].Level >= fileLevel) then begin
         {same name and level, it fits}
         if(Files.List[i].Name = name) and (Visible.List[i].Level = fileLevel) then
            exit(i);
      end else begin
         {if we reach a lower level then we won't be able to find the file at the specified level anyways}
         break;
      end;
   end;

   Result := -1;
end;

{ wdgTFileList }

constructor wdgTFileList.Create();
var
   column: wdgPGridColumn;

begin
   inherited Create;

   Clickable := true;
   HighlightHovered := true;
   ShowFileIcons := true;
   IncludeParentDirectoryLink := true;

   FileAttributes := faAnyFile or faDirectory;
   Pattern := '*';

   Files.InitializeValues(Files);

   if(ShowFileIcons) then begin
      column := AddColumn('');
      column^.Ratio := 0.05;
      column^.HorizontalJustify := uiJUSTIFY_HORIZONTAL_CENTER;
   end;

   column := AddColumn('Name');
   if(ShowFileIcons) then
      column^.Ratio := 0.35
   else
      column^.Ratio := 0.4;
   column^.HorizontalJustify := uiJUSTIFY_HORIZONTAL_LEFT;

   column := AddColumn('Type');
   column^.Ratio := 0.15;
   column^.HorizontalJustify := uiJUSTIFY_HORIZONTAL_CENTER;

   column := AddColumn('Size');
   column^.Ratio := 0.25;
   column^.HorizontalJustify := uiJUSTIFY_HORIZONTAL_LEFT;

   column := AddColumn('Time');
   column^.Ratio := 0.2;
   column^.HorizontalJustify := uiJUSTIFY_HORIZONTAL_LEFT;
end;

destructor wdgTFileList.Destroy();
begin
   inherited Destroy;

   Files.Dispose();
end;

procedure wdgTFileList.RenderStart();
begin
   inherited RenderStart;

   Today := Date;
end;

procedure wdgTFileList.RenderColumn(index, columnIndex: loopint; var r: oxTRect);
var
   f: oxTFont;
   height,
   padding,
   fh: loopint;
   pf: PFileDescriptor;
   br: oxTRect;

   glyph: wdgTListGlyph;

begin
   if(not ScissorRect(r)) then
      exit;

   if(not GridMode) then
      if(not ShowFileIcons) or (columnIndex > 0) then
         inherited RenderColumn(index, columnIndex, r)
      else begin
         padding := 1;
         pf := GetFile(index, columnIndex);
         glyph := wdgFileList.GetFileIcon(pf^);

         if(glyph.Glyph <> nil) and (glyph.Glyph.rId <> 0) then begin
            height := r.h - padding * 2;

            oxRender.BlendDefault();
            SetColorBlended(glyph.Color);
            uiDrawUtilities.Glyph(r.x, r.y, height, height, glyph.Glyph);

            {restore text color}
            SetFontColor(-1);
         end;
      end
   else begin
      f := CachedFont;
      pf := GetFile(index, columnIndex);
      br := r;

      if(pf <> nil) then begin
         glyph := wdgFileList.GetFileIcon(pf^);
         padding := 2;
         fh := f.GetHeight();

         if(glyph.Glyph <> nil) and (glyph.Glyph.rId <> 0) then begin
            height := r.h - (fh * wdgFileGrid.FileNameLines + fh div 2) - padding * 2;

            oxRender.BlendDefault();
            SetColorBlended(glyph.Color);
            uiDrawUtilities.Glyph(r.x, r.y - padding, height, height, glyph.Glyph);

            br.y := br.y - r.h + (fh * wdgFileGrid.FileNameLines) + fh div 2;
         end;
      end;

      SetColorBlendedEnabled(uiTSkin(uiTWindow(wnd).Skin).Colors.Text,
         uiTSkin(uiTWindow(wnd).Skin).DisabledColors.Text);

      f.WriteInRect(GetValue(index, columnIndex), br, [oxfpBreak, oxfpMultiline, oxfpCenterHorizontal]);
   end;
end;

function wdgTFileList.GetValue(index, column: loopint): StdString;
var
   fileIndex: loopint;

begin
   if(GridMode) then begin
      fileIndex := GetItemIndex(index, column);

      if(fileIndex < Files.n) then
         exit(Files.List[fileIndex].Name);

      exit('');
   end;

   if(ShowFileIcons) then begin
      if(column = 0) then
         exit('');

      column := column - 1;
   end;

   if(column = 0) then begin
      {name}
      if(Files.List[index].Name <> '..') then
         Result := Files.List[index].Name
      else
         Result := '..';
   end else if(column = 1) then begin
      {type}
      if(Files.List[index].IsFile()) then begin
         if(Files.List[index].Name <> '..') then
            Result := ExtractFileExtNoDot(Files.List[index].Name)
         else
            Result := '';
      end else
         Result := 'DIR';
   end else if(column = 2) then
      {size}
      Result := getiecByteSizeHumanReadableSI(Files.List[index].Size, 1, ' ')
   else if(column = 3) then begin
      {time}
      Result := GetModifiedTime(Files.List[index].Time);
   end else
      Result := '';
end;

function wdgTFileList.GetFile(index, column: loopint): PFileDescriptor;
var
   fileIndex: loopint;

begin
   if(GridMode) then begin
      fileIndex := GetItemIndex(index, column);

      if(fileIndex < Files.n) then
         exit(@Files.List[fileIndex])
      else
         exit(nil);
   end;

   exit(@Files.List[index]);
end;

function wdgTFileList.GetModifiedTime(givenTime: longint; full: boolean): StdString;
var
   time: TDateTime;

begin
   time := FileDateToDateTime(givenTime);

   if(not full) then begin
      if(not Today.MatchingDay(time)) then
         Result := DateToStr(time)
      else
         Result := TimeToStr(time);
   end else
      Result := DateTimeToStr(time);
end;

function wdgTFileList.GetFilePath(index: loopint): StdString;
var
   path: StdString;

begin
   Result := '';

   if(index > -1) then begin
      path := CurrentPath;

      if(CurrentPath <> '') then
         path := IncludeTrailingPathDelimiter(CurrentPath);

      Result := Path + Files.List[index].Name;
   end;
end;

procedure wdgTFileList.FindAll(const path: StdString);
var
   props: TBitSet;

begin
   CurrentPath := IncludeTrailingPathDelimiterNonEmpty(path);

   props := 0;

   if(not IncludeParentDirectoryLink) or (path = '') then
      props := props or FILE_FIND_ALL_SKIP_PARENT_DIRECTORY_LINK;

   if(DirectoriesOnly) then
      props := props or FILE_FIND_ALL_ONLY_DIRECTORIES;

   if(ShowHiddenFiles) or (uiFiles.ShowHiddenFiles) then
      props := props or FILE_FIND_ALL_HIDDEN;

   Files.Dispose();
   FileUtils.FindAll(CurrentPath + Pattern, FileAttributes, Files, props);
   uiFiles.SortFiles(Files);

   Assigned();
   OnPathChanged();

   if(Callbacks.PathChange <> nil) then
      Callbacks.PathChange();

   SetHint('');
end;

procedure wdgTFileList.LoadCurrent();
begin
   FindAll(GetCurrentDir());
end;

procedure wdgTFileList.LoadCurrentEmpty();
begin
   FindAll('');
   CurrentPath := '';
end;

procedure wdgTFileList.Reload();
begin
   if(CurrentPath <> '') then
      FindAll(CurrentPath)
   else
      LoadCurrentEmpty();
end;

procedure wdgTFileList.OpenDirectory(index: loopint);
begin
   if(Files.List[index].IsDirectory()) then begin
      if(CurrentPath <> '') then
         CurrentPath := IncludeTrailingPathDelimiter(CurrentPath);

      FindAll(CurrentPath + Files.List[index].Name + DirectorySeparator);
   end;
end;

procedure wdgTFileList.SetDirectoriesOnly(enabled: boolean);
begin
   ShowColumn(2, not enabled);
   DirectoriesOnly := enabled;
end;

function wdgTFileList.GetItemCount(): loopint;
begin
   if(not GridMode) then
      Result := Files.n
   else
      Result := GetItemRows(Files.n);
end;

function wdgTFileList.GetGridItemCount(): loopint;
begin
   Result := Files.n
end;

function wdgTFileList.Key(var k: appTKeyEvent): boolean;
begin
   Result := inherited Key(k);

   if(not Result) then begin
      if(k.Key.Equal(kcBACKSPACE) or (k.Key.Equal(kcUP, kmALT))) then begin
         if(k.Key.Released()) then
            GoUp();

         Result := true;
      end;
   end;
end;

procedure wdgTFileList.GoUp();
var
   index: longint;

begin
   CurrentPath := ExcludeTrailingPathDelimiter(CurrentPath);
   index := LastDelimiter(DirectorySeparator, CurrentPath);

   if(index > -1) then
      CurrentPath := Copy(CurrentPath, 1, index);

   FindAll(CurrentPath);
end;

procedure wdgTFileList.RemoveAll();
begin
   Files.Dispose();

   inherited RemoveAll;
end;

procedure wdgTFileList.FileClicked(index: loopint; button: TBitSet);
begin
   if(index > -1) and (button = appmcLEFT) then begin
      if(Files.List[index].IsDirectory()) then begin
         if(Files.List[index].Name <> '..') then begin
            OpenDirectory(index);
         end else
            GoUp();
      end;
   end;
end;

procedure wdgTFileList.FileDoubleClicked(index: loopint; button: TBitSet);
begin
end;

procedure wdgTFileList.GridItemClicked(index: loopint; button: TBitSet);
begin
   FileClicked(index, button);
end;

procedure wdgTFileList.GridItemDoubleClicked(index: loopint; button: TBitSet);
begin
   FileDoubleClicked(index, button);
end;

procedure wdgTFileList.OnPathChanged();
begin
end;

procedure wdgTFileList.OnGridHover(index: loopint);
begin
   if(index > -1) then
      SetHint('Name: ' + Files.List[index].Name + #13 +
         'Size: ' + getiecByteSizeHumanReadable(Files.List[index].Size) + #13 +
         'Modified time: ' + GetModifiedTime(Files.List[index].Time, true))
   else
      SetHint('');
end;

{ wdgTFileListGlobal }
class function wdgTFileListGlobal.GetFileIcon(const f: TFileDescriptor): wdgTListGlyph;
begin
   if(f.IsFile()) then begin
      Result.Glyph := oxFileIcons.Get(ExtractFileExtNoDot(f.Name));
      Result.Color := wdgFileList.FileColor;
   end else begin
      Result.Glyph := oxFileIcons.GetDirectory();
      Result.Color := wdgFileList.DirectoryColor;
   end;

   if(f.IsHidden() or (f.IsDirectory() and ((f.Name = '..') or (f.Name = '.')))) then
      Result.Color := Result.Color.Darken(0.2);
end;

{ wdgTFileGridGlobal }

procedure wdgTFileGridGlobal.OnAdd(wdg: wdgTFileGrid);
begin
   wdg.EnableGridMode();
end;

procedure InitWidget();
begin
   wdgFileList.Internal.Done(wdgTFileList);

   wdgFileList := wdgTFileListGlobal.Create(wdgFileList.Internal);
end;

procedure InitGridWidget();
begin
   wdgFileGrid.Internal.Done(wdgTFileGrid);

   wdgFileGrid := wdgTFileGridGlobal.Create(wdgFileGrid.Internal);
end;

procedure InitHierarchicalWidget();
begin
   wdgHierarchicalFileList.Internal.Done(wdgTHierarchicalFileList);

   wdgHierarchicalFileList := wdgTHierarchicalFileListGlobal.Create(wdgHierarchicalFileList.Internal);
end;

INITIALIZATION
   wdgFileList.Internal.Register('widget.filelist', @InitWidget);
   wdgFileGrid.Internal.Register('widget.filegrid', @InitGridWidget);
   wdgHierarchicalFileList.Internal.Register('widget.hierarchicalfilelist', @InitHierarchicalWidget);

   wdgFileGrid.FileNameLines := 2;

   wdgFileList.DirectoryColor.Assign(255, 206, 0, 255);
   wdgFileList.FileColor.Assign(255, 255, 255, 255);

END.
