{
   uFileHandlers
   Provides mechanisms for registering and calling multiple file handlers.

   Copyright (C) 2007. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uFileHandlers;

INTERFACE

   USES uStd, uLog, SysUtils, StringUtils;

CONST
   {error codes}
   fheGENERAL                    = $0100;
   fheFILE_EXIST_INVALID         = $0101;
   fheHANDLER_NOT_FOUND          = $0102;

TYPE
   {a procedure which is called to handle files}
   fhTHandleProc = procedure(data: pointer);

   {a handler, which is responsible for handling files}
   fhPHandler = ^fhTHandler;
   fhTHandler = record
      Name: string;
      Handle: fhTHandleProc;

      {indicates that the file should not be automatically opened/created for reading/writing,
      as the handler will do this}
      DoNotOpenFile: boolean;
      Next: fhPHandler;

      {load a file}
      procedure CallHandler(data: pointer);
   end;

   {an extension, associated with a handler}
   fhPExtension = ^fhTExtension;
   fhTExtension = record
      Ext: string;
      Handler: fhPHandler;

      next: fhPExtension;
   end;

   {magic number}
   fhTMagicNo = record
      Size: longint;
      mNo: array[0..15] of char;
   end;

   fhPFindData = ^fhTFindData;
   fhTFindData = record
      Handler: fhPHandler;
      Ext: fhPExtension;
   end;

   {handler information}
   fhPHandlerInfo = ^fhTHandlerInfo;

   { fhTHandlerInfo }

   fhTHandlerInfo = record
      nExtensions,
      nHandlers: longint;

      hStart,
      hEnd: fhPHandler;

      eStart,
      eEnd: fhPExtension;

      DefaultHandler: fhPHandler;
      PrevHandlerExt: fhPExtension;

      {finds a valid handler for a file}
      procedure FindHandler(const filename: string; out fd: fhTFindData);
      {extension and handler registration}
      procedure RegisterExt(var ext: fhTExtension);
      procedure RegisterExt(out ext: fhTExtension; const extString: string; handler: fhPHandler);
      procedure RegisterHandler(var ldr: fhTHandler);
      procedure RegisterHandler(out ldr: fhTHandler; const name: string; handleProc: fhTHandleProc);
      {logging}
      procedure LogExtensions();
   end;

{initialize a handler info record}
procedure fhInit(out hinfo: fhTHandlerInfo); inline;

IMPLEMENTATION

{handler initialize}
procedure fhInit(out hinfo: fhTHandlerInfo); inline;
begin
   ZeroOut(hinfo, sizeof(fhTHandlerInfo));
end;

{register extension}
procedure fhTHandlerInfo.RegisterExt(var ext: fhTExtension);
begin
   inc(nExtensions);
   ext.Next := nil;

   if(eStart = nil) then
      eStart := @ext
   else
      eEnd^.Next := @ext;
   eEnd := @ext;
end;

procedure fhTHandlerInfo.RegisterExt(out ext: fhTExtension; const extString: string; handler: fhPHandler);
begin
   ZeroOut(ext, SizeOf(ext));

   ext.Ext := extString;
   ext.Handler := handler;

   RegisterExt(ext);
end;

{register an handler}
procedure fhTHandlerInfo.RegisterHandler(var ldr: fhTHandler);
begin
   inc(nHandlers);
   ldr.Next := nil;

   if(hStart = nil) then
      hStart := @ldr
   else
      hEnd^.Next := @ldr;

   hEnd := @ldr;

   if(DefaultHandler = nil) then
      DefaultHandler := @ldr;
end;

procedure fhTHandlerInfo.RegisterHandler(out ldr: fhTHandler; const name: string; handleProc: fhTHandleProc);
begin
   ZeroPtr(@ldr, SizeOf(ldr));

   ldr.Name := name;
   ldr.Handle := handleProc;

   RegisterHandler(ldr);
end;

procedure fhTHandler.CallHandler(data: pointer);
begin
   if(Handle <> nil) then
      Handle(data);
end;

{DISPOSE}

{finds a valid handler for a file}
procedure fhTHandlerInfo.FindHandler(const filename: string; out fd: fhTFindData);
var
   fName,
   ext: string; {extension of the file}

procedure DetermineHandler();
var
   cur: fhPExtension;

begin
   cur := eStart;

   repeat
      if(cur^.ext = ext) then begin
         fd.ext := cur;
         exit;
      end;

      cur := cur^.Next;
   until (cur = nil);
end;

begin
   fd.Ext      := nil;
   fd.Handler  := nil;

   {if there are no extensions registered then we can't load anything :(}
   if(nExtensions > 0) then begin
      fName := filename;

      {determine extension}
      ext := LowerCase(StringUtils.ExtractFileExt(fName));

      if(ext <> '') then begin {if there is an extension}
         if(PrevHandlerExt <> nil) then begin
            if(PrevHandlerExt^.ext = ext) then
               fd.Ext := PrevHandlerExt
            else
               DetermineHandler();
         end else
            DetermineHandler();

         if(fd.Ext <> nil) then begin
            {call the default handler}
            PrevHandlerExt := fd.Ext;
            fd.Handler := fd.Ext^.Handler;
         end;
      end else begin {if no extension then call the default handler}
         if(DefaultHandler <> nil) then
            fd.Handler := DefaultHandler;
      end;
   end;
end;

procedure fhTHandlerInfo.LogExtensions();
var
   cur: fhPExtension;

begin
   cur := eStart;

   if(cur <> nil) then repeat
      log.i(cur^.Ext + '(' + cur^.Handler^.Name + ')');

      cur := cur^.Next;
   until (cur = nil);
end;

END.
