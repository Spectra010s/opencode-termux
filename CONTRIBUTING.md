# Contributing

## Branching

The default branch is **`native-android`**. It is the only branch that ships, and it is what `origin/HEAD` points at. Open every pull request against it.

```
native-android          <- default, release line, protected in practice
  feat/<thing>          <- your work
```

- Branch off `native-android`, keep the branch focused, and open the PR back into `native-android`.
- Prefix names with `feat/`, `fix/`, `docs/` or `chore/`. Longer-lived trains use `rc*/` or `archive/` as the existing branches do.
- Do not force-push `native-android`; rewrite your own branch instead.
- The `archive/`, `glibc`, `rc6-*` and `test-*` branches are historical. Leave them alone; do not base new work on them.

## What this project ships

One Android/aarch64 Bionic ELF for Termux. No PRoot, no glibc, no wrapper in the runtime path. The wrapper line exists as `opencode-wrapper` appendix packaging only, and it stays out of the mainline.

## Ground rules

- **aarch64 only.** Do not add a 32-bit (armv7/arm32) target or re-introduce its scripts; that track failed and was removed.
- **Pinned inputs.** Versions, commits and hashes live in [`tools/supply-chain-lock.json`](tools/supply-chain-lock.json), read through [`tools/ocver.py`](tools/ocver.py). Never hardcode a version in a script, workflow or installer — read it from the lock. A version bump means a new lock entry, not an edit to existing pins.
- **Do not edit generated output.** `artifacts/`, `packing/dpkg/work/`, `packing/pacman/pkg/` and versioned packages are build products.
- **Actions are pinned** to immutable commit SHAs with the version in a trailing comment. Use the v6 line where it exists.
- **Shell scripts** use `set -euo pipefail` and fail fast on missing binaries or files.

## Testing

```sh
make selfcheck          # local consistency checks
```

The **Unit Tests** workflow runs the `bats` suite on every push and pull request. Release builds are not part of PR CI: they are dispatched by hand through `build-native-android.yml`, which builds the Bionic OpenTUI library, bundles the pinned source for `bun`, cross-builds the native libraries, and produces an unsigned candidate artifact.

A change to the build pipeline is not done until that workflow is green. A change to the runtime is not done until the candidate runs on a real device: `--version`, TUI, auth, one real prompt, clean exit.

## Releases

Releases are published from CI, never from a maintainer machine:

1. `build-native-android.yml` with `strategy: bundle` produces the candidate plus one `SHA256SUMS` file.
2. The candidate is smoke-tested on a device.
3. Pushing the version tag (`git tag v2.2.7 && git push origin v2.2.7`) makes `publish-native-android.yml` find the successful candidate for that commit, verify its checksums, and publish it with [`.release/v<version>.md`](.release) as the release notes. The tag must match `current` in the lock.

Do not upload a locally built binary. Do not tag a release that has no verified CI artifact behind it.

## Documentation

Docs are grouped by purpose under [`docs/`](docs/):

| Folder | Contents |
|---|---|
| `guides/` | How to build, install, migrate, manage plugins |
| `reference/` | How the pipeline works, contracts, design notes |
| `ops/` | Runbooks and maintainer operations |
| `history/` | Superseded material, kept for archaeology |

When behaviour and docs disagree, fix the doc in the same change as the code. When you add or move a workflow-critical document, update the [`docs/README.md`](docs/README.md) index and the root [`AGENTS.md`](AGENTS.md) map.

Documents written in Chinese are kept as-is because their evidence trails are still cited.
