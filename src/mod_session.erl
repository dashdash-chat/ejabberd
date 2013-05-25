%%%----------------------------------------------------------------------
%%% File    : mod_session.erl
%%% Author  : Steven Lehrburger <lehrburger@gmail.com>
%%% Purpose : Notify a specific JID when a session is opened for a user.
%%% Created : 25 May 2013 by Steven Lehrburger <lehrburger@gmail.com>
%%%
%%%----------------------------------------------------------------------

-module(mod_session).
-author('lehrburger@gmail.com').

-behaviour(gen_mod).
-include("ejabberd.hrl").
-include("jlib.hrl").

-export([start/2,
         stop/1,
         send_opened_signal/1
        ]).

start(Host, _Opts) ->
    ?DEBUG("mod_session starting: ~s, ~s, ~s", [gen_mod:get_module_opt(Host, ?MODULE, recipient_jid, Host),
                                                gen_mod:get_module_opt(Host, ?MODULE, opened_signal, "default_opened_signal")
                                               ]),
    ejabberd_hooks:add(user_available_hook, Host, ?MODULE, send_opened_signal, 10),
    ok.

stop(Host) ->
    ?INFO_MSG("mod_session stopping", []),
    ejabberd_hooks:delete(user_available_hook, Host, ?MODULE, send_opened_signal, 10),
    ok.

send_opened_signal(#jid{luser = LUser, lserver = LServer}) ->
    Recipient_JID = gen_mod:get_module_opt(LServer, ?MODULE, recipient_jid, LServer),
    Signal        = gen_mod:get_module_opt(LServer, ?MODULE, opened_signal, "default_opened_signal"),
    ?DEBUG("send_opened_signal ~s from ~s to ~s, ~s", [Signal, LServer, Recipient_JID]),
    Packet = build_packet(message_chat, [io_lib:format("~s ~s", [Signal, LUser])]),
    ejabberd_router:route(jlib:string_to_jid(LServer), jlib:string_to_jid(Recipient_JID), Packet),
    none.

%%% This is from https://github.com/lehrblogger/ejabberd-modules/blob/master/mod_admin_extra/trunk/src/mod_admin_extra.erl
build_packet(message_chat, [Body]) ->
    {xmlelement, "message",
     [{"type", "chat"}, {"id", randoms:get_string()}],
     [{xmlelement, "body", [], [{xmlcdata, Body}]}]
    }.
