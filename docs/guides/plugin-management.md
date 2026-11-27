# Plugin management

OpenCode's own CLI handles plugins: `opencode plugin add/list/check/update/remove`
accepts npm names, Git specs and configured local paths. Use that for general
plugins. `scripts/plugin-manager.sh` is a narrower helper for installing
`oh-my-opencode` from source on Termux, with snapshots and patch recovery.

## What the helper owns

```
config      $XDG_CONFIG_HOME/opencode/opencode.json
plugins     $XDG_CONFIG_HOME/opencode/local-plugins/<name>/
snapshots   $XDG_CONFIG_HOME/opencode/plugin-snapshots/
state       $XDG_CONFIG_HOME/opencode/plugin-manager-state.json
```

It clones the plugin repo, builds it with `bun run` or `npm`, registers the
entry as a `file://` path in the config, and snapshots the config before each
mutation. Network failures are retried.

## Commands

```sh
./scripts/plugin-manager.sh install [name] [repo-url]
./scripts/plugin-manager.sh update [name]
./scripts/plugin-manager.sh list-snapshots [name]
./scripts/plugin-manager.sh rollback [name] [snapshot-file]
./scripts/plugin-manager.sh patch-export [name]
./scripts/plugin-manager.sh patch-apply [name] <patch-file>
./scripts/plugin-manager.sh verify-config [port]
```

Default name is `oh-my-opencode`, default repo is
`https://github.com/code-yeongyu/oh-my-opencode.git`.

`migrate-installed [name]` also exists, but it targets
`$PREFIX/lib/opencode/plugins/<name>/index.js`. This build no longer installs
system plugins there, so that command is legacy.

## Recovery model

1. `update` takes a config snapshot before changing anything.
2. If an update breaks the plugin, `rollback` restores the latest snapshot.
3. For a local fix, edit the cloned plugin and use `patch-export` to save a diff.
4. After a future upstream update, `patch-apply` re-applies the saved diff.

## Caveats

- The script writes the legacy singular `"plugin"` config key. OpenCode 2.3.2
  reads `"plugins"`, so entries written by this helper may need translating by
  hand before OpenCode picks them up.
- oh-my-opencode is a third-party plugin, not part of this build. It is not
  shipped, tested or patched here. Its `@opentui/solid` dependency pulls
  `@opentui/core` 0.5.x, which has no bionic native and predates the loader
  patch applied to this bundle.
- Prefer `opencode plugin add` for any plugin other than this specific source
  install workflow.
