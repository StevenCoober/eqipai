%%%-------------------------------------------------------------------
%% @doc eqipai public API
%% @end
%%%-------------------------------------------------------------------

-module(eqipai_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
    eqipai_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================
