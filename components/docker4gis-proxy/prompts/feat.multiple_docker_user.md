# We need to support "old application names".

## DOCKER_USER_LEGACY list

In
/home/wouter/github.com/wscherphof/docker4gis/components/docker4gis-proxy/goproxy/main.go,
I need a dockerUserLegacy string array variable that reads from an optional
DOCKER_USER_LEGACY env var contaning a CSV string with a list of zero or more
values.

Where we do `app := requestParts[1]`, if the value is in the list of
dockerUserLegacy values, it should be replaced with the dockerUser value.

Update the readme to include this new feature.
