When creating components for a project, I want their directories prefixed by the
`$DOCKER-USER` value (i.e. the project's name), so that we can read the
project's name from the component directory's name when we have an IDE open with
just one of the components. So for project `dgtest` we would get
`/components/dgtest-^package`, `/components/dgtest-proxy`,
`/components/dgtest-app`, etc.