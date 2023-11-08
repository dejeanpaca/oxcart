{
   yPak, file packaging
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
PROGRAM yPakTool;

   USES
      uStd, ConsoleUtils, ParamUtils, StringUtils, uSimpleParser,
      yPakU, ypkuPack, ypkuUnpack, ypkuList, ypkuDirSep, uyPakFile, ypkuFS;

CONST
   { modes of operation }
   MODE_UNKNOWN   = $0000; {unknown mode, user did not specify any mode}
   MODE_PACK      = $0001; {pack files to a .ypk}
   MODE_UNPACK    = $0002; {unpack files from a .ypk}
   MODE_LIST      = $0003; {list files and information for a .ypk}
   MODE_DIRSEP    = $0004; {replace directory separator in filenames for a .ypk}

   pakfnDefault = 'data.ypk';

VAR
   mode: longint;

procedure ErrorHalt(const s: string);
begin
   if(s <> '') then
      console.e(s);

   halt(1);
end;

procedure setMode(m: longint);
begin
   if(mode = MODE_UNKNOWN) then
      mode := m
   else
      ErrorHalt('You can specify only one mode (pack, unpack or list).');
end;

procedure setFilterMode(f: longint);
begin
   if(pak.FilterMode = FLTR_MODE_UNKNOWN) then
      pak.FilterMode := f
   else
      ErrorHalt('You can specify only one mode (include or exclude).');
end;

procedure WriteHelp();
begin
   writeln('ypaktool [mode] [-e excl] [-i incl] [-d c] [filename]');
   writeln('modes >');
   writeln('-p   - Pack files to a .ypk file');
   writeln('-u   - Unpack files from a .ypk file');
   writeln('-l   - List .ypk file contents');
   writeln('-rpd - Replace directory separators in a .ypk file with the specified ones');
   writeln('       The -d parameter must be specified.');
   writeln();
   writeln('-d   - Set the directory separator character. Can be \ or / ');
   writeln('Filtering modes (only one can be active) >');
   writeln('-e   - Excluded extensions');
   writeln('-i   - Included extensions');
   halt(0);
end;

procedure ValidateDirectorySeparator();
begin
   if not(ypkDirSep in['\', '/']) then
      ErrorHalt('Directory separator character can be ''\'' or ''/''');
end;

function Params(const pstr: StdString; const lstr: StdString): boolean;
var
   s: StdString;

begin
   result := true;

   if(lstr[1] =  '-') then begin
      {mode}
      if(lstr = '-p') then
         setMode(MODE_PACK)
      else if(lstr = '-u') then
         setMode(MODE_UNPACK)
      else if(lstr = '-l') then
         setMode(MODE_LIST)
      else if(lstr = '-rpd') then
         setMode(MODE_DIRSEP)
      {filter exclude}
      else if(lstr = '-e') then begin
         setFilterMode(FLTR_MODE_EXCLUDE);
         pak.Excluded := parameters.Next();
      {filter include}
      end else if(lstr = '-i') then begin
         setFilterMode(FLTR_MODE_INCLUDE);
         pak.Included := parameters.Next();
      {directory separator}
      end else if(lstr = '-d') then begin
         s := parameters.Next();

         if(s <> '') then begin
            ypkDirSep := s[1];
            ValidateDirectorySeparator();
         end else
            ErrorHalt('No directory separator character specified.');
      {hel}
      end else if(lstr = '-h') or (lstr = '--help') or (lstr = '-?') then WriteHelp();
   end else begin
      if(pak.fn = '') then
         pak.fn := pstr
      else
         ErrorHalt('You cannot specify more than one ypk file.');
   end;
end;

procedure DoParams();
var
   err: boolean = false;

begin
   parameters.Process(@Params);

   { check for additional errors in parameters }
   if(pak.fn = '') then begin
      console.w('No ypk file specified, will use defualt: ' + pakfnDefault);
      pak.fn := pakfnDefault;
   end;

   if(mode = MODE_UNKNOWN) then begin
      console.e('No mode specified');
      err := true;
   end;

   if(pak.FilterMode = FLTR_MODE_UNKNOWN) then
      pak.FilterMode := FLTR_MODE_EXCLUDE;

   if(err) then
      ErrorHalt('');
end;

procedure loadKV();
var
   i: longint;
   key, value: string;
   kv: TStringPairs;

begin
   kv.Initialize(kv);
   SimpleParser.LoadKeyValues('ypakfile', kv, ' ');

   if(kv.n > 0) then begin
      for i := 0 to kv.n - 1 do begin
         key := kv.List[i][0];
         value := kv.List[i][1];

         if(key = 'fn') then
            pak.fn := value
         else if (key = 'i') then
            pak.Included := value
         else if (key = 'e') then
            pak.Excluded := value
         else if (key = 'd') then begin
            ypkDirSep := value[1];
            ValidateDirectorySeparator();
         end;
      end;
   end;
end;

BEGIN
   loadKV();

   if(ParamCount() > 0) then
      DoParams()
   else
      ErrorHalt('No parameters provided.');

   {if there is an 'ypakfile' file in the current folder, then set mode to packing if none is set}
   if(mode = MODE_UNKNOWN) then
      mode := MODE_PACK;

   ReplaceDirSeparators(pak.fn);

   case mode of
      MODE_PACK:
         Pack();
      MODE_UNPACK:
         Unpack();
      MODE_LIST:
         List();
      MODE_DIRSEP:
         ReplaceDirSep();
   end;
END.
