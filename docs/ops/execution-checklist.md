# Execution Checklist

## Phase A (release)

The release is built and published by CI: push the tag, then verify the
artefacts that run produced.

1. Lock says `current` = the upstream version you intend to ship (`python3 tools/ocver.py current`).
2. Tag and push: `git push origin "$(python3 tools/ocver.py tag)"`.
   `publish-native-android.yml` runs the build workflow first, so the released
   files come from that run.
3. Verify the release page: `opencode_<version>-<revision>_aarch64.deb`,
   `opencode-<version>-android-aarch64-bundle.tar.gz`, `SHA256SUMS`, signed
   `Release`/`InRelease`.
4. On device, install both ways and check the runtime:

```sh
pkg install bun
curl -fsSL https://raw.githubusercontent.com/anomalyco/opencode-termux/native-android/install.sh | bash
opencode --version
opencode
```

5. apt path: `pkg install opencode` after the signed source is configured
   (see `docs/ops/apt-repository.md`).
6. Broken release: bump `package_revision` in the lock, tag
   `v<version>-<revision>`, let CI rebuild.

## Phase B (plugin lifecycle)

1. Install the plugin package.
2. Register the plugin file entry and verify.
3. Update the plugin package.
4. Roll back the snapshot if needed.
5. Export or apply local patches when upstream changes break the runtime.
6. If package-mode system skills are used, verify the hook runner log and
   manifest status after install/upgrade.

## Validation

- `./tools/plugin-selfcheck.sh` — environment/plugin read-only check.
- `./tests/run.sh` — shell unit tests.
