{
   wdguFilePathCrumbs, file path crumbs widget
   Copyright (C) 2017. Dejan Boras

   Shows file path crumbs so you can navigate
}

{$INCLUDE oxheader.inc}
UNIT wdguFilePathCrumbs;

INTERFACE

   USES
      sysutils, uStd, uBinarySize, uFileUtils, uTiming, uColors,
      {app}
      appuKeys, appuMouse,
      {oX}
      oxuTypes, oxuFont, oxuFileIcons, oxuRender,
      {ui}
      uiuTypes, uiuFiles,
      uiuWidget, uiWidgets, uiuRegisteredWidgets,
      wdguBase, wdguGrid, wdguList, wdguHierarchyList;

TYPE
   { wdgTFileList }

   wdgTFilePathCrumbs = class(uiTWidget)

   end;

   { wdgTFileListGlobal }

   wdgTFilePathCrumbsGlobal = object(specialize wdgTBase<wdgTFilePathCrumbs>)

   end;

VAR
   wdgFilePathCrumbs: wdgTFilePathCrumbsGlobal;

IMPLEMENTATION


INITIALIZATION
   wdgFilePathCrumbs.Create('file_path_crumbs');

END.
