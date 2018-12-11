{
   oxuAndroid, android interface for oX
   Copyright (c) 2012. Dejan Boras

   Started On:    02.03.2012.
}

{$INCLUDE oxdefines.inc}
UNIT oxuAndroidFS;

INTERFACE

   USES
      jni, jniutils, baseunix,
      {std}
      uLog, ulogAndroid, androidlog, StringUtils,
      {file}
      ypkuFS;

{initialize the filesystem}
procedure androidAddFS(env: PJNIENV; id: jint; fd_sys: jobject; offs, len: jlong);
{a touch event}
procedure jniAndroidAddFS(env: PJNIENV; obj: jobject; id: jint; fd_sys: jobject; offs, len: jlong); cdecl;

IMPLEMENTATION

procedure androidAddFS(env: PJNIENV; id: jint; fd_sys: jobject; offs, len: jlong);
var
   fdclass: JClass = nil;
   fdClassDescrFldID: JFieldID = nil;
   fd: jint;
   myfd: longint;
   fs: ypkPFSFile;

begin
   fdclass := env^^.FindClass(env, 'java/io/FileDescriptor');

   if(fdclass <> nil) then begin
      fdClassDescrFldId := env^^.GetFieldID(env, fdClass, 'descriptor', 'I');

      if(fdClassDescrFldID <> nil) and (fd_sys <> nil) then begin
         fd := env^^.GetIntField(env, fd_sys, fdClassDescrFldId);
         myfd := fpdup(fd);

         log.i('Got filesystem file descriptor: '+sf(myfd));

         if(fpLSeek(myfd, offs, Seek_Set) = -1) then
            log.e('Could not seek to start of filesystem(id: ' + sf(id)+', handle: ' + sf(myfd) + ').');

         fs := ypkfs.Add(id, myfd, offs, len);
      end;
   end else
      log.e('Cannot get java.io.FileDescriptor class.');

   if(fs = nil) then
      log.e('Failed to initialize filesystem(' + sf(id) + ').');
end;

procedure jniAndroidAddFS(env: PJNIENV; obj: jobject; id: jint; fd_sys: jobject; offs, len: jlong); cdecl;
begin
   androidAddFS(env, id, fd_sys, offs, len);
end;

END.

