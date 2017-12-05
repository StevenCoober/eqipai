-module(eqipai_mahjong).

-export([is_hu/1]).

%%%%%%%%%%%%%%%%%%备注%%%%%%%%%%%%%%%%%%%
%%%万：wang
%%%筒：tong
%%%条：tiao
%%%字：zi
%%%比如一筒是#{type => tong, index => 1}
%%%比如六万是#{type => wang, index => 6}
%%%比如八万是#{type => tiao, index => 8}
%%%东是#{type => zi, index => 1}, 南是#{type => zi, index => 2}, 顺序东南西北中发白


%%不带赖子鬼牌
%%N*3 + 2模式
-type mahjong() :: map().
-spec is_hu(L :: list(mahjong())) ->
    R :: {true, _hu_info} | false.
is_hu(Mahjongs) ->
    {_, Multis, Infos} = arrange(Mahjongs),
    is_hu(Multis, Infos).

is_hu([], _) ->
    false;
is_hu([#{type := Type} = Mahjong | Multis], Infos) ->
    empty_triples(),
    put_double(Mahjong),
    TypeMahjongs = maps:get(Type, Infos),
    RemovedMahjongs = remove_double(TypeMahjongs, Mahjong),
    NewInfos = maps:put(Type, RemovedMahjongs, Infos),

    case is_type_hu(maps:to_list(NewInfos)) of
        true -> 
            HuInfo = #{double => get_double(), triples => get_triples()},
            {true, HuInfo};
        false ->
            is_hu(Multis, Infos)
    end.

is_type_hu([]) ->
    true;
is_type_hu([{Type, Mahjongs} | List]) ->
    case is_type_hu(Type, Mahjongs) of
        true -> is_type_hu(List);
        false -> false
    end.

is_type_hu(_, []) ->
    true;
is_type_hu(_, Mahjongs) when length(Mahjongs) rem 3 =/= 0 ->
    false;
is_type_hu(Type, [#{index := Index1 } = First | Mahjongs]) ->
    {Part1, Part2} = lists:split(2, Mahjongs),
    case Part1 == [First, First] of
        true ->
            update_triples({First, First, First}),
            is_type_hu(Type, Part2);
        false ->
            case Type == zi of
                true ->
                    false;
                false ->
                    Second = #{type => Type, index => Index1+1},
                    case lists:delete(Second, Mahjongs) of
                        Mahjongs ->
                            false;
                        RemovedSecondMahjongs ->
                            Third = #{type => Type, index => Index1 +2},
                            case lists:delete(Third, RemovedSecondMahjongs) of
                                RemovedSecondMahjongs ->
                                    false;
                                NewMahjongs ->
                                    update_triples({First, Second, Third}),
                                    is_type_hu(Type, NewMahjongs)
                            end
                    end
            end
    end.

arrange(Mahjongs) ->
    Fun = fun(#{type:= Type} = Mahjong, {LastMahjong, AccMultis, AccInfos}) ->
                  OriTypeMajongs = maps:get(Type, AccInfos, []),
                  TypeMahjongs = OriTypeMajongs ++ [Mahjong],
                  NewAccInfos = maps:put(Type, TypeMahjongs, AccInfos),
                  NewAccMultis = case Mahjong == LastMahjong of
                                     true ->
                                         case lists:member(Mahjong, AccMultis) of
                                             true -> AccMultis;
                                             false -> AccMultis ++ [Mahjong]
                                         end;
                                     false ->
                                         AccMultis
                                 end,
                  {Mahjong, NewAccMultis, NewAccInfos}
          end,
    lists:foldl(Fun, {undefined, [], #{}}, order(Mahjongs)).

order(Mahjongs) ->
    Fun = fun(#{type := Type1, index := Index1}, #{type := Type2, index := Index2}) ->
                  if
                      Type1 == Type2 -> Index1 =< Index2;
                      true -> Type1 > Type2
                  end
          end,
    lists:sort(Fun, Mahjongs).

remove_double(List, Elem) ->
    lists:delete(Elem, lists:delete(Elem, List)).

get_double() ->
    get(eqipai_mahjong_double).

put_double(Mahjong) ->
    put(eqipai_mahjong_double, Mahjong).

empty_triples() ->
    put(eqipai_mahjong_triples, []).

update_triples(Triple) ->
    OriTriples = case get(eqipai_mahjong_triples) of
                     undefined -> [];
                     Triples -> Triples
                 end,
    NewTriples = [Triple | OriTriples],
    put(eqipai_mahjong_triples, NewTriples).

get_triples() ->
    get(eqipai_mahjong_triples).
