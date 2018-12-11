{
   oxuclParameters, common command line parameters
   Copyright (c) 2017. Dejan Boras

   Started On:    02.04.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuclParameters;

INTERFACE

   USES
      ParamUtils,
      oxuWindowTypes;

IMPLEMENTATION

procedure loadParameters();
begin
   if(parameters.FindFlag('ox.render_software')) then
      oxrDefaultWindowSettings.Software := true;
end;

INITIALIZATION
   loadParameters();

END.
