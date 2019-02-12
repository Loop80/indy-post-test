unit IndyServerUnit;

interface

{$i IdCompilerDefines.inc}

procedure RunTest;

implementation

uses
  IdCustomHTTPServer, IdContext, IdGlobalProtocols, IdGlobal, IdURI,
  ShellAPI;

type
  TMyServer = class(TIdCustomHTTPServer)
  private
    InputValue: string; // should use session instead ...
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
    ShellExecute(0, 'open', PChar('http://localhost/index.html'), '', '', 0);
    ReadLn;
  finally
    Server.Free;
  end;
end;

// based on class function TIdURI.URLDecode in Indy rev 5498

//function MyURLDecode(ASrc: string; AByteEncoding: IIdTextEncoding = nil
// ...
//  // ----------------------------
//  // Free Pascal 3.0.4 workaround: use AByteEncoding
//  //{$IFDEF STRING_IS_ANSI}
//  //EnsureEncoding(ADestEncoding, encOSDefault);
//  //CheckByteEncoding(LBytes, AByteEncoding, ADestEncoding);
//  //SetString(Result, PAnsiChar(LBytes), Length(LBytes));
//  //{$ELSE}
//  //Result := AByteEncoding.GetString(LBytes);
//  //{$ENDIF}
//  Result := string(AByteEncoding.GetString(LBytes));
//  // ----------------------------
//end;

// based on https://stackoverflow.com/questions/24861793

procedure MyDecodeAndSetParams(ARequestInfo: TIdHTTPRequestInfo);
var
  i, j : Integer;
  AValue, s: string;
  // ----------------------------
  // Free Pascal 3.0.4 workaround
  // LEncoding: IIdTextEncoding;
  // ----------------------------
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
    // Free Pascal 3.0.4 workaround
    // LEncoding := CharsetToEncoding(ARequestInfo.CharSet);
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
      // ----------------------------
      // Free Pascal 3.0.4 workaround
      // ARequestInfo.Params.Add(TIdURI.URLDecode(s, LEncoding));
      ARequestInfo.Params.Add(TIdURI.URLDecode(s, IndyTextEncoding_UTF8));
      // ----------------------------
      i := j + 1;
    end;
  finally
    ARequestInfo.Params.EndUpdate;
  end;
end;

procedure TMyServer.DoCommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
  if ARequestInfo.Document <> '/index.html' then begin
    AResponseInfo.ResponseNo := 404;
    Exit;
  end;

  if (ARequestInfo.CommandType = hcPOST) and
    IsHeaderMediaType(ARequestInfo.ContentType, 'application/x-www-form-urlencoded')
  then begin
    // decode form params
    MyDecodeAndSetParams(ARequestInfo);

    WriteLn('CharSet: ' + ARequestInfo.CharSet);
    WriteLn('FormParams: ' + ARequestInfo.FormParams);
    InputValue := ARequestInfo.Params.Values['input'];
    WriteLn('Param.Values[''input'']: ' + InputValue);

    AResponseInfo.ContentText :=
          '<!DOCTYPE HTML>'
        + '<html lang="en">'
        + '<head>'
        + '  <meta charset="utf-8">'
        + '  <title>Hello</title>'
        + '</head>'
        + '<body>'
        + '  Input: ' + InputValue
        + '</body>'
        + '</html>';
  end else begin
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
  end;

  AResponseInfo.ContentType := 'text/html';
  AResponseInfo.CharSet := 'utf-8';

  // this tells TIdHTTPServer what encoding the ContentText is using
  // so it can be decoded to Unicode prior to then being charset-encoded
  // for output. If the input and output encodings are the same, the
  // Ansi string data gets transmitted as-is without decoding/reencoding...
  AContext.Connection.IOHandler.DefAnsiEncoding := IndyTextEncoding_UTF8;
end;

end.

