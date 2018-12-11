{
   oxuUIHooks, UI hooks
   Copyright (c) 2014. Dejan Boras

   Started On:    18.01.2014.
}

{$INCLUDE oxdefines.inc}
UNIT oxuUIHooks;

INTERFACE

   USES
      {oX}
      oxuTypes, oxuWindowTypes;

TYPE

   { oxTUIHooks }

   oxTUIHooks = class
      public
         Name: string;

      constructor Create();

      procedure InitializeWindow({%H-}wnd: oxTWindow); virtual;
      procedure DestroyWindow({%H-}wnd: oxTWindow); virtual;

      procedure SetupContextWindow({%H-}wnd: oxTWindow); virtual;

      procedure SetDimensions({%H-}wnd: oxTWindow; {%H-}const {%H-}dimensions: oxTDimensions); virtual;
      procedure SetPosition({%H-}wnd: oxTWindow; {%H-}const {%H-}position: oxTPoint); virtual;
      procedure UpdatePosition({%H-}wnd: oxTWindow); virtual;

      procedure Select({%H-}wnd: oxTWindow); virtual;
      procedure Render({%H-}wnd: oxTWindow); virtual;

      procedure Minimize({%H-}wnd: oxTWindow); virtual;
      procedure Maximize({%H-}wnd: oxTWindow); virtual;
      procedure Restore({%H-}wnd: oxTWindow); virtual;
   end;

   oxTUIHooksInstance = class of oxTUIHooks;

VAR
   oxUIHooks: oxTUIHooks;
   oxUIHooksInstance: oxTUIHooksInstance;


IMPLEMENTATION

{ oxTUIHooks }

constructor oxTUIHooks.Create();
begin
   Name := 'Default';
end;

procedure oxTUIHooks.InitializeWindow(wnd: oxTWindow);
begin
end;

procedure oxTUIHooks.DestroyWindow(wnd: oxTWindow);
begin
end;

procedure oxTUIHooks.SetupContextWindow(wnd: oxTWindow);
begin
end;

procedure oxTUIHooks.SetDimensions(wnd: oxTWindow; const dimensions: oxTDimensions);
begin
end;

procedure oxTUIHooks.SetPosition(wnd: oxTWindow; const position: oxTPoint);
begin
end;

procedure oxTUIHooks.UpdatePosition(wnd: oxTWindow);
begin

end;

procedure oxTUIHooks.Select(wnd: oxTWindow);
begin
end;

procedure oxTUIHooks.Render(wnd: oxTWindow);
begin
end;

procedure oxTUIHooks.Minimize(wnd: oxTWindow);
begin
end;

procedure oxTUIHooks.Maximize(wnd: oxTWindow);
begin

end;

procedure oxTUIHooks.Restore(wnd: oxTWindow);
begin

end;

INITIALIZATION
   oxUIHooksInstance := oxTUIHooks;
END.

