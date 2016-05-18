-module( jira ).
-author( "Warren Kenny <warren.kenny@gmail.com>" ).

-export( [init/4, init/3, url/1, search/3, search/5] ).

-record( state, {   username        :: binary(),
                    password        :: binary(),
                    url             :: binary()
} ).

-type issue() :: map().
-export_type( [issue/0] ).

%%
%%  Initialize a JIRA handle for use in API function calls
%%
-spec init( string(), string(), string(), integer() ) -> #state{}.
init( Username, Password, Host, Port ) ->
    #state{     username    = want:binary( Username ),
                password    = want:binary( Password ),
                url         = want:binary( "https://" ++ Host ++ ":" ++ want:string( Port ) ++ "/rest/api/2" )
    }.
    
-spec init( string(), string(), string() ) -> #state{}.
init( Username, Password, Host ) ->
    init( Username, Password, Host, 443 ).
    
%%
%%  Retrieve the REST API URL for the given state
%%
-spec url( #state{} ) -> string().
url( #state{ url = URL } ) -> URL.

%%
%%  Search for any issues matching the given JQL string, collect all results by traversing all pages returned
%%
-spec search( string(), [binary()], #state{} ) -> { ok, [issue()] } | { error, term() }.
search( JQL, Fields, State ) ->
    search( JQL, Fields, State, 0, 50, 100, [] ).
   
-spec search( string(), [binary()], #state{}, integer(), integer(), integer(), [issue()] ) -> { ok, [issue()] } | { error, term() }.
search( JQL, Fields, State, StartAt, Max, Total, Out ) when StartAt =< Total ->
    case search( JQL, StartAt, Max, Fields, State ) of
        { ok, Issues, NewTotal }    -> search( JQL, Fields, State, StartAt + Max, Max, NewTotal, lists:append( Out, Issues ) );
        { error, Reason }           -> { error, Reason }
    end;
    
search( _JQL, _Fields, _State, StartAt, _Max, Total, Out ) when StartAt > Total ->
    { ok, Out }.
    
%%
%%  Search for any issues matching the given JQL string, starting at the given offset and returning the specified maximum number
%%  of results. On success, returns the total number of results available as well as the list of retrieved issues.
%%
-spec search( string(), integer(), integer(), [binary()], #state{} ) -> { ok, [issue()] } | { error, term() }.
search( JQL, Start, Max, Fields, #state{ username = Username, password = Password, url = BaseURL } ) ->
    Body = #{   jql         => want:binary( JQL ),
                startAt     => Start,
                maxResults  => Max,
                fields      => [ want:binary( F ) || F <- Fields ]                
    },
    Options = [{ basic_auth, { Username, Password } } ],
    URL = want:binary( url:join( BaseURL, [ "search" ] ) ),
    case hackney:post( URL, [{ <<"Content-Type">>, <<"application/json">> }], jsx:encode( Body ), Options ) of
        { ok, 200, _ResponseHeaders, Ref } ->
            { ok, ResponseBody } = hackney:body( Ref ),
            ResponseJSON = jsx:decode( ResponseBody, [ return_maps ] ),
            Total   = maps:get( <<"total">>, ResponseJSON ),
            Issues  = maps:get( <<"issues">>, ResponseJSON ),
            { ok, Issues, Total };
        { ok, Status, _, Ref } ->
            { ok, ErrorBody } = hackney:body( Ref ),
            { error, Status, ErrorBody };
        { error, Reason } ->
            { error, want:binary( Reason ) }
    end.