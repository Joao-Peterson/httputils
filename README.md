# querystring - WIP

Utility for handling http querystrings and other http related stuff such as:

1. Querystring parsing
2. Querystring to Json
3. Json to querystring (TODO)
4. Percent encoding and decoding

# Table of contents
- [querystring - WIP](#querystring---wip)
- [Table of contents](#table-of-contents)
- [Usage](#usage)
- [Install](#install)
  - [Using `boss`](#using-boss)
- [TODO](#todo)

# Usage

Include `querystringU` into your project and check out the functions provided.

# Install

## Using `boss`
Just use the following command:

```console
$ boss install lab.srssistemas.com/peterson/querystring
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

# TODO

1. toQuerystring()
2. UTF8 support
3. URIBuilder()
