{
   oxuglExtensions, basic OpenGL extension management
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuglExtensions;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      uStd, uLog, StringUtils
      {$IFNDEF OX_LIBRARY}
      , ustrList
      {$ENDIF};

TYPE
   oglPExtensionDescriptor = ^oglTExtensionDescriptor;
   oglTExtensionDescriptor = record
      Name: string;
      Present: boolean;
   end;

   oglTExtensionList = array of oglTExtensionDescriptor;

CONST
  {$IFNDEF GLES}
     {$INCLUDE oxglextdscr.inc}
  {$ELSE}
     {$INCLUDE gles/oxglextdscr.inc}
  {$ENDIF}

TYPE
   oglPExtensions = ^oglTExtensions;
   { oglTExtensions }

   oglTExtensions = record
      GetPlatformSpecific: TProcedure;
      PlatformSpecific: oglPExtensionDescriptor;
      nPlatformSpecific: loopint;

      pExtensions: oglPExtensionDescriptor;

      {$IFDEF OX_LIBRARY_SUPPORT}
      pExternal: oglPExtensions;
      {$ENDIF}

      procedure Get();
      function PlatformSupported(i: loopint): boolean;
      function Supported(i: loopint): boolean;
      function FindDescriptor(const ext: string): loopint;
      function FindDescriptor(const extList: oglTExtensionList; const ext: string): loopint;

      function GetList(): TAnsiStringArray;

      procedure DeInitialize();
   end;

VAR
   oglExtensions: oglTExtensions;

IMPLEMENTATION

procedure GetExts({%H-}i: longint; const ext: string);
var
   id: loopint;

begin
   id := oglExtensions.FindDescriptor(ext);

   if(id > -1) then
      oglcExtensionDescriptors[id].Present := true;
end;

procedure oglTExtensions.Get();
{$IFNDEF OX_LIBRARY}
var
   exts: pChar;
{$ENDIF}

begin
   pExtensions := @oglcExtensionDescriptors;

   {$IFNDEF OX_LIBRARY}
   exts := pChar(glGetString(GL_EXTENSIONS));

   strList.ProcessSpaceSeparated(exts, @GetExts);

   if(GetPlatformSpecific <> nil) then begin
      GetPlatformSpecific();
   end;
   {$ELSE}
   pExtensions := pExternal^.pExtensions;
   platformSpecific := pExternal^.PlatformSpecific;
   nPlatformSpecific := pExternal^.nPlatformSpecific;
   {$ENDIF}
end;

function oglTExtensions.PlatformSupported(i: loopint): boolean;
begin
   if(i >= 0) and (i < nPlatformSpecific) then begin
      Result := PlatformSpecific[i].Present;
   end else
      Result := false;
end;

function oglTExtensions.Supported(i: loopint): boolean;
begin
  if(i >= 0) and (i < oglnExtensionDescriptors) then begin
     Result := pExtensions[i].Present;
  end else
     Result := false;
end;

function oglTExtensions.FindDescriptor(const ext: string): loopint;
begin
   Result := FindDescriptor(oglcExtensionDescriptors, ext);
end;

function oglTExtensions.FindDescriptor(const extList: oglTExtensionList; const ext: string): loopint;
var
   i: loopint;

begin
   for i := 0 to high(extList) do
      if(extList[i].Name = ext) then
         exit(i);

   Result := -1;
end;

function oglTExtensions.GetList(): TAnsiStringArray;
var
   list: TAnsiStringArray = nil;
   i,
   count: loopint;

begin
   count := 0;

   for i := 0 to oglnExtensionDescriptors - 1 do begin
      if(pExtensions[i].Present) then
         inc(count);
   end;

   for i := 0 to oglExtensions.nPlatformSpecific - 1 do begin
      if(PlatformSpecific[i].Present) then
         inc(count);
   end;

   SetLength(list, count);
   count := 0;

   for i := 0 to oglnExtensionDescriptors - 1 do begin
      if(pExtensions[i].Present) then begin
         list[count] := pExtensions[i].Name;
         inc(count);
      end;
   end;

   for i := 0 to nPlatformSpecific - 1 do begin
      if(PlatformSpecific[i].Present) then begin
         list[count] := PlatformSpecific[i].Name;
         inc(count);
      end;
   end;

   Result := list;
end;

procedure oglTExtensions.DeInitialize();
var
   i: loopint;

begin
  for i := 0 to high(oglcExtensionDescriptors) do begin
     oglcExtensionDescriptors[i].Present := false;
  end;

  for i := 0 to (oglExtensions.nPlatformSpecific - 1) do begin
     oglExtensions.PlatformSpecific[i].Present := false;
  end;
end;

END.
