{
   oxuAndroidPlatform, android platform
   Copyright (c) 2011. Dejan Boras

   Started On:    11.02.2011.
}

{$INCLUDE oxdefines.inc}
UNIT oxuAndroidPlatform;

INTERFACE

   USES
      uStd,
      {app}
      appuMouse,
      {oX}
      oxuTypes, oxuPlatform, oxuPlatforms, oxuWindowTypes;

TYPE
   { oxTAndroidPlatform }

   oxTAndroidPlatform = class(oxTPlatform)
      constructor Create(); override;
      function Initialize(): boolean; override;

      function MakeWindow({%H-}wnd: oxTWindow): boolean; override;
   end;

   { TAndroidPointerDriver }

   TAndroidPointerDriver = class(appTPointerDriver)
      LastX,
      LastY: loopint;

      constructor Create();

      procedure getXY({%H-}devID: longint; wnd: pointer; out x, y: single); override;
      procedure setXY({%H-}devID: longint; wnd: pointer; x, y: single); override;
      procedure hide(devID: longint; {%H-}wnd: pointer); override;
      procedure show(devID: longint; {%H-}wnd: pointer); override;
   end;


IMPLEMENTATION

{ TAndroidPointerDriver }

constructor TAndroidPointerDriver.Create();
begin
   Name := 'android';
end;

procedure TAndroidPointerDriver.getXY(devID: longint; wnd: pointer; out x, y: single);
begin
   inherited getXY(devID, wnd, x, y);
end;

procedure TAndroidPointerDriver.setXY(devID: longint; wnd: pointer; x, y: single);
begin
   inherited setXY(devID, wnd, x, y);
end;

procedure TAndroidPointerDriver.hide(devID: longint; wnd: pointer);
begin
   inherited hide(devID, wnd);
end;

procedure TAndroidPointerDriver.show(devID: longint; wnd: pointer);
begin
   inherited show(devID, wnd);
end;

{ oxTAndroidPlatform }

constructor oxTAndroidPlatform.Create();
begin
   Name := 'android';
end;

function oxTAndroidPlatform.Initialize(): boolean;
begin
   { pointer driver }
   PointerDriver := TAndroidPointerDriver.Create();

   Result := true;
end;

function oxTAndroidPlatform.MakeWindow(wnd: oxTWindow): boolean;
begin
   Result := true;
end;

INITIALIZATION
   oxPlatforms.Register(oxTAndroidPlatform);

END.
