{
   oxuGlobalHotkeys, command console front-end
   Copyright (c) 2020. Dejan Boras
}

UNIT oxuGlobalHotkeys;

INTERFACE

   USES
      appuKeys,
      {ox}
      oxuWindowTypes, oxuGlobalKeys;

IMPLEMENTATION

procedure fullscreenHandler({%H-}wnd: oxTWindow);
begin

end;

CONST
   gkFullscreenHandler: oxTGlobalKeyHandler = (
      Key: (
         Code: kcTILDE;
         State: 0;
      );
      Pressed: nil;
      Released: @fullscreenHandler;
      Name: 'oxConsole'
   );

INITIALIZATION
   oxGlobalKeys.Hook(gkFullscreenHandler);


END.
