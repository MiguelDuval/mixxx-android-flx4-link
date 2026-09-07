#!/usr/bin/env python3
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
CONTROLLER = ROOT / "src/controllers/controllermanager.cpp"
OLD_INCLUDE_BLOCK = '''#ifdef __ANDROID__\n// PortMidi is disabled on Android, so the Android USB-MIDI implementation is\n// compiled into this translation unit together with ControllerManager.\n#include "controllers/midi/portmidicontroller.cpp"\n#include "controllers/midi/portmidienumerator.cpp"\n#endif\n'''


def strip_bad_direct_includes() -> bool:
    text = CONTROLLER.read_text(encoding="utf-8")
    if OLD_INCLUDE_BLOCK in text:
        CONTROLLER.write_text(text.replace(OLD_INCLUDE_BLOCK, "", 1), encoding="utf-8")
        return True

    # Also handle the same two includes if the surrounding comment changed.
    new = re.sub(
        r'(?ms)^#ifdef __ANDROID__\s*.*?#include "controllers/midi/portmidicontroller\\.cpp"\s*#include "controllers/midi/portmidienumerator\\.cpp"\s*#endif\s*',
        "",
        text,
        count=1,
    )
    if new != text:
        CONTROLLER.write_text(new, encoding="utf-8")
        return True
    return False


def find_mixxx_lib_cmake():
    candidates = []
    for path in ROOT.rglob("CMakeLists.txt"):
        if any(part in {".git", "build", "buildenv", "build-android"} for part in path.parts):
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        if re.search(r"(?m)^\\s*add_library\\(\\s*mixxx-lib\\b", text):
            candidates.append((path, text))
    if not candidates:
        raise SystemExit("Could not locate the CMake file that creates target mixxx-lib")
    if len(candidates) > 1:
        # Prefer the deepest file: Mixxx normally defines the library in src/CMakeLists.txt.
        candidates.sort(key=lambda item: len(item[0].parts), reverse=True)
    return candidates[0]


def insert_after_add_library(text: str, cmake_path: Path) -> str:
    if "src/controllers/midi/portmidicontroller.cpp" in text or "controllers/midi/portmidicontroller.cpp" in text:
        # The sources may already be present; only remove the Android translation-unit hack.
        return text

    marker = re.search(r"(?m)^\\s*add_library\\(\\s*mixxx-lib\\b", text)
    if not marker:
        raise SystemExit("Could not locate add_library(mixxx-lib ...)")

    depth = 0
    started = False
    end = None
    for i in range(marker.start(), len(text)):
        ch = text[i]
        if ch == "(":
            depth += 1
            started = True
        elif ch == ")" and started:
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    if end is None:
        raise SystemExit("Could not parse add_library(mixxx-lib ...)")

    controller_src = (ROOT / "src/controllers/midi/portmidicontroller.cpp").relative_to(cmake_path.parent).as_posix()
    enumerator_src = (ROOT / "src/controllers/midi/portmidienumerator.cpp").relative_to(cmake_path.parent).as_posix()
    block = (
        "\n\n# Android USB-MIDI backend (PortMidi is disabled on Android).\n"
        "if(ANDROID)\n"
        "  target_sources(mixxx-lib PRIVATE\n"
        f"    {controller_src}\n"
        f"    {enumerator_src}\n"
        "  )\n"
        "endif()"
    )
    return text[:end] + block + text[end:]


def main() -> None:
    changed = strip_bad_direct_includes()
    cmake_path, cmake_text = find_mixxx_lib_cmake()
    patched_cmake = insert_after_add_library(cmake_text, cmake_path)
    if patched_cmake != cmake_text:
        cmake_path.write_text(patched_cmake, encoding="utf-8")
        changed = True

    print(f"ControllerManager direct .cpp includes removed: {changed}")
    print(f"mixxx-lib CMake: {cmake_path.relative_to(ROOT)}")
    print("Android USB-MIDI sources are registered with target_sources()")

    # Fail loudly if the final source state is not what we expect.
    final_controller = CONTROLLER.read_text(encoding="utf-8")
    if "#include \"controllers/midi/portmidicontroller.cpp\"" in final_controller or "#include \"controllers/midi/portmidienumerator.cpp\"" in final_controller:
        raise SystemExit("Direct Android .cpp inclusion is still present in ControllerManager")
    final_cmake = cmake_path.read_text(encoding="utf-8")
    if "target_sources(mixxx-lib PRIVATE" not in final_cmake or "portmidicontroller.cpp" not in final_cmake or "portmidienumerator.cpp" not in final_cmake:
        raise SystemExit("Android MIDI sources were not registered in CMake")


if __name__ == "__main__":
    main()
