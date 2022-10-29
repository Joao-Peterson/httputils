unit httpUtilsU;

interface

type

    // enumerator that represents a type of value a json pair can hold 
    jsonValueTypeEnum = (
        jsonNull        = 0,
        jsonBoolean     = 1,
        jsonInteger     = 2,
        jsonFloat       = 3,
        jsonString      = 4
    );

    // union record for the json value
    jsonValueT = record
        case jsonType: jsonValueTypeEnum of
            jsonNull:       (nullValue:     String[255]);
            jsonBoolean:    (booleanValue:  Boolean); 
            jsonInteger:    (integerValue:  Integer);
            jsonFloat:      (floatValue:    Extended);     
            jsonString:     (stringValue:   String[255]);     
    end;

    // class with static/class util methods for http and other api request stuff like some json commands
    httpUtilsT = class

        // encode string to percentencoding used in application/x-www-form-urlencoded request
        class function percentEncode(str: string; isUri: boolean = true): string;
        // decode string from percentencoding used in application/x-www-form-urlencoded request
        class function percentDecode(str: string; isUri: boolean = true): string;

        // build a percent encoded url based on the rfc3986 spec. URI Regex: ^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?    $7 are all the params, $4 is the host, $5 the routes, $2 the protocol
        // function URLBuilder(host: string; routes: TStringList; params: TStringList);

        // substitute points on a string for '[' and ']'. Ex: 'a.b.c' -> 'a[b][c]'
        class function pointsToBrackets(input: string): string;

        // substitute brackets on a string for '.'. Ex: 'a[b][c]' -> 'a.b.c'
        class function bracketsToPoints(input: string): string;

        // split a string by brackets. Ex: 'a[b][c]' -> '(a, b, c)'
        class function bracketsSplit(input: string): TArray<String>;

        // parses a json value from a string to the correct type
        class function parseJsonValue(value: string; parseBool: Boolean = true; parseNull: Boolean = true; parseFloats: Boolean = true; parseIntegers: Boolean = true): jsonValueT;
    end;

implementation

uses
    System.RegularExpressions,
    System.SysUtils,
    System.Character,
    System.JSON.Types;

const 
    percentcodeUnreserved   = ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '~'];
    percentcodeReserved     = [':', '/', '?', '#', '[', ']', '@', '!', '$', '&', '''', '(', ')', '*', '+', ',', ';', '=', '%']; 


// ------------------------------------------------- Percent/URL encoding --------------------------------------------------

class function httpUtilsT.percentEncode(str: string; isUri: boolean): string;
begin
    var i: integer;
    var en: string := '';
    for i := 0 to str.Length-1 do                                                   // for every char
    begin    
        if(str.Chars[i] in percentcodeUnreserved) then
            en := en + str.Chars[i]

        else if((not isUri) and (str.Chars[i] = ' ')) then
            en := en + '+'
        else
            en := en + '%' + IntToHex(Ord(str.Chars[i]), 2);
    end;

    Result := en;
end;

class function httpUtilsT.percentDecode(str: string; isUri: boolean): string;
begin
    var i: integer := 0;
    var code: integer := 0;
    var de: string := '';
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

            de := de + Chr(code);

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

// ------------------------------------------------- Json related methods --------------------------------------------------

class function httpUtilsT.parseJsonValue(value: string; parseBool: Boolean; parseNull: Boolean; parseFloats: Boolean; parseIntegers: Boolean): jsonValueT;
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

        if(resInt.Success and (resInt.Length = value.Length)) then                  // integer
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
        else if(resFloat.Success and (resFloat.Length = value.Length)) then         // integer
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

// ------------------------------------------------- Misc methods ----------------------------------------------------------

class function httpUtilsT.pointsToBrackets(input: string): string;
begin
    var reg := TRegEx.Create('\.');
    var buffer: string := reg.Replace(input, '[', 1);
    Result := reg.Replace(buffer, '][');
    
    if((buffer.CompareTo(input) <> 0) and (Result[Result.Length-1] <> ']')) then
        Result := Result + ']';
end;

class function httpUtilsT.bracketsToPoints(input: string): string;
begin
    var buffer: string := TRegEx.Replace(input, '\]\[', '[');
    buffer := TRegEx.Replace(buffer, '\]', '');
    Result := TRegEx.Replace(buffer, '\[', '.');
end;

class function httpUtilsT.bracketsSplit(input: string): TArray<String>;
begin
    var buffer: string := TRegEx.Replace(input, '\]\[', '[');
    buffer := TRegEx.Replace(buffer, '\]', '');
    Result := TRegEx.Split(buffer, '\[');
end;


end.