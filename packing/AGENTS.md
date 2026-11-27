# PACKAGING KNOWLEDGE BASE

## OVERVIEW
`packing/` holds the launcher template. The deb and tarball are assembled in
CI by `scripts/ci/package-release-bundle.sh`; no package output is committed.

## STRUCTURE
```text
packing/
└── launcher/opencode        # launcher template, @TERMUX_PREFIX@ placeholder
```

## WHERE TO LOOK
| Task | Location | Notes |
|---|---|---|
| Launcher template | `launcher/opencode` | execs `bun` with the bundled entrypoint; placeholder substituted at package time |
| Deb metadata | `scripts/ci/package-release-bundle.sh` | control fields and dependencies are generated there |

## CONVENTIONS
- Keep `@TERMUX_PREFIX@` unsubstituted in the template; the packager replaces it.
- Declare runtime dependencies (`bun`, `libc++`, `ripgrep`) in the packager, not here.

## ANTI-PATTERNS (PACKAGING)
- Do not commit generated `.deb` or tarball files.
- Do not add a second launcher copy; `materialize-bundle.sh` is the only consumer.
