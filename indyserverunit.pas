unit IndyServerUnit;

interface

procedure RunTest;

implementation

uses
  IdCustomHTTPServer, IdContext, IdGlobalProtocols, IdGlobal, IdUri, Dialogs, SysUtils;

type
  TMyServer = class(TIdCustomHTTPServer)
  protected
    procedure DoCommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo); override;
  end;

procedure RunTest;
var
  Server: TMyServer;
begin
  Server := TMyServer.Create;
  try
    Server.Active := True;
    WriteLn('Server is running on http://localhost');
    ReadLn;
  finally
    Server.Free;
  end;
end;

// based on https://stackoverflow.com/questions/24861793
// and Indy IdCustomHTTPServer rev 5498
procedure MyDecodeAndSetParams(ARequestInfo: TIdHTTPRequestInfo);
var
  i, j : Integer;
  AValue, s: string;
  LEncoding: IIdTextEncoding;
begin
  AValue := ARequestInfo.UnparsedParams;
  // Convert special characters
  // ampersand '&' separates values    {Do not Localize}
  ARequestInfo.Params.BeginUpdate;
  try
    ARequestInfo.Params.Clear;
    // TODO: provide an event or property that lets the user specify
    // which charset to use for decoding query string parameters.  We
    // should not be using the 'Content-Type' charset for that.  For
    // 'application/x-www-form-urlencoded' forms, we should be, though...
    LEncoding := IndyTextEncoding_UTF8; // CharsetToEncoding(ARequestInfo.CharSet);
    i := 1;
    while i <= Length(AValue) do
    begin
      j := i;
      while (j <= Length(AValue)) and (AValue[j] <> '&') do {do not localize}
      begin
        Inc(j);
      end;
      s := Copy(AValue, i, j-i);
      // See RFC 1866 section 8.2.1. TP
      s := ReplaceAll(s, '+', ' ');  {do not localize}
      ARequestInfo.Params.Add(TIdURI.URLDecode(s, LEncoding));
      i := j + 1;
    end;
  finally
    ARequestInfo.Params.EndUpdate;
  end;
end;

procedure TMyServer.DoCommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
  if (ARequestInfo.CommandType = hcPOST) and
     IsHeaderMediaType(ARequestInfo.ContentType, 'application/x-www-form-urlencoded')
  then begin
    MyDecodeAndSetParams(ARequestInfo);

    WriteLn('CharSet: ' + ARequestInfo.CharSet);
    WriteLn('FormParams: ' + ARequestInfo.FormParams);
    ShowMessage('Param[0]: ' + ARequestInfo.Params[0]);
  end;

  AResponseInfo.ContentText :=
  '<!DOCTYPE HTML>'
+ '<html lang="en">'
+ '<head>'
+ '  <meta charset="utf-8">'
+ '  <title>Form Test</title>'
+ '</head>'
+ '<body>'
+ '  <form method="POST">'
+ '    <input type="text" name="input" />'
+ '    <input type="submit" />'
+ '  </form>'
+ '</body>'
+ '</html>';
  AResponseInfo.ContentType := 'text/html';
  AResponseInfo.CharSet := 'utf-8';
end;

end.

