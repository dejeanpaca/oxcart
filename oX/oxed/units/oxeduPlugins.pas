{
   oxeduPlugins, plugins
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduPlugins;

INTERFACE

   USES
      uStd, uLog;

TYPE
   oxedPPlugin = ^oxedTPlugin;
   oxedTPlugin = record
      Name,
      Description: string;
   end;

   oxedTPluginsList = specialize TSimpleList<oxedTPlugin>;

   { oxedTPluginsGlobal }

   oxedTPluginsGlobal = record
      List: oxedTPluginsList;

      function Add(const name: string; const description: string = ''): oxedPPlugin;
   end;

VAR
   oxedPlugins: oxedTPluginsGlobal;

IMPLEMENTATION

{ oxedTPluginsGlobal }

function oxedTPluginsGlobal.Add(const name: string; const description: string): oxedPPlugin;
var
   plugin: oxedTPlugin;

begin
   ZeroOut(plugin, SizeOf(plugin));
   plugin.Name := name;
   plugin.Description := description;

   List.Add(plugin);

   Result := List.GetLast();
end;

INITIALIZATION
   oxedTPluginsList.InitializeValues(oxedPlugins.List);

   oxedPlugins.Add('OXED', 'oX Editor');

END.
