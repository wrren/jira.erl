## jira.erl

JIRA client library for Erlang. Currently only supports JQL issue searching and basic authentication.

## Rebar Installation

Add the following to your rebar.config:

```erlang
{ jira, ".*",	{ git, "git://github.com/wrren/jira.erl.git", { branch, "master" } } }
```

## Running Tests

Copy ```test/test.config.example``` to ```test/test.config``` and fill in your JIRA credentials and host details. The
Common Test for searching requires a valid project name under which to search for issues, fill this in under the
```jira_project``` key. Use of a non-existent project will cause an error to be thrown.

```erlang
rebar compile
rebat eunit ct
```

## Examples

```erlang

%% Initialize a JIRA handle
State = jira:init( "username", "password", "jira.example.com" ),

JQL = "project = WEB",
StartAt = 0,
MaxResults = 25,
GetFields = [ "summary", "assignee" ],

%% Get paginated results
{ ok, Issues, TotalResults } = jira:search( JQL, StartAt, MaxResults, Fields, State ),

%% Get all results through repeated requests
{ ok, AllIssues } = jira:search( JQL, Fields, State ).

```