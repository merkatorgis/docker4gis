# Copilot Instructions

- For npm test publishes, use /npm-test-publish; production publish is handled
	by the DevOps pipeline.
- Publishing is staged, not direct: both flows run `npm stage publish`, and a
	human approves the staged version on npm afterwards. See
	`docs/releasing.md`.
