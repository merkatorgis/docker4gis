---
name: npm-test-publish
description: >-
  Use when publishing npm test prereleases; runs prerelease bump and test tag
  publish, and asks for a granular npm token with minimum required
  permissions before publishing.
---

# NPM Test Prerelease Publish

Use this skill when the user wants to publish a test build to npm using the
`test` dist-tag.

## Quick Workflow

Run the helper script. If asked for a token, provide it. That's it.

```bash
.github/scripts/npm-test-publish.sh
```

The script handles:
- Bumping prerelease version
- Token prompting (only if needed)
- Publishing to npm with `test` dist-tag

**Success** = npm publish command completes without error.

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
