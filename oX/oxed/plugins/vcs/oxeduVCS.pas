{
   oxeduVCS, some basic support for version control systems
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduVCS;

INTERFACE

   USES
      {oxed}
      oxeduPlugins;

TYPE

   { oxedTVCS }

   oxedTVCS = class
      UsedVCS: oxedTVCS; static;

      {called when this vcs integration is used}
      procedure Start(); virtual;
      {called when we stop using this vcs integration}
      procedure Stop(); virtual;

      class procedure SetVCS(vcs: oxedTVCS); static;
   end;

VAR
   oxedVCS: oxedTVCS;

IMPLEMENTATION

{ oxedTVCS }

procedure oxedTVCS.Start();
begin

end;

procedure oxedTVCS.Stop();
begin

end;

class procedure oxedTVCS.SetVCS(vcs: oxedTVCS);
begin
   UsedVCS := vcs;
end;

INITIALIZATION
   oxedPlugins.Add('VCS', 'Version Control System(s)');

END.
