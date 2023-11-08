{
   Started On:    26.03.2011.
}

{$INCLUDE oxdefines.inc}
PROGRAM ui;

   USES
      {$INCLUDE oxappuses.inc}, uStd, StringUtils, uLog, uTypeHelper,
      {oX}
      oxuWindowTypes,
      oxuWindows, oxuWindow, oxumPrimitive, oxuTransform, oxuPaths, oxuTexture, oxuTextureGenerate,
      oxuRender, oxuScreenshot, oxuWindowSettings,
      {UI}
      uiuControl,
      uiuSurface, uiuWindowTypes, uiuWindow, uiWidgets, uiuDraw,
      wdguButton, wdguLabel, wdguTitleButtons, wdguCheckbox, wdguScrollbar, wdguRadioButton, wdguProgressBar,
      wdguList, wdguTabs, wdguInputBox, wdguGrid, wdguTextEdit,
      oxuwndAbout, oxuwndToast, oxuwndQuickMenu, oxuwndSplash, oxuwndSettings, oxuwndColorPicker,
      oxuInit;

TYPE

   { wdgTTestGrid }

   wdgTTestGrid = class(wdgTStringGrid)
      constructor Create; override;

      function GetItemCount(): loopint; override;
      function GetValue(index, column: loopint): string; override;
   end;

VAR
   srfMain: uiTWindow;
   q: oxTPrimitiveModel;

   tabs: wdgTTabs;
   itemsList: TAnsiStringArray;

procedure loadQuad();
begin
   q.InitQuad();
   q.Scale(50.0, 50.0, 1.0);
   q.SetTexRender(true);
   oxTextureGenerate.Generate(oxPaths.textures + 'main.tga', q.texture);
end;

procedure createSurface();
begin
   srfMain := uiSurface.Create('Main Surface');
   srfMain.QuitOnEscape();

   uiWidget.SetTarget(srfMain);

   {set background for menu}
   //srfMain.SetBackground(oxPaths.textures + 'main.tga');
end;

procedure createStandardWidgets();
begin
   { SURFACE }

   {set buttons}
   wdgLabel.Add('Hello world...', oxPoint(5, 560), oxNullDimensions);

   wdgRadioButton.Add('First option', oxPoint(10, 540)).SetGroup(1);
   wdgRadioButton.Add('Second option', oxPoint(10, 510)).SetGroup(1).Mark();

   wdgProgressBar.Add(oxPoint(5, 480), oxDimensions(790, 40)).SetMaximum(100).SetCurrent(50).Undefined();

   wdgInputBox.Add('this is a input box', oxPoint(5, 595), oxDimensions(790, 16));

   tabs := wdgTabs.Add(oxPoint(5, 300), oxDimensions(790, 200));
   tabs.AddTab('Video');
   tabs.AddTab('Audio');
   tabs.AddTab('Other');
   tabs.Done();

   wdgScrollbar.Add(5, 1).Light().Right();
end;

procedure stringListTest();
var
   i: loopint;

begin
   { STRING LIST }
   SetLength(itemsList, 50);

   for i := 0 to 49 do
      itemsList[i] := sf(i + 1) + '. Item';

   itemsList[4] := 'Really long ass item on this list ........';

   wdgStringList.Add(oxPoint(5, 430), oxDimensions(200, 120)).Assign(itemsList).Selectable := true;
end;

procedure gridTest();
var
   grid: wdgTTestGrid;

begin
   uiWidget.Create.Instance := wdgTTestGrid;

   grid := wdgTTestGrid(wdgStringGrid.Add(oxPoint(210, 430), oxDimensions(200, 120)));
   grid.AddColumn('Name');
   grid.AddColumn('Type');
   grid.AddColumn('Size');

   grid.Assigned();
end;

procedure textEditTest();
var
   wdg: wdgTTextEdit;

begin
   wdg := wdgTextEdit.Add(oxPoint(415, 430), oxDimensions(380, 120));
   if(wdg.Load('ui.pp')) then
      log.v('Loaded text edit file')
   else
      log.w('Failed to load text edit file');
end;

procedure showToast();
begin
   oxToast.Show('Hello', 'UI Test shown', oxcTOAST_DURATION_INDEFINITE);
end;

procedure buttonGrid();
var
   i, j: loopint;
   wdg: wdgTButton;
   pos: uiTControlGridPosition;

begin
   for i := 0 to 3 do
      for j := 0 to 3 do begin
         wdg := wdgButton.Add(sf(i * 4 + j), oxPoint(j * 60 + 3, (i + 1) * 20 + 3), oxDimensions(60, 20), 0);
         pos := [];

         if(i = 0) then
            pos := pos + [uiCONTROL_GRID_BOTTOM]
         else if(i = 3) then
            pos := pos + [uiCONTROL_GRID_TOP]
         else
            pos := pos + [uiCONTROL_GRID_MIDDLE];

         if(j = 0) then
            pos := pos + [uiCONTROL_GRID_LEFT]
         else if(j = 3) then
            pos := pos + [uiCONTROL_GRID_RIGHT]
         else
            pos := pos + [uiCONTROL_GRID_MIDDLE];


         wdg.SetButtonPosition(pos);
      end;
end;

procedure onInitialize();
begin
   loadQuad();
   createSurface();
   createStandardWidgets();
   gridTest();
   stringListTest();
   textEditTest();
   buttonGrid();
{
   oxwndAbout.Open();
   oxwndQuickMenu.Open();
   oxwndSplash.Open();
   oxwndSettings.Open();
   oxwndColorPicker.Open();

   showToast();}
end;

procedure onDeinitialize();
begin
   q.Dispose();
end;

procedure RenderWnd({%H-}wnd: oxTWindow);
begin
   oxTransform.Identity();
   oxTransform.Apply();
end;

procedure InitWindow();
begin
   oxWindowSettings.AllocateCount := 1;
   oxWindowSettings.w[0].Dimensions.Assign(800, 600);
end;

constructor wdgTTestGrid.Create;
begin
   inherited Create;

   Selectable := true;
end;

function wdgTTestGrid.GetItemCount(): loopint;
begin
   Result := 25;
end;

function wdgTTestGrid.GetValue(index, column: loopint): string;
begin
   Result:= sf(index) + 'x' + sf(column);
end;

procedure init();
begin
   oxWindows.onRender.Add(@RenderWnd);

   ox.OnInitialize.Add(@onInitialize);
   ox.OnDeinitialize.Add(@onDeinitialize);
end;

BEGIN
   appInfo.SetName('UI Test');
   appInfo.SetVersion(1, 0, 0);

   oxwndSplash.Link := 'https://www.google.hr';

   ox.AppProcs.iAdd('init', @init);
   InitWindow();

   oxRun.Go();
END.
