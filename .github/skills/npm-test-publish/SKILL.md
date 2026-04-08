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

## Required Safety Prompt

Before running publish commands, ensure a granular npm access token is
available with the minimum required capabilities.

Request this explicitly:
- Token type: granular access token
- Package scope: only the target package
- Permissions: publish package versions
- Optional: short expiration

Never hardcode tokens in files.
Never echo a full token in responses.

Token cache location (outside git):
- `${XDG_CONFIG_HOME:-$HOME/.config}/docker4gis/npm-test-publish/token`
- File permissions must remain owner-only (`0600`)
- Re-prompt only when the token is missing or authentication fails

## Workflow

Run the project helper script:

```bash
.github/scripts/npm-test-publish.sh
```

The script does this:
- Bumps prerelease version without creating a git tag or commit
- Uses cached token when present
- Prompts for token only when missing or auth fails
- Retries publish once after replacing an invalid token

Then verify what was published:

```bash
npm view <package-name> versions --json
npm view <package-name> dist-tags --json
```

## Notes

- npm does not allow publishing the same version twice.
- Each run must produce a unique prerelease version.
- If publish fails with an auth error, verify token scope and permissions.
