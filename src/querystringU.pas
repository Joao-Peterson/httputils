unit querystringU;

interface

uses
    System.Classes,
    System.Generics.Collections,
    System.JSON,
    System.JSON.Writers,
    System.JSON.Readers,
    System.JSON.Builders;

type

    // class util that can parse/serialize to and from querystring (percent-encoded) and json
    querystringT = class
        // create new instance. Use the 'parse*()' calls tomoperate on some types of data
        constructor Create();

        // create querystring from a string, generally a http request body of content type application/x-www-form-urlencoded
        procedure parseQuerystring(querystring: string);
        // create a querystring from a json object
        procedure parseJsonObject(json: TJSONObject; parseNull: boolean = true);
        // create a querystring from a json string
        procedure parseJson(json: string; parseNull: boolean = true);

        // serializes querystring to json format
        function toJsonObject(parseBool: Boolean = true; parseNull: Boolean = true; parseFloats: Boolean = true; parseIntegers: Boolean = true): TJSONObject;
        function toJson(parseBool: Boolean = true; parseNull: Boolean = true; parseFloats: Boolean = true; parseIntegers: Boolean = true): string;
        // serializes querystring to string list, for easier handling like: list.Values['valueName']
        function toQuerystringList(): TStringList;
        // serializes querystring to a single string with optional percent encoding
        function toQuerystring(encode: Boolean = true): string;

        // destroy
        destructor Destroy(); override;

    private
        // querystring pair
        qsKeys: TList<string>;
        qsValues: TList<string>;

        // writes the correct type of json value from a string
        class procedure writeJsonValue(writter: TJsonWriter; value: string; parseBool: Boolean; parseNull: Boolean; parseFloats: Boolean; parseIntegers: Boolean);

        // recursive function to read json
        class procedure jsonToQuerystring(ite: TJSONIterator; keys: TList<string>; values: TList<string>; parseNull: boolean);
    end;


implementation

uses
    System.RegularExpressions,
    System.SysUtils,
    System.Character,
    System.JSON.Types,
    httpUtilsU;

// ------------------------------------------------- Parse methods ---------------------------------------------------------

procedure querystringT.parseQuerystring(querystring: string);
begin
    if querystring.IsEmpty() then
    begin
        raise Exception.Create('querystring parameter was empty');
        exit;
    end;

    var input: string;
    try
        input := httpUtilsT.percentDecode(querystring, false);                      // decode just to be sure
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
end;

procedure querystringT.parseJson(json: string; parseNull: boolean);
begin
    if json.IsEmpty() then
    begin
        raise Exception.Create('json parameter was empty');
        exit;
    end;

    try
        var obj: TJSONObject := TJSONObject.ParseJSONValue(json) as TJSONObject;
        parseJsonObject(obj, parseNull);
    except
        on E: Exception do raise;
    end;
end;

procedure querystringT.parseJsonObject(json: TJSONObject; parseNull: boolean);
begin
    if((json = nil) or (json.Count = 0)) then 
    begin
        raise Exception.Create('json object passed was empty or nil');;
        exit;
    end;

    var reader: TJsonObjectReader := TJsonObjectReader.Create(json);
    var ite: TJSONIterator := TJSONIterator.Create(reader);
    jsonToQuerystring(ite, qsKeys, qsValues, parseNull);

    ite.Destroy();
    reader.Destroy();
end;

// ------------------------------------------------- To* methods -----------------------------------------------------------

function querystringT.toQuerystring(encode: Boolean): string;
begin
    if((self.qsKeys = nil) or ((self.qsKeys <> nil) and (self.qsKeys.Count = 0))) then
    begin
        raise Exception.Create('querystring is empty or nil');
        exit;
    end;

    try
        var i: integer;
        var buffer: string := '';

        for i := 0 to qsKeys.Count-1 do                                             // for every pair
        begin
            if i <> 0 then                                                          // add ampersand '&' for every element except the first one
                buffer := buffer + '&';

            if encode then                                                          // if encoded needed
            begin
                buffer := buffer +                                                  // add pair
                httpUtilsT.percentEncode(qsKeys.Items[i],false) + '=' +     
                httpUtilsT.percentEncode(qsValues.Items[i],false);           
            end
            else
            begin
                buffer := buffer + qsKeys.Items[i] + '=' + qsValues.Items[i];       // add pair
            end;
        end;

        Result := buffer;
    except
        on E: Exception do raise;
    end;
end;

function querystringT.toQuerystringList(): TStringList;
begin
    if((self.qsKeys = nil) or ((self.qsKeys <> nil) and (self.qsKeys.Count = 0))) then
    begin
        raise Exception.Create('querystring is empty or nil');
        exit;
    end;

    var qs: TStringList := TStringList.Create();

    var i: integer := 0;
    for i := 0 to qsKeys.Count-1 do
    begin
        qs.AddPair(qsKeys.Items[i], qsValues.Items[i]);
    end;
    
    Result := qs;
end;

function querystringT.toJson(parseBool: Boolean; parseNull: Boolean; parseFloats: Boolean; parseIntegers: Boolean): string;
begin
    try
        var json := toJsonObject(parseBool, parseNull, parseFloats, parseIntegers);
        Result := json.ToJSON();
        json.Destroy();
    except
        on E: Exception do raise;
    end;
end;

function querystringT.toJsonObject(parseBool: Boolean; parseNull: Boolean; parseFloats: Boolean; parseIntegers: Boolean): TJSONObject;
begin
    if((self.qsKeys = nil) or ((self.qsKeys <> nil) and (self.qsKeys.Count = 0))) then
    begin
        raise Exception.Create('querystring is empty or nil');
        exit;
    end;

    var curParents: TArray<string> := nil;
    var curParentsSize: integer := 0;
    var writter: TJsonObjectWriter := TJsonObjectWriter.Create();
    writter.WriteStartObject();

    // for every path/key=value pair
    var key, value: string;
    var i: integer;
    for i := 0 to qsKeys.Count-1 do
    begin
        var parents: TArray<string> := httpUtilsT.bracketsSplit(qsKeys.Items[i]);   // get parents from querystring name
        var parentsSize: integer := Length(parents);

        if parentsSize <= 0 then
        begin
            continue;
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
    Result := writter.JSON.Clone() as TJSONObject;
    writter.Destroy();
end;

// ------------------------------------------------- Private methods -------------------------------------------------------

class procedure querystringT.writeJsonValue(writter: TJsonWriter; value: string; parseBool: Boolean; parseNull: Boolean; parseFloats: Boolean; parseIntegers: Boolean);
begin
    try
        var parsed: jsonValueT := httpUtilsT.parseJsonValue(value, parseBool, parseNull, parseFloats, parseIntegers);

        case parsed.jsonType of 
            jsonNull: writter.WriteNull();        
            jsonBoolean: writter.WriteValue(parsed.booleanValue);     
            jsonInteger: writter.WriteValue(parsed.integerValue);     
            jsonFloat: writter.WriteValue(parsed.floatValue);       
            jsonString: writter.WriteValue(parsed.stringValue);
        end;     
    except
        on E: Exception do raise;
    end;
end;

class procedure querystringT.jsonToQuerystring(ite: TJSONIterator; keys: TList<string>; values: TList<string>; parseNull: boolean);
begin
    while true do                                                                   // run trough all json tokens
    begin
        if(ite.Next() = false) then                                                 // check for array/object end
        begin
            if(ite.Depth = 0) then break;                                           // end of the json 

            ite.Return();                                                           // else just go up to parent
            continue;                                                               // and try again
        end;

        case ite.&Type of                                                           // we only care about value tokens for the querystring formation
            TJsonToken.StartObject: ite.Recurse();                                  // on object or array, recurse inside
            TJsonToken.StartArray:  ite.Recurse(); 

            TJsonToken.Integer:
            begin
                keys.Add(httpUtilsT.pointsToBrackets(ite.GetPath(0)));
                values.Add(IntToStr(ite.AsInteger));  
            end;

            TJsonToken.Float:
            begin
                keys.Add(httpUtilsT.pointsToBrackets(ite.GetPath(0)));
                values.Add(FloatToStr(ite.AsExtended, TFormatSettings.Create('en-US')));  
            end;

            TJsonToken.&String:
            begin
                keys.Add(httpUtilsT.pointsToBrackets(ite.GetPath(0)));
                values.Add(ite.AsString);  
            end;

            TJsonToken.Boolean:
            begin
                keys.Add(httpUtilsT.pointsToBrackets(ite.GetPath(0)));
                values.Add(LowerCase(BoolToStr(ite.AsBoolean, true)));  
            end;

            TJsonToken.Null:
            begin
                keys.Add(httpUtilsT.pointsToBrackets(ite.GetPath(0)));
                if parseNull then
                    values.Add('null')
                else   
                    values.Add('');
            end;
        end;
    end;
end;

// ------------------------------------------------- Create and destroy ----------------------------------------------------

constructor querystringT.Create();
begin
    inherited Create();
    self.qsKeys := TList<string>.Create();
    self.qsValues := TList<string>.Create();
end;

destructor querystringT.Destroy();
begin
    if qsKeys <> nil then qsKeys.Destroy();
    if qsValues <> nil then qsValues.Destroy();
    inherited Destroy();
end;

end.
