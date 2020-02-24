{
   jniutils, utilities for dealing with java native interface
   Copyright (c) 2012. Dejan Boras
}

{$MODE OBJFPC}{$H+}
UNIT jniutils;

INTERFACE

   USES jni, androidlog;

CONST
   MAX_JVALUES = 31;

VAR
   javaVM: PJavaVM;
   jvalues: array[0..MAX_JVALUES] of jvalue;
   pjvalues: pointer = @jvalues[0];

{converts a jstring to a pascal string}
function jniJStringToString(Env: PJNIEnv; JStr: jstring): String;
{JNI_OnLoad callback}
function jniOnLoad(jvm: PJavaVM; reserved: pointer): jint; cdecl;

IMPLEMENTATION

function jniJStringToString(Env: PJNIEnv; JStr: jstring): String;
var
  IsCopy: byte = false;
  Chars: PChar;

begin
   if(JStr = nil) then
      exit('');

   Chars:= Env^^.GetStringUTFChars(Env, JStr, IsCopy);
   if Chars = nil then
      Result := ''
   else begin
      Result := String(Chars);
      Env^^.ReleaseStringUTFChars(Env, JStr, Chars);
   end;
end;

function jniOnLoad(jvm: PJavaVM; reserved: pointer): jint; cdecl;
var
   env: PJNIEnv;

begin
   javaVM := jvm;
   if(jvm^^.GetEnv(jvm, @env, JNI_VERSION_1_4) <> JNI_OK) then begin
      __android_log_write(ANDROID_LOG_ERROR, 'JNI', 'Failed to get JNI environment for JNI version 1.4');
      exit(-1);
   end else
      __android_log_write(ANDROID_LOG_INFO, 'JNI', 'JNI_onLoad executed successfully.');

   exit(JNI_VERSION_1_4);
end;


INITIALIZATION

END.
