{
   ulogHTML, uLog HTML handler
   Copyright (C) 2011. Dejan Boras

   Started On:    02.11.2011.
}

{$MODE OBJFPC}{$H+}
UNIT ulogHTML;

INTERFACE

   USES sysutils, StringUtils, uLog;

VAR
   loghHTML: TLogHandler;

IMPLEMENTATION

CONST
   htmlCSS = {$INCLUDE htmllog.css.inc};
   htmlJS = {$INCLUDE htmllog.js.inc};

   htmlHeader =
      '<!DOCTYPE html>'#10'<html>'#10+
      '<head>';
   htmlBody =
      '</head>'#10 +
      '<body>'#10 +
      '<script type="application/javascript">' + htmlJS + '</script>'#10 +
      '</body>'#10 +
      '</html>';
   htmlEnd =
      '</body>'#10 +
      '</html>';

   htmlTypeClasses: array[0..logcPRIORITY_MAX] of string = (
      'info',
      'warning',
      'error',
      'verbose',
      'fatal',
      'debug',
      'ok'
   );

procedure hopen(logFile: PLog);
begin
   log.handler.Standard.open(logFile);
end;

procedure hstart(logf: PLog);
begin
   logf^.HandlerWritelnRaw(htmlHeader);
   logf^.HandlerWritelnRaw('<title>' + logf^.LogHeader + '</title>');
   logf^.HandlerWritelnRaw('<style type="text/css">' + htmlCSS + '</style>');
   logf^.HandlerWritelnRaw(htmlBody);
end;

procedure hwriteln(logf: PLog; priority: longint; const s: string);
var
   td: TDateTime;
   buf: TSimpleAnsiStringBuffer;

begin
   td := Now();
   buf.Reset();

   buf.Write('<div class="logentry"><span class="timestamp">');
   buf.Write(TimeToStr(td));
   buf.Write('</span><span ');
   if(priority <> 0) then begin
      buf.Write('class="');
      buf.Write(htmlTypeClasses[priority]);
      buf.Write('"');
   end;

   buf.Write('>');
   buf.Write(s);
   buf.Write('</span></div>');

   logf^.HandlerWritelnRaw(buf.Get());
end;

procedure hclose(logf: PLog);
begin
   logf^.HandlerWritelnRaw(htmlEnd);
   log.handler.standard.close(logf);
end;

procedure hEnterSection(logf: PLog; const s: string; collapsed: boolean);
begin
   logf^.HandlerWritelnRaw('<div class="sectionenclosure">');
   logf^.HandlerWritelnRaw('<div class="sectiontitle">' + s + '</div>');
   if(not collapsed) then
      logf^.HandlerWritelnRaw('<div class="section">')
   else
      logf^.HandlerWritelnRaw('<div class="section" hidden="true">');
end;

procedure hLeaveSection(logf: PLog);
begin
   logf^.HandlerWritelnRaw('</div></div>');
end;

INITIALIZATION
   {use the standard log handler for most operations}
   loghHTML                := log.handler.Standard;
   loghHTML.Name           := 'html';
   loghHTML.fileExtension  := 'html';
   loghHTML.open           := @hopen;
   loghHTML.start          := @hstart;
   loghHTML.writeln        := @hwriteln;
   loghHTML.close          := @hclose;
   loghHTML.enterSection   := @hEnterSection;
   loghHTML.leaveSection   := @hLeaveSection;
   {nothing should be output to the file by default }
   loghHTML.noHeader       := true;

   log.handler.pDefault := @loghHTML;
END.

