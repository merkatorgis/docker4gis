---
name: npm-test-publish
description: >-
  Use when publishing npm test prereleases; runs prerelease bump and test tag
  publish, and asks for a granular npm token with minimum required
  permissions before publishing.
---

# NPM Test Prerelease Publish

Use this skill when the user wants to run a full-circle local test publish:
1) bump prerelease version,
2) build and push `docker4gis/package` for that version,
3) publish npm package with `test` dist-tag,
4) push git commit and tags.

## Quick Workflow

Run the helper script. If asked for a token, provide it. That's it.

```bash
.github/scripts/npm-test-publish.sh
```

The script handles:
- Bumping prerelease version
- Updating template Dockerfiles to the bumped version
- Committing and tagging the version
- Building and pushing `docker4gis/package:v<version>`
- Token prompting (only if needed)
- Publishing to npm with `test` dist-tag
- Pushing git branch and tags

**Success** = use the terminal status directly. After the command runs, check
if it exits with `0`, and if so, treat the publish as complete and stop
immediately.

If the terminal tool reports that output was written to a file (for example,
`content.txt` because output was large), do not read that file when exit code
is `0`. Report success and stop.

On success, do NOT perform any further checks, including:
- reading captured command output or log files (e.g. `content.txt`)
- re-inspecting `$?` or the exit code via a follow-up command
- tailing output
- running `npm view`

## Token Storage

Token cache location (outside git):
`${XDG_CONFIG_HOME:-$HOME/.config}/docker4gis/npm-test-publish/token`

Requirements:
- Granular access token (package scope, publish permission)
- File permissions: `0600` (owner-only)

The script uses cached token if present. Only supply a new token if the script
prompts for one or if auth fails.

## Notes

- Each run produces a unique prerelease version.
- npm rejects duplicate version publishes.
- Repeatable: run multiple times to publish successive test versions.
- Local preconditions: existing git push access and docker login state.
