{
   ulogAndroid, uLog android handler
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT android_log_helper;

INTERFACE

   USES
      uStd;

procedure logi(priority: longint; const what: StdString);
procedure logi(const what: StdString);
procedure logw(const what: StdString);
procedure loge(const what: StdString);
procedure logf(const what: StdString);
procedure logv(const what: StdString);

IMPLEMENTATION

var
   tag: pchar = 'ox';

function __android_log_write(prio: longint; tag, text: pchar): longint; cdecl; external 'log' name '__android_log_write';

procedure logi(priority: longint; const what: StdString);
begin
   __android_log_write(priority, tag, PChar(what));
end;

procedure logi(const what: StdString);
begin
   __android_log_write(ANDROID_LOG_INFO, tag, PChar(what));
end;

procedure logw(const what: StdString);
begin
   __android_log_write(ANDROID_LOG_WARN, tag, PChar(what));
end;

procedure loge(const what: StdString);
begin
   __android_log_write(ANDROID_LOG_ERROR, tag, PChar(what));
end;

procedure logf(const what: StdString);
begin
   __android_log_write(ANDROID_LOG_FATAL, tag, PChar(what));
end;

procedure logv(const what: StdString);
begin
   __android_log_write(ANDROID_LOG_VERBOSE, tag, PChar(what));
end;

END.
