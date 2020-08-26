# `prop.erl.tpl` from rebar3 proper plugin
define tpl_prop
-module($(n)).
-include_lib("proper/include/proper.hrl").

%%%%%%%%%%%%%%%%%%
%%% Properties %%%
%%%%%%%%%%%%%%%%%%
prop_test() ->
    ?FORALL(Type, term(),
        begin
            boolean(Type)
        end).

%%%%%%%%%%%%%%%
%%% Helpers %%%
%%%%%%%%%%%%%%%
boolean(_) -> true.

%%%%%%%%%%%%%%%%%%
%%% Generators %%%
%%%%%%%%%%%%%%%%%%
mytype() -> term().
endef

# `prop_fsm.erl.tpl` from rebar3 proper plugin
define tpl_prop_fsm
-module($(n)).
-include_lib("proper/include/proper.hrl").

-export([initial_state/0, initial_state_data/0,
         on/1, off/1, service/3, % State generators
         weight/3, precondition/4, postcondition/5, next_state_data/5]).

prop_test() ->
    ?FORALL(Cmds, proper_fsm:commands(?MODULE),
        begin
            actual_system:start_link(),
            {History,State,Result} = proper_fsm:run_commands(?MODULE, Cmds),
            actual_system:stop(),
            ?WHENFAIL(io:format("History: ~p\nState: ~p\nResult: ~p\n",
                                [History,State,Result]),
                      aggregate(zip(proper_fsm:state_names(History),
                                    command_names(Cmds)),
                                Result =:= ok))
        end).

-record(data, {}).

%% Initial state for the state machine
initial_state() -> on.
%% Initial model data at the start. Should be deterministic.
initial_state_data() -> #data{}.

%% State commands generation
on(_Data) -> [{off, {call, actual_system, some_call, [term(), term()]}}].

off(_Data) ->
    [{off, {call, actual_system, some_call, [term(), term()]}},
     {history, {call, actual_system, some_call, [term(), term()]}},
     { {service,sub,state}, {call, actual_system, some_call, [term()]}}].

service(_Sub, _State, _Data) ->
    [{on, {call, actual_system, some_call, [term(), term()]}}].

%% Optional callback, weight modification of transitions
weight(_FromState, _ToState, _Call) -> 1.

%% Picks whether a command should be valid.
precondition(_From, _To, #data{}, {call, _Mod, _Fun, _Args}) -> true.

%% Given the state states and data *prior* to the call
%% `{call, Mod, Fun, Args}', determine if the result `Res' (coming
%% from the actual system) makes sense.
postcondition(_From, _To, _Data, {call, _Mod, _Fun, _Args}, _Res) -> true.

%% Assuming the postcondition for a call was true, update the model
%% accordingly for the test to proceed.
next_state_data(_From, _To, Data, _Res, {call, _Mod, _Fun, _Args}) ->
    NewData = Data,
    NewData.
endef

# `prop_statem.erl.tpl` from rebar3 proper plugin$
define tpl_prop_statem
-module($(n)).
-include_lib("proper/include/proper.hrl").

%% Model Callbacks
-export([command/1, initial_state/0, next_state/3,
         precondition/2, postcondition/3]).

%%%%%%%%%%%%%%%%%%
%%% PROPERTIES %%%
%%%%%%%%%%%%%%%%%%
prop_test() ->
    ?FORALL(Cmds, commands(?MODULE),
            begin
                actual_system:start_link(),
                {History, State, Result} = run_commands(?MODULE, Cmds),
                actual_system:stop(),
                ?WHENFAIL(io:format("History: ~p\nState: ~p\nResult: ~p\n",
                                    [History,State,Result]),
                          aggregate(command_names(Cmds), Result =:= ok))
            end).

%%%%%%%%%%%%%
%%% MODEL %%%
%%%%%%%%%%%%%
%% @doc Initial model value at system start. Should be deterministic.
initial_state() ->
    #{}.

%% @doc List of possible commands to run against the system
command(_State) ->
    oneof([
        {call, actual_system, some_call, [term(), term()]}
    ]).

%% @doc Determines whether a command should be valid under the
%% current state.
precondition(_State, {call, _Mod, _Fun, _Args}) ->
    true.

%% @doc Given the state `State' *prior* to the call
%% `{call, Mod, Fun, Args}', determine whether the result
%% `Res' (coming from the actual system) makes sense.
postcondition(_State, {call, _Mod, _Fun, _Args}, _Res) ->
    true.

%% @doc Assuming the postcondition for a call was true, update the model
%% accordingly for the test to proceed.
next_state(State, _Res, {call, _Mod, _Fun, _Args}) ->
    NewState = State,
    NewState.
endef
