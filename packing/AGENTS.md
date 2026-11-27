# PACKAGING KNOWLEDGE BASE

## OVERVIEW
`packing/` holds only the launcher template. The deb and tarball are assembled
in CI by `scripts/ci/package-release-bundle.sh`; no package output is committed.

## STRUCTURE
```text
packing/
└── launcher/opencode        # launcher template
```

## WHERE TO LOOK
| Task | Location | Notes |
|---|---|---|
| Launcher template | `launcher/opencode` | execs `bun` with the bundled `index.js` |
| Deb metadata | `scripts/ci/package-release-bundle.sh` | control fields and dependencies generated there |

## CONVENTIONS
- The launcher carries `__OPENCODE_VERSION__`; `scripts/materialize-bundle.sh` substitutes it for the deb.
- The bundle's JS carries `@TERMUX_PREFIX@`; the packager and `install.sh` substitute it with the device prefix.
- Declare runtime dependencies (`bun`, `libc++`, `ripgrep`) in the packager, not here.

## ANTI-PATTERNS
- Do not commit generated `.deb` or tarball files.
- Do not add a second launcher copy; `materialize-bundle.sh` is the only template consumer for the deb.
