{
   ulogAndroid, uLog android handler
   Copyright (C) 2019. Dejan Boras
}

{$MODE OBJFPC}{$H+}
UNIT android_log_helper;

INTERFACE

   USES
      uStd;

procedure logi(priority: longint; const what: StdString);
procedure logi(const what: StdString);
procedure logw(const what: StdString);
procedure loge(const what: StdString);
procedure logf(const what: StdString);

IMPLEMENTATION

procedure logi(priority: longint; const what: StdString);
begin
   SysLogWrite(priority, PAnsiChar(what));
end;

procedure logi(const what: StdString);
begin
   SysLogWrite(ANDROID_LOG_INFO, PAnsiChar(what));
end;

procedure logw(const what: StdString);
begin
   SysLogWrite(ANDROID_LOG_WARN, PAnsiChar(what));
end;

procedure loge(const what: StdString);
begin
   SysLogWrite(ANDROID_LOG_ERROR, PAnsiChar(what));
end;

procedure logf(const what: StdString);
begin
   SysLogWrite(ANDROID_LOG_FATAL, PAnsiChar(what));
end;

END.
