# GitHub Actions Scope

> The file name is historical. CI **is** the release path: release binaries are built in
> Actions from the pinned lock, because a build produced on one phone cannot be reproduced
> or audited by anyone else. The phone is where the candidate is smoke-tested, not where
> release artifacts are made.

## Workflows

| Workflow | Role |
|---|---|
| `build-native-android.yml` | Candidate: builds from `tools/supply-chain-lock.json`, swaps in the bionic OpenTUI lib, verifies the FFI guard, then packages the binary `.tar.gz` plus the APT `.deb` / `Packages.gz` / `Release` candidate. Uploads them as run artifacts. |
| `publish-native-android.yml` | Release: takes a successful candidate run ID, re-verifies provenance (right workflow, success, commit is an ancestor, build inputs unchanged since), re-checks every checksum, then creates the tag and uploads the assets with `RELEASE_NOTES.md` as the body. |
| `tests.yml` | Shell unit tests for build/packaging helpers. Runs on every push. |
| `build-pure-android.yml` | Manual upstream experiment, kept for investigation. Not a release path. |

## Rules

- Publish only from a candidate artifact fetched back from Actions. Never upload a binary
  built on a device.
- Never hand-edit release assets or checksums; if a build is wrong, run a new candidate and
  publish that run.
- Pin workflow actions to immutable commit SHAs.
- aarch64 is the only target. 32-bit was removed.

## What stays local

- On-device smoke test of the candidate before it is published: `--version`, server and
  model listing, TUI, real prompt, clean exit.
- Plugin lifecycle, install/upgrade/downgrade checks, and system-skill hooks on a real
  Termux device.
