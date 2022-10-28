﻿unit testsU;

{$I ../modules/dunitx/Source/DUnitX.Stacktrace.inc}

interface

uses
    Dunitx.TestFramework;

type

    [TestFixture]
    querystringTestT = class
        [Test]
        [TestCase('Case 1', '../../test-empty.http,../../test-empty.json,true')]
        [TestCase('Case 2', '../../test-malformed.http,../../test-malformed.json,true')]
        [TestCase('Case 3', '../../test-random1.http,../../test-random1.json,true')]
        [TestCase('Case 4', '../../test-random2.http,../../test-random2.json,true')]
        [TestCase('Case 5', '../../test-random3.http,../../test-random3.json,true')]
        [TestCase('Case 6', '../../test-full.http,../../test-full.json,true')]
        [TestCase('Case 7', '../../test-single.http,../../test-single.json,false')]
        [TestCase('Case 8', '../../test-simple.http,../../test-simple.json,false')]
        [TestCase('Case 9', '../../test-empty-value.http,../../test-empty-value.json,false')]
        procedure toJsonTest(querystringFile: string; expectedJsonFile: string; parse: string);
        
        [Test]
        [TestCase('Case 1', ':/?#[]@!$&''()*+;=% ,%3A%2F%3F%23%5B%5D%40%21%24%26%27%28%29%2A%2B%3B%3D%25%20,Encoding all URI special chars,true')]
        procedure percentEncodingTest(input: string; expected: string; msg: string; isuri: string);

        [TestCase('Case 1', '%3A%2F%3F%23%5B%5D%40%21%24%26%27%28%29%2A%2B%3B%3D%25%20,:/?#[]@!$&''()*+;=% ,Decoding from all URI special chars,true')]
        [TestCase('Case 2', '%3A%2F%3F%23%5B%5D%40%21%24%26%27%28%29%2A%2B%3B%3D%25+,:/?#[]@!$&''()*+;=% ,Decoding from all URI special chars with + symbol for application/x-www-form-urlencoded,false')]
        procedure percentDecodingTest(input: string; expected: string; msg: string; isuri: string);

        [Test]
        [TestCase('Case null 1', 'null,0')]
        [TestCase('Case null 2', ',0')]
        [TestCase('Case bool 1', 'true,1')]
        [TestCase('Case bool 2', 'false,1')]
        [TestCase('Case integer 1', '+2132,2')]
        [TestCase('Case integer 2', '-242421,2')]
        [TestCase('Case integer 3', '0,2')]
        [TestCase('Case integer 4', '-0,2')]
        [TestCase('Case integer 5', '+0,2')]
        [TestCase('Case integer 6', '2147483647,2')]
        [TestCase('Case integer 7', '2147483648,4')]
        [TestCase('Case float 1', '-0.3E+4,3')]
        [TestCase('Case float 2', '-435.3324E-12,3')]
        [TestCase('Case float 3', '-.3545e+32,3')]
        [TestCase('Case float 4', '+.3545e-32,3')]
        [TestCase('Case float 5', '+059094.3545e-32,3')]
        [TestCase('Case float 6', '+05903545e-32,3')]
        [TestCase('Case float 7', '0.432,3')]
        [TestCase('Case float 8', '.432,3')]
        [TestCase('Case float 9', '0.432e454,3')]
        [TestCase('Case float 10', '0.432e+4,3')]
        [TestCase('Case float 11', '.432E54,3')]
        [TestCase('Case string 1', '0.432+454,4')]
        [TestCase('Case string 2', '.,4')]
        [TestCase('Case string 3', '-,4')]
        [TestCase('Case string 4', '+,4')]
        [TestCase('Case string 5', '}1G.t8;T_F$WSH*#j*@[>jw Z#=Vrv&UfR8&36O0Z~%a[xC1#Y,4')]
        [TestCase('Case string 6', '%Gb#21HIX%ZkKfEe8Kk_kVcN:d!"bJLZ\+gmc)=)U!2{mO#ES.,4')]
        [TestCase('Case string 7', '3P7RhyY=*2n "^}tn|$h0ZPx@Z8yo0Y;*Kn!|)b|5G^J}q4Y/=,4')]
        procedure parseJsonValueTest(value: string; tp: string);
    end;

implementation

{ testsT }

uses
    querystringU,
    System.Classes,
    System.SysUtils,
    System.IOUtils;

procedure querystringTestT.toJsonTest(querystringFile: string; expectedJsonFile: string; parse: string);
var
    qs: querystringT;
    query: string;
    jsonRes: string;
    json: string;
    i: integer;
begin

    var parsebool: boolean := parse.compareTo('true') = 0;

    try
        query := TFile.ReadAllText(querystringFile);
        jsonRes := TFile.ReadAllText(expectedJsonFile);

        qs := querystringT.Create(query);

        json := qs.toJson(parsebool,parsebool,parsebool,parsebool);

        Assert.AreEqual(jsonRes, json);
        
        qs.Destroy();
    except
        on E: exception do
        begin
            raise Exception.Create('Error toJson() for file: ' + querystringFile + '. Exception: ' + E.Message);
        end;
    end;
end;

procedure querystringTestT.percentEncodingTest(input: string; expected: string; msg: string; isuri: string);
begin
    var uri: boolean := isuri.compareTo('true') = 0; 
    try
        Assert.AreEqual(expected, querystringT.percentEncode(input, uri),msg);
    except
        on E: exception do raise;
    end;
end;

procedure querystringTestT.percentDecodingTest(input: string; expected: string; msg: string; isuri: string);
begin
    var uri: boolean := isuri.compareTo('true') = 0; 
    try
        Assert.AreEqual(expected, querystringT.percentDecode(input, uri),msg);
    except
        on E: exception do raise;
    end;
end;

procedure querystringTestT.parseJsonValueTest(value: string; tp: string);
begin
    var res: jsonValueT;
    var resEx: jsonValueTypeEnum := jsonValueTypeEnum(strtoint(tp));

    res := querystringT.parseJsonValue(value);

    Assert.AreEqual(resEx, res.jsonType);
end;

//procedure querystringTestT.URIBuilderTest;
//begin
//    try
//        Assert.AreEqual(querystringT.percentEncode('http://localhost/foo/bar.html?fizz=buzz#readme'), 'http://localhost/foo/bar.html?fizz=buzz#readme', 'when url contains only allowed characters should keep URL the same');
//        Assert.AreEqual(querystringT.percentEncode('http://[::1]:8080/foo/bar'), 'http://[::1]:8080/foo/bar', 'when url contains only allowed characters should not touch IPv6 notation');
//        Assert.AreEqual(querystringT.percentEncode('http://localhost/\nsnow.html'), 'http://localhost/%0Asnow.html', 'when url contains invalid raw characters should encode LF');
//        Assert.AreEqual(querystringT.percentEncode('http://localhost/\fsnow.html'), 'http://localhost/%0Csnow.html', 'when url contains invalid raw characters should encode FF');
//        Assert.AreEqual(querystringT.percentEncode('http://localhost/\rsnow.html'), 'http://localhost/%0Dsnow.html', 'when url contains invalid raw characters should encode CR');
//        Assert.AreEqual(querystringT.percentEncode('http://localhost/ snow.html'), 'http://localhost/%20snow.html', 'when url contains invalid raw characters should encode SP');
//        Assert.AreEqual(querystringT.percentEncode('http://localhost/\0snow.html'), 'http://localhost/%00snow.html', 'when url contains invalid raw characters should encode NULL');
//        Assert.AreEqual(querystringT.percentEncode('/\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f'), '/%00%01%02%03%04%05%06%07%08%09%0A%0B%0C%0D%0E%0F', 'when url contains invalid raw characters should encode all expected characters from ASCII set');
//        Assert.AreEqual(querystringT.percentEncode('/\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f'), '/%10%11%12%13%14%15%16%17%18%19%1A%1B%1C%1D%1E%1F', 'when url contains invalid raw characters should encode all expected characters from ASCII set');
//        Assert.AreEqual(querystringT.percentEncode('/\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f'), '/%20!%22#$%25&''()*+,-./', 'when url contains invalid raw characters should encode all expected characters from ASCII set');
//        Assert.AreEqual(querystringT.percentEncode('/\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f'), '/0123456789:;%3C=%3E?', 'when url contains invalid raw characters should encode all expected characters from ASCII set');
//        Assert.AreEqual(querystringT.percentEncode('/\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f'), '/@ABCDEFGHIJKLMNO', 'when url contains invalid raw characters should encode all expected characters from ASCII set');
//        Assert.AreEqual(querystringT.percentEncode('/\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f'), '/PQRSTUVWXYZ[%5C]%5E_', 'when url contains invalid raw characters should encode all expected characters from ASCII set');
//        Assert.AreEqual(querystringT.percentEncode('/\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f'), '/%60abcdefghijklmno', 'when url contains invalid raw characters should encode all expected characters from ASCII set');
//        Assert.AreEqual(querystringT.percentEncode('/\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f'), '/pqrstuvwxyz%7B%7C%7D~%7F', 'when url contains invalid raw characters should encode all expected characters from ASCII set');
//        Assert.AreEqual(querystringT.percentEncode('/\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f'), '/%C2%80%C2%81%C2%82%C2%83%C2%84%C2%85%C2%86%C2%87%C2%88%C2%89%C2%8A%C2%8B%C2%8C%C2%8D%C2%8E%C2%8F', 'when url contains invalid raw characters should encode all characters above ASCII as UTF-8 sequences');
//        Assert.AreEqual(querystringT.percentEncode('/\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f'), '/%C2%90%C2%91%C2%92%C2%93%C2%94%C2%95%C2%96%C2%97%C2%98%C2%99%C2%9A%C2%9B%C2%9C%C2%9D%C2%9E%C2%9F', 'when url contains invalid raw characters should encode all characters above ASCII as UTF-8 sequences');
//        Assert.AreEqual(querystringT.percentEncode('/\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf'), '/%C2%A0%C2%A1%C2%A2%C2%A3%C2%A4%C2%A5%C2%A6%C2%A7%C2%A8%C2%A9%C2%AA%C2%AB%C2%AC%C2%AD%C2%AE%C2%AF', 'when url contains invalid raw characters should encode all characters above ASCII as UTF-8 sequences');
//        Assert.AreEqual(querystringT.percentEncode('/\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf'), '/%C2%B0%C2%B1%C2%B2%C2%B3%C2%B4%C2%B5%C2%B6%C2%B7%C2%B8%C2%B9%C2%BA%C2%BB%C2%BC%C2%BD%C2%BE%C2%BF', 'when url contains invalid raw characters should encode all characters above ASCII as UTF-8 sequences');
//        Assert.AreEqual(querystringT.percentEncode('/\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf'), '/%C3%80%C3%81%C3%82%C3%83%C3%84%C3%85%C3%86%C3%87%C3%88%C3%89%C3%8A%C3%8B%C3%8C%C3%8D%C3%8E%C3%8F', 'when url contains invalid raw characters should encode all characters above ASCII as UTF-8 sequences');
//        Assert.AreEqual(querystringT.percentEncode('/\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf'), '/%C3%90%C3%91%C3%92%C3%93%C3%94%C3%95%C3%96%C3%97%C3%98%C3%99%C3%9A%C3%9B%C3%9C%C3%9D%C3%9E%C3%9F', 'when url contains invalid raw characters should encode all characters above ASCII as UTF-8 sequences');
//        Assert.AreEqual(querystringT.percentEncode('/\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef'), '/%C3%A0%C3%A1%C3%A2%C3%A3%C3%A4%C3%A5%C3%A6%C3%A7%C3%A8%C3%A9%C3%AA%C3%AB%C3%AC%C3%AD%C3%AE%C3%AF', 'when url contains invalid raw characters should encode all characters above ASCII as UTF-8 sequences');
//        Assert.AreEqual(querystringT.percentEncode('/\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff'), '/%C3%B0%C3%B1%C3%B2%C3%B3%C3%B4%C3%B5%C3%B6%C3%B7%C3%B8%C3%B9%C3%BA%C3%BB%C3%BC%C3%BD%C3%BE%C3%BF', 'when url contains invalid raw characters should encode all characters above ASCII as UTF-8 sequences');
//        Assert.AreEqual(querystringT.percentEncode('http://localhost/%20snow.html'), 'http://localhost/%20snow.html', 'when url contains percent-encoded sequences should not encode the "%" character');
//        Assert.AreEqual(querystringT.percentEncode('http://localhost/%F0snow.html'), 'http://localhost/%F0snow.html', 'when url contains percent-encoded sequences should not care if sequence is valid UTF-8');
//        Assert.AreEqual(querystringT.percentEncode('http://localhost/%foo%bar%zap%'), 'http://localhost/%25foo%bar%25zap%25', 'when url contains percent-encoded sequences should encode the "%" if not a valid sequence');
//        Assert.AreEqual(querystringT.percentEncode('http://localhost/\uD83D\uDC7B snow.html'), 'http://localhost/%F0%9F%91%BB%20snow.html', 'when url contains raw surrogate pairs should encode pair as UTF-8 byte sequences');
//        Assert.AreEqual(querystringT.percentEncode('http://localhost/\uD83Dfoo\uDC7B <\uDC7B\uD83D>.html'), 'http://localhost/%EF%BF%BDfoo%EF%BF%BD%20%3C%EF%BF%BD%EF%BF%BD%3E.html', 'when url contains raw surrogate pairs when unpaired should encode as replacement character');
//        Assert.AreEqual(querystringT.percentEncode('http://localhost/\uD83D'), 'http://localhost/%EF%BF%BD', 'when url contains raw surrogate pairs when unpaired should encode at end of string');
//        Assert.AreEqual(querystringT.percentEncode('\uDC7Bfoo'), '%EF%BF%BDfoo', 'when url contains raw surrogate pairs when unpaired should encode at start of string');
//
//    except
//        on E: exception do raise;
//    end;
//end;

initialization
    TDUnitX.RegisterTestFixture(querystringTestT);
end.
