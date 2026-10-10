#!/usr/bin/env python3
"""Apply version-locked Android safety guards to OpenTUI 0.5.17."""

import argparse
from pathlib import Path


def replace_exact(path: Path, old: str, new: str, count: int = 1) -> None:
    text = path.read_text(encoding="utf-8")
    actual = text.count(old)
    if actual != count:
        raise SystemExit(
            f"patch-opentui: {path}: expected {count} occurrence(s), found {actual}"
        )
    path.write_text(text.replace(old, new), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("tree", type=Path)
    args = parser.parse_args()
    native = args.tree / "packages" / "native" / "src"
    buffer = native / "buffer.zig"
    renderer = native / "renderer.zig"
    build = args.tree / "packages" / "native" / "build.zig"
    if not buffer.is_file() or not renderer.is_file() or not build.is_file():
        raise SystemExit("patch-opentui: expected packages/native/src source tree")

    replace_exact(
        build,
        """fn addTranslatedCImports(
    b: *std.Build,""",
        """fn addBionicTranslateIncludes(b: *std.Build, step: *std.Build.Step.TranslateC) void {
    if (b.graph.environ_map.get("BIONIC_ARCH_INCLUDE")) |path| {
        step.addSystemIncludePath(.{ .cwd_relative = path });
    }
    if (b.graph.environ_map.get("BIONIC_SYS_INCLUDE")) |path| {
        step.addSystemIncludePath(.{ .cwd_relative = path });
    }
}

fn addTranslatedCImports(
    b: *std.Build,""",
    )
    replace_exact(
        build,
        """    miniaudio_translate.addIncludePath(b.path("src"));
    module.addImport("miniaudio", miniaudio_translate.createModule());""",
        """    miniaudio_translate.addIncludePath(b.path("src"));
    addBionicTranslateIncludes(b, miniaudio_translate);
    module.addImport("miniaudio", miniaudio_translate.createModule());""",
    )
    replace_exact(
        build,
        """    yoga_translate.addIncludePath(yoga_dep.path(""));
    module.addImport("yoga", yoga_translate.createModule());""",
        """    yoga_translate.addIncludePath(yoga_dep.path(""));
    addBionicTranslateIncludes(b, yoga_translate);
    module.addImport("yoga", yoga_translate.createModule());""",
    )

    replace_exact(
        buffer,
        """        return x >= scissor.x and x < scissor.x + @as(i32, @intCast(scissor.width)) and
            y >= scissor.y and y < scissor.y + @as(i32, @intCast(scissor.height));""",
        """        const w = @as(i32, @intCast(@min(scissor.width, 0x7FFFFFFF)));
        const h = @as(i32, @intCast(@min(scissor.height, 0x7FFFFFFF)));
        return x >= scissor.x and x < scissor.x +| w and
            y >= scissor.y and y < scissor.y +| h;""",
    )

    rect_old = """        const rect_end_x = x + @as(i32, @intCast(width));
        const rect_end_y = y + @as(i32, @intCast(height));
        const scissor_end_x = scissor.x + @as(i32, @intCast(scissor.width));
        const scissor_end_y = scissor.y + @as(i32, @intCast(scissor.height));"""
    rect_new = """        const w = @as(i32, @intCast(@min(width, 0x7FFFFFFF)));
        const h = @as(i32, @intCast(@min(height, 0x7FFFFFFF)));
        const sw = @as(i32, @intCast(@min(scissor.width, 0x7FFFFFFF)));
        const sh = @as(i32, @intCast(@min(scissor.height, 0x7FFFFFFF)));
        const rect_end_x = x +| w;
        const rect_end_y = y +| h;
        const scissor_end_x = scissor.x +| sw;
        const scissor_end_y = scissor.y +| sh;"""
    replace_exact(buffer, rect_old, rect_new, count=2)

    replace_exact(
        buffer,
        """        if (virtual_lines.len == 0) return;

        const firstVisibleLine: u32 = if (y < 0) @intCast(-y) else 0;""",
        """        if (virtual_lines.len == 0) return;
        if (y <= -0x40000000) return;

        const firstVisibleLine: u32 = if (y < 0) @intCast(-y) else 0;""",
    )

    replace_exact(
        buffer,
        """        if (posX >= @as(i32, @intCast(self.width)) or posY >= @as(i32, @intCast(self.height))) return;

        const startX: u32 = if (posX < 0) @intCast(-posX) else 0;""",
        """        if (posX >= @as(i32, @intCast(self.width)) or posY >= @as(i32, @intCast(self.height))) return;
        if (posX < -0x40000000 or posY < -0x40000000) return;

        const startX: u32 = if (posX < 0) @intCast(-posX) else 0;""",
        count=2,
    )

    replace_exact(
        renderer,
        "            clipped.x + @as(i32, @intCast(clipped.width)),",
        "            clipped.x +| @as(i32, @intCast(@min(clipped.width, 0x7FFFFFFF))),",
    )
    replace_exact(
        renderer,
        "            clipped.y + @as(i32, @intCast(clipped.height)),",
        "            clipped.y +| @as(i32, @intCast(@min(clipped.height, 0x7FFFFFFF))),",
    )
    replace_exact(renderer, rect_old, rect_new)

    required = (
        (buffer, "@min(scissor.width, 0x7FFFFFFF)"),
        (buffer, "if (y <= -0x40000000) return;"),
        (buffer, "if (posX < -0x40000000 or posY < -0x40000000) return;"),
        (renderer, "@min(clipped.width, 0x7FFFFFFF)"),
        (renderer, "const rect_end_x = x +| w;"),
    )
    for path, marker in required:
        if marker not in path.read_text(encoding="utf-8"):
            raise SystemExit(f"patch-opentui: missing postcondition in {path}: {marker}")
    print("patch-opentui: OpenTUI 0.5.17 Android guards applied")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
