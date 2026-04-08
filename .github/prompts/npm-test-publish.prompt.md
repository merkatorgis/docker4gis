---
description: >-
  Publish an npm test prerelease with cached token handling and publish to the
  test tag.
---

Use the npm-test-publish skill.

Goal:
- Publish a test prerelease to npm safely.

Required behavior:
- Ask for minimum capabilities only: package publish for the target package.
- Recommend short expiry and no broader scopes than needed.
- Do not print the full token in chat output.
- Store token outside git at:
  `${XDG_CONFIG_HOME:-$HOME/.config}/docker4gis/npm-test-publish/token`
- Reuse stored token and only re-ask when missing or invalid.

Then execute:

```bash
.github/scripts/npm-test-publish.sh
```

Finally verify:

```bash
npm view <package-name> versions --json
npm view <package-name> dist-tags --json
```
