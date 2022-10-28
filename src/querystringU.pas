unit querystringU;

interface

uses
    JSON,
    System.Classes,
    System.Generics.Collections,
    JSON.Writers;

type

    // enumerator that represents a type of value a json pair can hold 
    jsonValueTypeEnum = (
        jsonNull        = 0,
        jsonBoolean     = 1,
        jsonInteger     = 2,
        jsonFloat       = 3,
        jsonString      = 4
    );

    jsonValueT = record
        case jsonType: jsonValueTypeEnum of
            jsonNull:       (nullValue:     String[255]);
            jsonBoolean:    (booleanValue:  Boolean); 
            jsonInteger:    (integerValue:  Integer);
            jsonFloat:      (floatValue:    Extended);     
            jsonString:     (stringValue:   String[255]);     
    end;

    // class util that can parse/serialize to and from querystring (percent-encoded) and json
    querystringT = class
        // create querystring from a string, generally a http request body of content type application/x-www-form-urlencoded
        constructor Create(querystring: string); overload;
        // create a querystring from a json object
        constructor Create(json: TJSONObject); overload;

        // serializes querystring to json format
        function toJson(parseBool: Boolean = true; parseNull: Boolean = true; parseFloats: Boolean = true; parseIntegers: Boolean = true): string;
        // serializes querystring to string list, for easier handling like: list.Values['valueName']
//        function toQuerystring(): TStringList;

        // encode string to percentencoding used in application/x-www-form-urlencoded request
        class function percentEncode(str: string; isUri: boolean=true): string;
        // decode string from percentencoding used in application/x-www-form-urlencoded request
        class function percentDecode(str: string; isUri: boolean=true): string;

        // build a percent encoded url based on the rfc3986 spec. URI Regex: ^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?    $7 are all the params, $4 is the host, $5 the routes, $2 the protocol
//        function URLBuilder(host: string; routes: TStringList; params: TStringList);

        // parses a json value from a string to the correct type
        class function parseJsonValue(value: string; parseBool: Boolean = true; parseNull: Boolean = true; parseFloats: Boolean = true; parseIntegers: Boolean = true): jsonValueT;

        // destroy
        destructor Destroy(); override;
    private
        qsKeys: TList<string>;
        qsValues: TList<string>;
        json: TJSONObject;

        // writes the correct type of json value from a string
        class procedure writeJsonValue(writter: TJsonWriter; value: string; parseBool: Boolean; parseNull: Boolean; parseFloats: Boolean; parseIntegers: Boolean);
    end;


implementation

uses
    System.RegularExpressions,
    System.SysUtils;

function querystringT.toJson(parseBool: Boolean; parseNull: Boolean; parseFloats: Boolean; parseIntegers: Boolean): string;
var
    writter: TJsonObjectWriter;
    parents: TArray<string>;
    curParents: TArray<string>;
    curParentsSize: integer;
    buffer: string;
    parentsSize: integer;
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
    var key, value: string;
    var i: integer;
    for i := 0 to qsKeys.Count-1 do
    begin
        buffer := TRegEx.Replace(qsKeys.Items[i], '\]\[', '[');
        buffer := TRegEx.Replace(buffer, '\]', '');
        parents := TRegEx.Split(buffer, '\[');
        parentsSize := Length(parents);

        if parentsSize <= 0 then
        begin
            continue;
//            raise Exception.Create('Couldn''t parse querystring value. Value index: [' + IntToStr(i) + ']');
        end;

        // if parentless value
        var j: integer := 0;
        if parentsSize = 1 then
        begin
            // close all objects
            for j := 0 to curParentsSize-1 do
                writter.WriteEnd();

            // reset curparents
            Delete(curParents, 0, curParentsSize);
            curParentsSize := 0;

            // write value
            writter.WritePropertyName(parents[parentsSize-1]);
            writeJsonValue(writter, qsValues.Items[i], parseBool, parseNull, parseFloats, parseIntegers);
        end

        // if value has parents
        else
        begin
            var run: integer;
            if curParentsSize < parentsSize then run := curParentsSize else run := parentsSize;

            // point where they differentiate
            for j := 0 to run-1 do
            begin
                if parents[j].CompareTo(curParents[j]) <> 0 then
                    break;
            end;

            // end old objs
            var k: integer := 0;
            for k := j to curParentsSize-1 do
            begin
                writter.WriteEnd();
            end;

            // create new ones
            for k := j to parentsSize-2 do
            begin
                var mat: TMatch := TRegEx.Match(parents[k], '\d+');

                if((not mat.Success) or (mat.Length <> parents[k].Length)) then     // only write name of values that dont have numeric names
                    writter.WritePropertyName(parents[k]);

                mat := TRegEx.Match(parents[k+1], '\d+');
                if((mat.Success) and (mat.Length = parents[k+1].Length)) then       // if child has numeric name, then this values is and array
                    writter.WriteStartArray()
                else                                                                // if not is a object
                    writter.WriteStartObject();

            end;

            // reset parents
            Delete(curParents, 0, curParentsSize);
            curParents := Copy(parents, 0, parentsSize-1);
            curParentsSize := parentsSize-1;

            // write value
            writter.WritePropertyName(parents[parentsSize-1]);
            writeJsonValue(writter, qsValues.Items[i], parseBool, parseNull, parseFloats, parseIntegers);
        end;
    end;

    writter.WriteEndObject();
    Result := writter.JSON.ToJSON();
    writter.Destroy();
end;

class procedure querystringT.writeJsonValue(writter: TJsonWriter; value: string; parseBool: Boolean; parseNull: Boolean; parseFloats: Boolean; parseIntegers: Boolean);
begin
    if (value.IsEmpty() and parseNull) then                                         // null
        writter.WriteNull()

    else if ((value.CompareTo('null') = 0) and parseNull) then                      // null, variation
        writter.WriteNull

    else if ((value.CompareTo('true') = 0) and parseBool) then                      // true
        writter.WriteValue(true)

    else if ((value.CompareTo('false') = 0) and parseBool) then                     // false
        writter.WriteValue(false)

    else if                                                                         // integer
        ((TRegEx.Match(value, '[-+]?\d+').Length = 
        value.Length)
        and parseIntegers)
    then 
    begin
        try
            var num: Integer := StrToInt(value);                                    // if can parse
            writter.WriteValue(num);                                                // as integer
        except
            on E: Exception do
            begin
                writter.WriteValue(value);                                          // as string
            end;
        end;
    end
    else if                                                                         // float 
        ((TRegEx.Match(value, '[-+]?\d*\.?\d+([eE][-+]?\d+)?').Length = 
        value.Length)
        and parseFloats)
    then 
    begin
        try
            var num: Extended := StrToFloat(                                        // if can parse
                value, 
                TFormatSettings.Create('en-US')
            );
            writter.WriteValue(num);                                                // as Extended
        except
            on E: Exception do
            begin
                writter.WriteValue(value);                                          // as String
            end;
        end;
    end
    else
        writter.WriteValue(value);                                                  // string
end;

class function querystringT.percentEncode(str: string; isUri: boolean): string;
var
  i: integer;
  en: string;
begin
    for i := 0 to str.Length-1 do                                                   // for every char
    begin
        case str.Chars[i] of                                                        // encode
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
            ' ': if isUri then en := en + '%20' else en := en + '+';                // if not "uri" then encode space as '+'
            else en := en + str.Chars[i];                                           // on any other char just append
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
    while i <= str.Length-1 do                                                      // for every char
    begin
        if str.Chars[i] = '%' then                                                  // on encoded char
        begin
            try
                code := StrToInt('$' + str.Substring(i+1, 2));                      // try forming hexadecimal
            except
                on E: exception do
                begin
                    de := de + str.Chars[i];                                        // just apend the '%' if code was invalid
                    i := i + 1;                                                     // in this case just jump one forwards and continue
                    continue;
                end;
            end;

            case code of                                                            // decode from hex
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

            i := i + 2;                                                             // jump over the code chars
        end 
        else if((not isUri) and (str.Chars[i] = '+'))then                           // if '+'
        begin
            de := de + ' ';
        end
        else
        begin                                                                       // on any char
            de := de + str.Chars[i];
        end;

        i := i + 1;
    end;

    Result := de;
end;

constructor querystringT.Create(querystring: string);
begin
    inherited Create();

    self.qsKeys := TList<string>.Create();
    self.qsValues := TList<string>.Create();
    if querystring.IsEmpty() then exit;

    var input: string;
    try
        input := percentDecode(querystring, false);                                 // decode just to be sure
    except
      on E: Exception do raise;
    end;

    var sep: integer := Pos('&', input);                                            // search separator
    if sep = 0 then sep := Length(input)+1;

    while true do                                                                   // while the there are no more '&' separators
    begin
        if sep <> 1 then                                                            // if single '&' then just wait to find another one
        begin
            var pair: string := Copy(input, 0, sep-1);                              // copy key value pair
            var key: string;
            var value: string;

            var equal: integer := Pos('=', pair);                                   // find '=' separator
            if equal = 0 then                                                       // empty value
            begin
                self.qsKeys.Add(pair);
                self.qsValues.Add('');
            end
            else
            begin                                                                   // key and value
                key := Copy(pair, 0, equal-1);
                value := Copy(pair, equal+1, Length(pair)-equal);
                self.qsKeys.Add(key);
                self.qsValues.Add(value);
            end;
        end;

        Delete(input, 1, sep);                                                      // remove just read key/value pair from input
        sep := Pos('&', input);                                                     // search next separator
        if sep = 0 then                                                             // on last pair or end
        begin
           if input.IsEmpty then break;                                             // on end
           sep := Length(input)+1;                                                  // if just on last set sep to the end
        end
    end;

    self.json := nil;
end;

class function querystringT.parseJsonValue(value: string; parseBool: Boolean; parseNull: Boolean; parseFloats: Boolean; parseIntegers: Boolean): jsonValueT;
begin
    var union: jsonValueT;

    if (value.IsEmpty() and parseNull) then                                         // null
    begin
        union.jsonType := jsonNull;
        union.nullValue := '';
    end

    else if ((value.CompareTo('null') = 0) and parseNull) then                      // null, variation
    begin
        union.jsonType := jsonNull;
        union.nullValue := '';
    end

    else if ((value.CompareTo('true') = 0) and parseBool) then                      // true
    begin
        union.jsonType := jsonBoolean;
        union.booleanValue := true;
    end

    else if ((value.CompareTo('false') = 0) and parseBool) then                     // false
    begin
        union.jsonType := jsonBoolean;
        union.booleanValue := false;
    end

    else                                                                            // integer, float, string
    begin
        var resInt: TMatch;
        var resFloat: TMatch;

        if parseIntegers then
            resInt := TRegEx.Match(value, '[-+]?\d+');

        if parseIntegers then
            resFloat := TRegEx.Match(value, '[-+]?\d*\.?\d+([eE][-+]?\d+)?');

        if(resInt.Success and (resInt.Length = value.Length)) then                    // integer
        begin
            try
                var num: Integer := StrToInt(value);                                // if can parse
                union.jsonType := jsonInteger;
                union.integerValue := num;
            except
                on E: Exception do
                begin
                    union.jsonType := jsonString;
                    union.stringValue := value;
                end;
            end;
        end
        else if(resFloat.Success and (resFloat.Length = value.Length)) then           // integer
        begin
            try
                var num: Extended := StrToFloat(                                    // if can parse
                    value, 
                    TFormatSettings.Create('en-US')
                );
                
                union.jsonType := jsonFloat;    
                union.floatValue := num;
            except
                on E: Exception do
                begin
                    union.jsonType := jsonString;
                    union.stringValue := value;
                end;
            end;
        end
        else
        begin                                                                       // string
            union.jsonType := jsonString;
            union.stringValue := value;
        end;
    end;

    Result := union;
end;

constructor querystringT.Create(json: TJSONObject);
begin
    inherited Create();
    qsKeys := nil;
    qsValues := nil;
    self.json := json;
end;

destructor querystringT.Destroy();
begin
    if qsKeys <> nil then qsKeys.Destroy();
    if qsValues <> nil then qsValues.Destroy();
    if json <> nil then json.Destroy();
    inherited Destroy();
end;

end.
