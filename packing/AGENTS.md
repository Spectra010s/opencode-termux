# PACKAGING KNOWLEDGE BASE

## OVERVIEW
`packing/` mixes source templates/manifests with generated package outputs. Keep edits confined to source-of-truth files.

## STRUCTURE
```text
packing/
├── deb/DEBIAN/control                # template metadata (source-of-truth)
├── deb-standalone/DEBIAN/control     # rollback package metadata
├── launcher/opencode                 # bundle launcher template
├── manifests/system-skills/*.json    # hook/system-skill policy manifests
├── dpkg/*.deb                        # generated outputs (do not edit)
└── dpkg/work/                        # generated staging tree (do not edit)
```

## WHERE TO LOOK
| Task | Location | Notes |
|---|---|---|
| Deb control metadata | `deb/DEBIAN/control` | placeholder-based template consumed during package build |
| Hook manifests/policy | `manifests/system-skills/*.json` | events, compatibility gates, idempotency policy |

## CONVENTIONS
- Treat deb control templates and manifests as editable source.
- Keep package post-install/upgrade hook behavior aligned with safe defaults.

## ANTI-PATTERNS (PACKAGING)
- Do not edit generated paths: `dpkg/work/`, `dpkg/*.deb`, versioned packages.
- Do not hardcode one-off local paths into templates intended for staged-prefix packaging.
- Do not bypass runtime/launcher presence checks before packaging.
