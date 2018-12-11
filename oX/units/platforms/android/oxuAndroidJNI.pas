{
   oxuAndroidJNI, oX android jni generic functionality
   Copyright (C) 2013. Dejan Boras

   Started On:    25.11.2013.
}

{$INCLUDE oxdefines.inc}
UNIT oxuAndroidJNI;

INTERFACE

   USES jni, jniutils, uStd, uLog;

CONST
   oxcAndroidJNIClassPath = 'dbx/oX/Native/';

TYPE
   oxTAndroidJNI = record
      className: string;
      moduleName: string;
      ok,
      initialized: boolean;
      pClass: Pjclass;
      env: PJNIEnv;
      jvidConstructor: jmethodID;

      function findMethod(const name, signature: string): jmethodID;
      procedure failedToLoadMethod(const name: string);
      procedure setInitialized();
      procedure getConstructor();
      function NewGlobalRef(): jobject;
      procedure DeleteGlobalRef(var jgobj: jobject);
   end;

procedure oxAndroidJNIInitialize(var helper: oxTAndroidJNI; env: PJNIEnv; const className, moduleName: string);

IMPLEMENTATION

procedure oxAndroidJNIInitialize(var helper: oxTAndroidJNI; env: PJNIEnv; const className, moduleName: string);
var
   fullClassName: string;

begin
   ZeroOut(helper, SizeOf(helper));
   helper.className     := className;
   helper.moduleName    := moduleName;
   helper.env           := env;
   fullClassName        := oxcAndroidJNIClassPath + className;
   helper.pClass        := env^^.FindClass(env, pchar(fullClassName));
   if(helper.pClass <> nil) then
      helper.ok := true
   else
      log.e(helper.moduleName + 'Failed to find nSoundPool class.');
end;

{ oxTAndroidJNI }

function oxTAndroidJNI.findMethod(const name, signature: string): jmethodID;
begin
   result := env^^.GetMethodID(env, pClass, pchar(name), pchar(signature));
   if(result = nil) then begin
      failedToLoadMethod(name);
      ok := false;
   end;
end;

procedure oxTAndroidJNI.failedToLoadMethod(const name: string);
begin
   log.e(moduleName + ' > Failed to find ''' + name + ''' method in ' + className + ' class.');
end;

procedure oxTAndroidJNI.setInitialized();
begin
   initialized := ok;

   if(ok) then
      log.i(moduleName + ' initialized.')
   else
      log.e(moduleName + ' > failed to initialize.');
end;

procedure oxTAndroidJNI.getConstructor();
begin
   jvidConstructor   := findMethod('<init>', '()V');
end;

function oxTAndroidJNI.NewGlobalRef(): jobject;
var
   jgobj: jobject;

begin
   jgobj := env^^.NewObject(env, pClass, jvidConstructor);
   if(jgobj <> nil) then begin
      jgobj := env^^.NewGlobalRef(env, jgobj);
   end;

   result := jgobj;
end;

procedure oxTAndroidJNI.DeleteGlobalRef(var jgobj: jobject);
begin
   if(jgobj <> nil) then begin
      env^^.DeleteGlobalRef(env, jgobj);
      jgobj := nil;
   end;
end;

END.

