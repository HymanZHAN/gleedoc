-module(gleedoc_line_ffi).
-export([separator/0]).

separator() ->
    case os:type() of
        {win32, _} -> <<"\r\n">>;
        _          -> <<"\n">>
    end.
