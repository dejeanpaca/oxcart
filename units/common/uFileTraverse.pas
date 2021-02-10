{
   uFileTraverse, path traversal utilities
   Copyright (C) 2021. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uFileTraverse;

INTERFACE

   USES
      sysutils,
      uStd, StringUtils, uFileUtils;

TYPE
   {list of file descriptors}
   PFileDescriptorList = ^TFileDescriptorList;
   TFileDescriptorList = specialize TSimpleList<TFileDescriptor>;

   PFileTraverse = ^TFileTraverse;

   PFileTraverseData = ^TFileTraverseData;
   TFileTraverseData = record
      Traverse: PFileTraverse;
      ExternalData: Pointer;
      f: TFileDescriptor;
   end;

   { TFileTraverse }

   TFileTraverse = record
   public
      {extensions which are only to be included in processing (allowlist)}
      Extensions: array of StdString;
      {extensions which are to be excluded from being processed (blocklist)}
      ExtensionBlocklist: array of StdString;

      Running: boolean;
      Recursive: boolean;

      {called when a file is found with matching extension (if any), if returns false traversal is stopped}
      OnFile: function(const f: TFileTraverseData): boolean;
      OnDirectory: function(const f: TFileTraverseData): boolean;

      ExternalData: pointer;

      procedure Initialize();
      class procedure Initialize(out traverse: TFileTraverse); static;

      {processes a tree with a starting path}
      procedure Run(const startPath: StdString);
      {processes current path}
      procedure Run();

      {add an extension to the extension allowlist}
      procedure AddExtension(const ext: StdString);
      {add an extension to the extension blocklist}
      procedure ExcludeExtension(const ext: StdString);

      {reset extensions}
      procedure ResetExtensions();

      {stop traversing}
      procedure Stop();

   private
      path: StdString;
      {causes process to stop traversing files/directories if set to true}
      stopTraverse: boolean;
      {processes an individual directory (called recursively)}
      procedure RunDirectory(const name: StdString);
   end;

IMPLEMENTATION

{ TFileTraverse }

procedure TFileTraverse.Initialize();
begin
   Recursive := true;
end;

class procedure TFileTraverse.Initialize(out traverse: TFileTraverse);
begin
   ZeroPtr(@traverse, SizeOf(traverse));
   traverse.Initialize();
end;

procedure TFileTraverse.Run(const startPath: StdString);
begin
   path           := ExcludeTrailingPathDelimiter(startPath);
   stopTraverse   := false;
   Running        := true;

   RunDirectory('');
   Running := false;
end;

procedure TFileTraverse.Run();
begin
   Run('');
end;

procedure TFileTraverse.AddExtension(const ext: StdString);
begin
   SetLength(Extensions, Length(Extensions) + 1);
   Extensions[Length(Extensions) - 1] := ext;
end;

procedure TFileTraverse.ExcludeExtension(const ext: StdString);
begin
   SetLength(ExtensionBlocklist, Length(ExtensionBlocklist) + 1);
   ExtensionBlocklist[Length(ExtensionBlocklist) - 1] := ext;
end;

procedure TFileTraverse.ResetExtensions();
begin
   SetLength(ExtensionBlocklist, 0);
   SetLength(Extensions, 0);
end;

procedure TFileTraverse.Stop();
begin
   stopTraverse := true;
end;

procedure TFileTraverse.RunDirectory(const name: StdString);
var
   src: TUnicodeSearchRec;
   i,
   result: longint;
   ext,
   fname: StdString;
   ok: boolean;
   fd: TFileTraverseData;

begin
   {build path}
   if(name <> '') then
      path := IncludeTrailingPathDelimiterNonEmpty(path) + ExcludeTrailingPathDelimiter(name);

   {find first}
   if(path = '') then
      result := FindFirst('*', faReadOnly or faDirectory, src)
   else
      result := FindFirst(UTF8Decode(path + DirectorySeparator + '*'), faReadOnly or faDirectory, src);

   fd.Traverse := @Self;
   fd.ExternalData := ExternalData;

   if(result = 0) then begin
      repeat
         {avoid special directories}
         if(src.Name <> '.') and (src.Name <> '..') then begin
            {found directory, recurse into it}
            if(src.Attr and faDirectory > 0) then begin
               if(Recursive) then begin
                  if(OnDirectory = nil) then
                     RunDirectory(UTF8Encode(src.Name))
                  else begin
                     TFileDescriptor.From(fd.f, src);
                     fd.f.Name := path + DirectorySeparator + UTF8Encode(src.Name);

                     if(OnDirectory(fd)) then
                        RunDirectory(UTF8Encode(src.Name));
                  end;
               end;
            end else begin
               ok    := true;
               ext   := UTF8Lower(ExtractFileExt(utf8string(UTF8Encode(src.Name))));

               {check if extension matches any on the blocklist (if there is a blocklist)}
               if(ExtensionBlocklist <> nil) then begin
                  for i := 0 to Length(ExtensionBlocklist) - 1 do begin
                     if(ext = ExtensionBlocklist[i]) then
                        ok := false;
                  end;
               end;

               {check if file matches extension (if any specified)}
               if(Extensions <> nil) and (ok) then begin
                  ok := false;

                  for i := 0 to Length(Extensions) - 1 do
                     if(ext = Extensions[i]) then
                        ok := true;
               end;

               if(ok) then begin
                  {build filename}
                  if(path <> '') then
                     fname := path + DirectorySeparator + UTF8Encode(src.Name)
                  else
                     fname := UTF8Encode(src.Name);

                  {call OnFile to perform operations on the file}
                  if(OnFile <> nil) then begin
                     TFileDescriptor.From(fd.f, src);
                     fd.f.Name := fname;

                     if(not OnFile(fd)) then
                        stopTraverse := true;
                  end;
               end;
            end;
         end;

         if(stopTraverse) then
            break;

         {next file/directory}
         result := FindNext(src);
      until (result <> 0);
   end;

   path := ExcludeTrailingPathDelimiter(ExtractFilePath(path));

   {we're done}
   FindClose(src);
end;

END.
