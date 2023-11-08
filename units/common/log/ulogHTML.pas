{
   ulogHTML, uLog HTML handler
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT ulogHTML;

INTERFACE

   USES
      sysutils,
      uStd, uLog, StringUtils;

TYPE

   { THTMLLogHandler }

   THTMLLogHandler = object(TStandardLogHandler)
      constructor Create();

      procedure Start(logf: PLog); virtual;
      procedure Close(log: PLog); virtual;
      procedure Writeln(logf: PLog; priority: longint; const s: StdString); virtual;
      procedure EnterSection(log: PLog; const s: StdString; collapsed: boolean); virtual;
      procedure LeaveSection(log: PLog); virtual;
   end;

VAR
   loghHTML: THTMLLogHandler;

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

   htmlTypeClasses: array[0..logcPRIORITY_MAX] of StdString = (
      'info',
      'warning',
      'error',
      'verbose',
      'fatal',
      'debug',
      'ok'
   );

function encode(const htmlString: StdString): StdString;
begin
  Result :=
  StringReplace(
    StringReplace(
    StringReplace(
    StringReplace(
      htmlString,
      '&','&amp;', [rfReplaceAll]),
      '<','&lt;', [rfReplaceAll]),
      '>','&gt;', [rfReplaceAll]),
      '"','&quot;', [rfReplaceAll]);
end;

procedure hclose(logf: PLog);
begin
   logf^.HandlerWritelnRaw(htmlEnd);
   log.handler.standard.close(logf);
end;

procedure hEnterSection(logf: PLog; const s: StdString; collapsed: boolean);
begin
   logf^.HandlerWritelnRaw('<div class="sectionenclosure">');
   logf^.HandlerWritelnRaw('<div class="sectiontitle">' + encode(s) + '</div>');

   if(not collapsed) then
      logf^.HandlerWritelnRaw('<div class="section">')
   else
      logf^.HandlerWritelnRaw('<div class="section" hidden="true">');
end;

procedure hLeaveSection(logf: PLog);
begin
   logf^.HandlerWritelnRaw('</div></div>');
end;

{ THTMLLogHandler }

constructor THTMLLogHandler.Create();
begin
   inherited;

   Name := 'html';
   FileExtension := 'html';
   NoHeader := true;
end;

procedure THTMLLogHandler.Start(logf: PLog);
begin
   logf^.HandlerWritelnRaw(htmlHeader);
   logf^.HandlerWritelnRaw('<title>' + logf^.LogHeader + '</title>');
   logf^.HandlerWritelnRaw('<style type="text/css">' + htmlCSS + '</style>');
   logf^.HandlerWritelnRaw(htmlBody);
end;

procedure THTMLLogHandler.Close(log: PLog);
begin
   log^.HandlerWritelnRaw(htmlEnd);

   inherited Close(log);
end;

procedure THTMLLogHandler.Writeln(logf: PLog; priority: longint; const s: StdString);
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
   buf.Write(encode(s));
   buf.Write('</span></div>');

   logf^.HandlerWritelnRaw(buf.Get());
end;

procedure THTMLLogHandler.EnterSection(log: PLog; const s: StdString; collapsed: boolean);
begin
   log^.HandlerWritelnRaw('<div class="sectionenclosure">');
   log^.HandlerWritelnRaw('<div class="sectiontitle">' + encode(s) + '</div>');

   if(not collapsed) then
      log^.HandlerWritelnRaw('<div class="section">')
   else
      log^.HandlerWritelnRaw('<div class="section" hidden="true">');
end;

procedure THTMLLogHandler.LeaveSection(log: PLog);
begin
   log^.HandlerWritelnRaw('</div></div>');
end;

INITIALIZATION
   {use the standard log handler for most operations}
   loghHTML.Create();

END.
