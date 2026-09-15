# Releasing the docker4gis package

Publishing the `docker4gis` npm package is a two-step process: the
pipeline **stages** a release, and a human **approves** it. A green
pipeline does not put the version on the registry.

## Why staged publishing

The npm API token the pipeline uses is not allowed to publish directly.
npm's staged publishing exists for exactly that case: it accepts the
tarball without proof-of-presence (2FA) and holds it in a staging area,
deferring the 2FA step to whoever approves it later. So the pipeline runs
`npm stage publish` instead of `npm publish`.

Staged publishing needs **npm 11.15.0 or newer** (first bundled with Node
24.18). Both pipelines pin Node 24 and `npm@^11.15.0`; do the same
locally, or `npm stage` will not exist.

## What the pipeline does

`azure-pipeline-continuous-integration.yml` runs on `master` and calls
`base/publish_docker4gis_version.sh` with `PUBLISH_MODE=release`, which:

1. bumps the patch version and updates the template Dockerfiles,
2. commits and tags that version,
3. builds and pushes `docker4gis/package:v<version>`,
4. runs `npm stage publish`,
5. pushes the commit and tags.

After a green run, the git tag and the Docker image are live, but the npm
version is only staged. Nobody installing `docker4gis` gets it yet.

## Approving a staged release

You need npm 11.15.0 or newer, and an npm account with publish rights on
the package and 2FA enabled:

```
npm --version                   # must be >= 11.15.0
npm whoami                      # log in with `npm login` if this fails
```

Then list what is waiting, and approve it:

```
npm stage list docker4gis       # shows the stage ids
npm stage view <stage-id>       # optional: inspect the metadata
npm stage download <stage-id>   # optional: inspect the tarball
npm stage approve <stage-id>    # publishes it; prompts for your OTP
```

`npm stage approve <stage-id> --otp <code>` skips the prompt.

Confirm the result with `npm view docker4gis version`.

## Rejecting a staged release

```
npm stage reject <stage-id>
```

This removes the staged version; it is never published. Note that the
version bump is already committed and tagged on `master` at that point,
so a rejected release burns that version number — the next pipeline run
bumps to the next patch rather than retrying the rejected one.

## Test prereleases

`.github/scripts/npm-test-publish.sh` (the `/npm-test-publish` skill) runs
the same script with `PUBLISH_MODE=test`, so it stages too — with the
`test` dist-tag. A staged prerelease is not installable via
`npm install docker4gis@test` until it is approved the same way:

```
npm stage list docker4gis
npm stage approve <stage-id>
```

## When the publish fails

`publish_docker4gis_version.sh` propagates npm's exit status, so a failed
stage fails the pipeline step. Two cases are called out in the log:

- `Provided NPM token is not authorized.` (exit code 11) — the token is
  missing, expired, or lacks publish permission on the package. Rotate
  `NPM_TOKEN` in the pipeline's variables, or pass a fresh token to the
  test-publish script.
- `npm publish failed with exit status <n>.` — anything else; npm's own
  output above it says what went wrong.

Steps 1-3 above have already run when the stage fails, so the version
bump, the tag and the Docker image may exist for a version that was never
staged. Re-running the pipeline bumps to the next patch version.
