unit IndyServerUnit;

interface

procedure RunTest;

implementation

uses
  IdCustomHTTPServer, IdContext, IdGlobalProtocols, IdGlobal, IdURI,
  SysUtils;

type
  TMyServer = class(TIdCustomHTTPServer)
  private
    // InputValue: string; // should use session...
  protected
    procedure DoCommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo); override;
  end;

procedure RunTest;
var
  Server: TMyServer;
begin
  FileGetAttr('');

  Server := TMyServer.Create;
  try
    Server.Active := True;
    WriteLn('Server is running on http://localhost');
    ReadLn;
  finally
    Server.Free;
  end;
end;

// based on class function TIdURI.URLDecode in Indy rev 5498

//function MyURLDecode(ASrc: string; AByteEncoding: IIdTextEncoding = nil
//  {$IFDEF STRING_IS_ANSI}; ADestEncoding: IIdTextEncoding = nil{$ENDIF}
//  ): string;
//var
//  i, SrcLen: Integer;
//  ESC: string;
//  LChars: TIdWideChars;
//  LBytes: TIdBytes;
//begin
//  Result := '';    {Do not Localize}
//  LChars := nil;
//  LBytes := nil;
//  EnsureEncoding(AByteEncoding, encUTF8);
//  // S.G. 27/11/2002: Spaces is NOT to be encoded as "+".
//  // S.G. 27/11/2002: "+" is a field separator in query parameter, space is...
//  // S.G. 27/11/2002: well, a space
//  // ASrc := ReplaceAll(ASrc, '+', ' ');  {do not localize}
//  i := 1;
//  SrcLen := Length(ASrc);
//  while i <= SrcLen do begin
//    if ASrc[i] <> '%' then begin  {do not localize}
//      AppendByte(LBytes, Ord(ASrc[i])); // Copy the char
//      Inc(i); // Then skip it
//    end else begin
//      Inc(i); // skip the % char
//      if not CharIsInSet(ASrc, i, 'uU') then begin  {do not localize}
//        // simple ESC char
//        ESC := Copy(ASrc, i, 2); // Copy the escape code
//        Inc(i, 2); // Then skip it.
//        try
//          AppendByte(LBytes, Byte(IndyStrToInt('$' + ESC))); {do not localize}
//        except end;
//      end else
//      begin
//        // unicode ESC code
//
//        // RLebeau 5/10/2006: under Win32, the character will likely end
//        // up as '?' in the Result when converted from Unicode to Ansi,
//        // but at least the URL will be parsed properly
//
//        ESC := Copy(ASrc, i+1, 4); // Copy the escape code
//        Inc(i, 5); // Then skip it.
//        try
//          if LChars = nil then begin
//            SetLength(LChars, 1);
//          end;
//          LChars[0] := WideChar(IndyStrToInt('$' + ESC));  {do not localize}
//          AppendBytes(LBytes, AByteEncoding.GetBytes(LChars));
//        except end;
//      end;
//    end;
//  end;
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
  // Free Pascal 3.0.4 workaround: use MyURLDecode and UTF8
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
      // Free Pascal 3.0.4 workaround: use MyURLDecode and UTF8
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

  AResponseInfo.ContentText :=
      '<!DOCTYPE HTML>'
    + '<html lang="en">'
    + '<head>'
    + '  <meta charset="utf-8">'
    + '  <title>Hello</title>'
    + '</head>'
    + '<body>'
    + '  Input ' + Utf8Encode('ä')
    + '</body>'
    + '</html>';
  AResponseInfo.ContentType := 'text/html';
  AResponseInfo.CharSet := 'utf-8';


  //if (ARequestInfo.CommandType = hcPOST) and
  //  IsHeaderMediaType(ARequestInfo.ContentType, 'application/x-www-form-urlencoded')
  //then begin
  //  MyDecodeAndSetParams(ARequestInfo);
  //
  //  WriteLn('CharSet: ' + ARequestInfo.CharSet);
  //  WriteLn('FormParams: ' + ARequestInfo.FormParams);
  //  InputValue := ARequestInfo.Params.Values['input'];
  //  WriteLn('Param.Values[''input'']: ' + InputValue);
  //
  //  // redirect to thankyou page
  //  AResponseInfo.Redirect('thankyou.html');
  //  Exit;
  //end else begin
  //  AResponseInfo.ContentText :=
  //      '<!DOCTYPE HTML>'
  //    + '<html lang="en">'
  //    + '<head>'
  //    + '  <meta charset="utf-8">'
  //    + '  <title>Form Test</title>'
  //    + '</head>'
  //    + '<body>'
  //    + '  <form method="POST">'
  //    + '    <input type="text" name="input" />'
  //    + '    <input type="submit" />'
  //    + '  </form>'
  //    + '</body>'
  //    + '</html>';
  //  AResponseInfo.ContentType := 'text/html';
  //  AResponseInfo.CharSet := 'utf-8';
  //end;
end;

end.

