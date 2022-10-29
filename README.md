# httpUtils

Utility for handling http querystrings and other http related stuff such as:

1. Querystring parsing
2. Querystring to Json
3. Json to querystring
4. Percent encoding and decoding
5. Queristring nested bracket notation utils
6. Json value generic parsing from string

# Table of contents
- [httpUtils](#httputils)
- [Table of contents](#table-of-contents)
- [Install](#install)
	- [Using `boss`](#using-boss)
- [Usage](#usage)
	- [querystring](#querystring)
		- [From querystring](#from-querystring)
		- [From json](#from-json)
		- [To querystring](#to-querystring)
		- [To querystringList](#to-querystringlist)
		- [To json](#to-json)
		- [To jsonObject](#to-jsonobject)
	- [httpUtils](#httputils-1)
		- [percent encoding](#percent-encoding)
		- [querystring brackets](#querystring-brackets)
		- [json value parsing](#json-value-parsing)
- [Tests](#tests)
- [Error handling](#error-handling)
- [TODO](#todo)

# Install

## Using `boss`
Just use the following command:

```console
$ boss install github.com/Joao-Peterson/httputils
```

If asked for permission, you can login with your gitlab credentials. **(must be done in powershell or cmd with administrator mode)**
```console
$ boss login
> Url to login (ex: github.com): lab.srssistemas.com
> Use SSH(y or n):
> n
> Username: your_username
> Password: your_password
```

Note: ssh isn't supported, hence the **'n'** for not using ssh. See this issue with boss: https://github.com/HashLoad/boss/issues/52.

# Usage

## querystring

Start by including including `querystringU.pas`.

A querystring is a `&` delimited string with key/value pairs that is [percent/url encoded](#percent-encoding) and is usually present in the http URI:

```http
http://site.com?key=value&key2=value2&encodedvalue=%20%3A%2F%
```

Or inside the body of a `Content-Type: x-www-form-urlencoded` http request:
```http
http://site.com
Content-Type: x-www-form-urlencoded

Body:
key=value&key2=value2&encodedvalue=+%3A%2F%
```

With the `queristringT` class you can easly parse this kind of data to multiple formats, including **JSON**!.

### From querystring

```pascal
var qs: querystringT := querystringT.Create();
qs.parseQuerystring('key=value&key2=value2&encodedvalue=+%3A%2F%');
```

### From json

```pascal
var qs: querystringT := querystringT.Create();
qs.parseJson('{"key":"value","key2":"value2","encodedvalue":" :/"', true);
```

Or from a JsonObject:

```pascal
var json := TJSONObject.ParseJSONValue('{"key":"value","key2":"value2","encodedvalue":" :/"') as TJSONObject;
var qs: querystringT := querystringT.Create();
qs.parseJson(json, true);
```

The last argument refeers to as how the json `null` should be interpeted. 
If `true` then value: `"null"`
If `false` then value: `""`

### To querystring

```pascal
var qs: string := qs.toQuerystring(true);
```

Where the `true` sets the output to be [percent/url encoded](#percent-encoding).

### To querystringList

Can be used to access key/values pair.

```pascal
var qs: TStringList := qs.toQuerystringList(true);

WriteLN(qs.Keys[0]);
WriteLN(qs.Values['key1']);
WriteLN(qs.ValuesByIndex['0']);
```

Where the `true` sets the output to be [percent/url encoded](#percent-encoding).

### To json

Notes:

1. Nested values in querystring form are of the form `value[child][grandchild]=42`. 
2. Nested values are converted to nested json objects. `{"value":{"child":{"grandchild": 42}}}`. 
3. Nested values with numbers are converted to arrays. `value[1][grandchild]=42` -> `{"value":["grandchild": 42]}`. 
4. Sometimes the conversion from querystring to json to querystring again can be not equal, that's because compromisses are made in order to achieved a more natural json, no value will be lost, but if a name contains illegal characters it may be parsed as a separator, so the json will be generated differently and consequentially the new querystring.

```pascal
var json: string := qs.toJson(true, true, true, true);
```

Where the 4 arguments are:
```pascal
parseBool: Boolean = true      // define if 'true' and 'false' should be parsed from string to Boolean if true
parseNull: Boolean = true      // define if 'null' should be parsed from '' to 'null' if true
parseFloats: Boolean = true    // define if a float should be parsed from a string to Extended if true
parseIntegers: Boolean = true  // define if a integer should be parsed from a string to Integer if true
```

### To jsonObject

```pascal
var json: TJSONObject := qs.toJsonObject(true, true, true, true);
```

Where the 4 arguments are:
```pascal
parseBool: Boolean = true      // define if 'true' and 'false' should be parsed from string to Boolean if true
parseNull: Boolean = true      // define if 'null' should be parsed from '' to 'null' if true
parseFloats: Boolean = true    // define if a float should be parsed from a string to Extended if true
parseIntegers: Boolean = true  // define if a integer should be parsed from a string to Integer if true
```

## httpUtils

Start by including including `httpUtilsU.pas`.

This utils are for handling miscellaneous http related tasks, feel free to read about them, they might be useful for your use case.

All methods are `class` ones.

### percent encoding

```pascal
var encoded: string := httpUtilsT.percentEncode(input, true);
```

The second boolean is for switching the `URI`/`x-www-form-urlencoded` type, the difference is:

```pascal
uri:        ' ' = '%20'
urlencoded: ' ' = '+'
```

Decoded is of the same form:

```pascal
var decoded: string := httpUtilsT.percentDecode(encoded, true);
```

### querystring brackets

substitute points on a string for '[' and ']'. Ex: 'a.b.c' -> 'a[b][c]'
```pascal
class function pointsToBrackets(input: string): string;
```

substitute brackets on a string for '.'. Ex: 'a[b][c]' -> 'a.b.c'
```pascal
class function bracketsToPoints(input: string): string;
```

split a string by brackets. Ex: 'a[b][c]' -> '(a, b, c)'
```pascal
class function bracketsSplit(input: string): TArray<String>;
```

### json value parsing

Given a string that may contain a json standard value, such as `true`, `null` or `-23.45E+5`, this function can parse the value from a string to the correct type using a `record` with `case`:

```pascal
var parsed: jsonValueT := httpUtilsT.parseJsonValue(valueString, true, true, true, true);

case parsed.jsonType of 
    jsonNull: 													// indicates a null value;        
    jsonBoolean:	var num: boolean 	:= parsed.booleanValue; // access boolean value      
    jsonInteger:	var num: integer 	:= parsed.integerValue; // access integer value      
    jsonFloat:  	var num: extended 	:= parsed.floatValue;   // access extended value       
    jsonString: 	var num: string 	:= parsed.stringValue;  // access string value  
end;     
```

# Tests

Tests are done by the [testsU.pas](test/testsU.pas) file using [DunitX](https://github.com/VSoftTechnologies/DUnitX), or rather, a fork i made that uses boss to be installed. 

# Error handling

Just use `try-exception` blocks.

# TODO

1. URIBuilder()
