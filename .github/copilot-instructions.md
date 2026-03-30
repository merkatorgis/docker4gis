# Copilot Instructions

- In this repository, `dgn` runs the current branch/worktree `docker4gis`
  script for local development of docker4gis itself.
- Prefer a non-global, cwd-resolved `dgn` shell function; do not rely on
  `npm link` or other npm-global mechanisms for parallel worktrees.
- When a user asks about docker4gis command development, first check whether
  `dgn` is available (for example with `type -t dgn`).
- If `dgn` is missing, set it up automatically as an idempotent Bash function
  in `~/.bashrc` that walks up from `$PWD` until it finds `docker4gis`.
- After setup, verify with `dgn pwd` and explicitly tell the user that
  `dgn` is available.
- Keep instruction files wrapped at 80 characters per line.
