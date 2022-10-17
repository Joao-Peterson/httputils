unit querystringU;

interface

uses
    JSON,
    System.Classes;

type
    // class util that can parse/serialize to and from querystring (percent-encoded) and json
    querystringT = class
        // create querystring from a string, generally a http request body of content type application/x-www-form-urlencoded
        constructor Create(querystring: string); overload;
        // create a querystring from a json object
        constructor Create(json: TJSONObject); overload;

        // serializes querystring to json format
        function toJson(): string;
        // serializes querystring to string list, for easier handling like: list.Values['valueName']
//        function toQuerystring(): TStringList;

        // encode string to percentencoding used in application/x-www-form-urlencoded request
        class function percentEncode(str: string; isUri: boolean=true): string;
        // decode string from percentencoding used in application/x-www-form-urlencoded request
        class function percentDecode(str: string; isUri: boolean=true): string;

        // build a percent encoded url based on the rfc3986 spec. URI Regex: ^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?    $7 are all the params, $4 is the host, $5 the routes, $2 the protocol
//        function URLBuilder(host: string; routes: TStringList; params: TStringList);

        // destroy
        destructor Destroy(); override;
    private
        querystring: TStringList;
        json: TJSONObject;
    end;

implementation

uses
    System.RegularExpressions,
    JSON.Writers,
    System.SysUtils;

function querystringT.toJson(): string;
var
    writter: TJsonObjectWriter;
    parents: TArray<string>;
    curParents: TArray<string>;
    curParentsSize: integer;
    buffer: string;
    parentsSize: integer;
    i: Integer;
    j: integer;
    k: integer;
    run: integer;
begin
    if self.json <> nil then
    begin
        Result := self.json.ToJSON();
        exit();
    end;

    curParents := nil;
    curParentsSize := 0;
    writter := TJsonObjectWriter.Create();
    writter.WriteStartObject();

    // for every path/key=value pair
    for i := 0 to self.querystring.Count - 1 do
    begin
        buffer := TRegEx.Replace(querystring.Names[i], '\]\[', '[');
        buffer := TRegEx.Replace(buffer, '\]', '');
        parents := TRegEx.Split(buffer, '\[');
        parentsSize := Length(parents);

        if parentsSize <= 0 then
        begin
            continue;
//            raise Exception.Create('Couldn''t parse querystring value. Value index: [' + IntToStr(i) + ']');
        end;

        // if parentless value
        if parentsSize = 1 then
        begin
            // close all objects
            for j := 0 to curParentsSize-1 do
                writter.WriteEndObject();

            // reset curparents
            Delete(curParents, 0, curParentsSize);
            curParentsSize := 0;

            // write value
            writter.WritePropertyName(parents[parentsSize-1]);
            writter.WriteValue(percentDecode(querystring.ValueFromIndex[i], false));
        end

        // if value has parents
        else
        begin
            if curParentsSize < parentsSize then run := curParentsSize else run := parentsSize;

            // point where they differentiate
            j := 0;
            for j := 0 to run-1 do
            begin
                if parents[j].CompareTo(curParents[j]) <> 0 then
                    break;
            end;

            // end old objs
            for k := j to curParentsSize-1 do
                writter.WriteEndObject();

            // create new ones
            for k := j to parentsSize-2 do
            begin
                writter.WritePropertyName(parents[k]);
                writter.WriteStartObject();
            end;

            // reset parents
            Delete(curParents, 0, curParentsSize);
            curParents := Copy(parents, 0, parentsSize-1);
            curParentsSize := parentsSize-1;

            // write value
            writter.WritePropertyName(parents[parentsSize-1]);
            writter.WriteValue(percentDecode(querystring.ValueFromIndex[i], false));
        end;
    end;

    writter.WriteEndObject();
    Result := writter.JSON.ToJSON();
    writter.Destroy();
end;

class function querystringT.percentEncode(str: string; isUri: boolean): string;
var
  i: integer;
  en: string;
begin
    for i := 0 to str.Length-1 do
    begin
        case str.Chars[i] of
            ':': en := en + '%3A';
            '/': en := en + '%2F';
            '?': en := en + '%3F';
            '#': en := en + '%23';
            '[': en := en + '%5B';
            ']': en := en + '%5D';
            '@': en := en + '%40';
            '!': en := en + '%21';
            '$': en := en + '%24';
            '&': en := en + '%26';
            '''': en := en + '%27';
            '(': en := en + '%28';
            ')': en := en + '%29';
            '*': en := en + '%2A';
            '+': en := en + '%2B';
            ',': en := en + '%2C';
            ';': en := en + '%3B';
            '=': en := en + '%3D';
            '%': en := en + '%25';
            ' ': if isUri then en := en + '%20' else en := en + '+';
            else en := en + str.Chars[i];
        end;
    end;

    Result := en;
end;

class function querystringT.percentDecode(str: string; isUri: boolean): string;
var
  i: integer;
  code: integer;
  de: string;
begin
    i := 0;
    while i <= str.Length-1 do
    begin
        if str.Chars[i] = '%' then
        begin
            try
                code := StrToInt('$' + str.Substring(i+1, 2));
            except
                on E: exception do
                begin
                    de := de + str.Chars[i];
                    i := i + 1;
                    continue;
                end;
            end;

            case code of
                $3A: de := de + ':';
                $2F: de := de + '/';
                $3F: de := de + '?';
                $23: de := de + '#';
                $5B: de := de + '[';
                $5D: de := de + ']';
                $40: de := de + '@';
                $21: de := de + '!';
                $24: de := de + '$';
                $26: de := de + '&';
                $27: de := de + '''';
                $28: de := de + '(';
                $29: de := de + ')';
                $2A: de := de + '*';
                $2B: de := de + '+';
                $2C: de := de + ',';
                $3B: de := de + ';';
                $3D: de := de + '=';
                $25: de := de + '%';
                $20: de := de + ' ';
            end;

            i := i + 2;
        end
        else if((not isUri) and (str.Chars[i] = '+'))then
        begin
            de := de + ' ';
        end
        else
        begin
            de := de + str.Chars[i];
        end;

        i := i + 1;
    end;

    Result := de;
end;

constructor querystringT.Create(querystring: string);
begin
    inherited Create();
    self.querystring := TStringList.Create();
    self.querystring.Delimiter := '&';
    self.querystring.DelimitedText := querystring;
    self.json := nil;
end;

constructor querystringT.Create(json: TJSONObject);
begin
    inherited Create();
    querystring := nil;
    self.json := json;
end;

destructor querystringT.Destroy();
begin
    if querystring <> nil then querystring.Destroy();
    if json <> nil then json.Destroy();
    inherited Destroy();
end;

end.
