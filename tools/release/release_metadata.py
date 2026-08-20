#!/usr/bin/env python3
"""Validate and emit Pixel Track Works release metadata.

The version in project.godot is authoritative. Windows resource metadata,
artifact names, and release manifests are derived from that value.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROJECT_FILE = ROOT / "project.godot"
EXPORT_PRESETS_FILE = ROOT / "export_presets.cfg"
MAIN_SCENE_FILE = ROOT / "scenes/main/main.tscn"

VERSION_PATTERN = re.compile(
    r"^(?P<major>0|[1-9]\d*)\."
    r"(?P<minor>0|[1-9]\d*)\."
    r"(?P<patch>0|[1-9]\d*)"
    r"(?:-(?P<prerelease>[0-9A-Za-z.-]+))?"
    r"(?:\+(?P<build>[0-9A-Za-z.-]+))?$"
)

REQUIRED_BUNDLE_SOURCES = {
    "README.md": ROOT / "README.md",
    "QUICK_START.md": ROOT / "docs/QUICK_START.md",
    "RELEASE_NOTES.md": ROOT / "docs/RELEASE_NOTES_1.0.0_RC_DRAFT.md",
    "ASSET_ATTRIBUTION.md": ROOT / "docs/ASSET_ATTRIBUTION.md",
}
BASE_BUNDLE_FILES = {
    "PixelTrackWorks.exe",
    *REQUIRED_BUNDLE_SOURCES.keys(),
    "VERSION.txt",
    "RELEASE_MANIFEST.json",
}


class MetadataError(RuntimeError):
    """Raised when release metadata or a release archive is inconsistent."""


def _read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError as exc:
        raise MetadataError(f"Could not read {path.relative_to(ROOT)}: {exc}") from exc


def _quoted_setting(text: str, key: str, source: Path) -> str:
    pattern = re.compile(rf'^{re.escape(key)}="([^"]*)"$', re.MULTILINE)
    match = pattern.search(text)
    if match is None:
        raise MetadataError(f"Missing {key} in {source.relative_to(ROOT)}")
    return match.group(1)


def project_version() -> str:
    version = _quoted_setting(_read_text(PROJECT_FILE), "config/version", PROJECT_FILE).strip()
    if VERSION_PATTERN.fullmatch(version) is None:
        raise MetadataError(
            f"application/config/version is not valid semantic version text: {version!r}"
        )
    return version


def windows_file_version(version: str) -> str:
    match = VERSION_PATTERN.fullmatch(version)
    if match is None:
        raise MetadataError(f"Cannot derive Windows version from {version!r}")
    prerelease = match.group("prerelease") or ""
    numeric_tokens = re.findall(r"\d+", prerelease)
    revision = int(numeric_tokens[-1]) if numeric_tokens else 0
    parts = (
        int(match.group("major")),
        int(match.group("minor")),
        int(match.group("patch")),
        revision,
    )
    if any(part > 65535 for part in parts):
        raise MetadataError("Windows file-version components must be <= 65535")
    return ".".join(str(part) for part in parts)


def safe_version(version: str) -> str:
    value = re.sub(r"[^0-9A-Za-z._-]+", "-", version).strip("-")
    if not value:
        raise MetadataError("Version produced an empty artifact-safe value")
    return value


def expected_names(version: str) -> dict[str, str]:
    safe = safe_version(version)
    stem = f"PixelTrackWorks-{safe}-Windows-x64"
    return {
        "version": version,
        "safe_version": safe,
        "file_version": windows_file_version(version),
        "archive": f"{stem}.zip",
        "artifact": stem,
    }


def validate() -> dict[str, str]:
    version = project_version()
    expected = expected_names(version)
    export_text = _read_text(EXPORT_PRESETS_FILE)
    product_version = _quoted_setting(
        export_text, "application/product_version", EXPORT_PRESETS_FILE
    )
    file_version = _quoted_setting(
        export_text, "application/file_version", EXPORT_PRESETS_FILE
    )
    errors: list[str] = []
    if product_version != version:
        errors.append(
            "export_presets.cfg application/product_version is "
            f"{product_version!r}; expected {version!r}"
        )
    if file_version != expected["file_version"]:
        errors.append(
            "export_presets.cfg application/file_version is "
            f"{file_version!r}; expected {expected['file_version']!r}"
        )
    for packaged_name, source in REQUIRED_BUNDLE_SOURCES.items():
        if not source.is_file():
            errors.append(
                f"required bundle source for {packaged_name} is missing: "
                f"{source.relative_to(ROOT)}"
            )
    main_scene = _read_text(MAIN_SCENE_FILE)
    if "res://scripts/release/release_self_test.gd" not in main_scene:
        errors.append("main scene does not wire scripts/release/release_self_test.gd")
    if 'name="ReleaseSelfTest"' not in main_scene:
        errors.append("main scene does not instantiate the ReleaseSelfTest node")
    if errors:
        raise MetadataError("\n".join(errors))
    return expected


def write_github_output(metadata: dict[str, str]) -> None:
    output_path = os.environ.get("GITHUB_OUTPUT", "").strip()
    if not output_path:
        raise MetadataError("GITHUB_OUTPUT is not set")
    with Path(output_path).open("a", encoding="utf-8") as handle:
        for key in ("version", "safe_version", "file_version", "archive", "artifact"):
            handle.write(f"{key}={metadata[key]}\n")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def _validated_sha(value: str, label: str) -> str:
    normalized = value.strip().lower()
    if not re.fullmatch(r"[0-9a-f]{40}", normalized):
        raise MetadataError(f"{label} must be a full 40-character Git SHA")
    return normalized


def bundle_files() -> list[str]:
    files = set(BASE_BUNDLE_FILES)
    if (ROOT / "LICENSE").is_file():
        files.add("LICENSE")
    return sorted(files)


def write_manifest(
    metadata: dict[str, str],
    executable: Path,
    output: Path,
    source_commit: str,
    ci_commit: str,
    godot_version: str,
) -> None:
    if not executable.is_file():
        raise MetadataError(f"Executable is missing: {executable}")
    payload = {
        "schema_version": 1,
        "product_name": "Pixel Track Works",
        "version": metadata["version"],
        "windows_file_version": metadata["file_version"],
        "release_state": "development" if "-" in metadata["version"] else "release",
        "source_commit": _validated_sha(source_commit, "Source commit"),
        "ci_commit": _validated_sha(ci_commit, "CI commit"),
        "godot_version": godot_version.strip(),
        "platform": "windows-x64",
        "executable": {
            "path": "PixelTrackWorks.exe",
            "size_bytes": executable.stat().st_size,
            "sha256": sha256_file(executable),
        },
        "bundle_files": bundle_files(),
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _read_checksum(path: Path) -> str:
    try:
        first_line = path.read_text(encoding="utf-8").splitlines()[0]
    except (OSError, IndexError) as exc:
        raise MetadataError(f"Could not read checksum file {path}: {exc}") from exc
    value = first_line.split()[0].strip().lower()
    if not re.fullmatch(r"[0-9a-f]{64}", value):
        raise MetadataError(f"Checksum file does not start with a SHA-256 digest: {path}")
    return value


def verify_archive(metadata: dict[str, str], archive: Path) -> None:
    if archive.name != metadata["archive"]:
        raise MetadataError(
            f"Archive name is {archive.name!r}; expected {metadata['archive']!r}"
        )
    if not archive.is_file():
        raise MetadataError(f"Archive is missing: {archive}")
    checksum_path = archive.with_name(f"{archive.name}.sha256")
    if not checksum_path.is_file():
        raise MetadataError(f"Archive checksum is missing: {checksum_path}")
    actual_archive_hash = sha256_file(archive)
    recorded_archive_hash = _read_checksum(checksum_path)
    if actual_archive_hash != recorded_archive_hash:
        raise MetadataError("Archive checksum does not match the downloaded ZIP")

    try:
        with zipfile.ZipFile(archive, "r") as release_zip:
            bad_member = release_zip.testzip()
            if bad_member is not None:
                raise MetadataError(f"ZIP integrity test failed at {bad_member}")
            names = sorted(name for name in release_zip.namelist() if not name.endswith("/"))
            expected_files = bundle_files()
            if names != expected_files:
                raise MetadataError(
                    f"Bundle files differ from the release contract. actual={names}, "
                    f"expected={expected_files}"
                )
            manifest = json.loads(release_zip.read("RELEASE_MANIFEST.json"))
            version_text = release_zip.read("VERSION.txt").decode("utf-8").strip()
            executable = release_zip.read("PixelTrackWorks.exe")
    except (OSError, zipfile.BadZipFile, KeyError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise MetadataError(f"Could not inspect release archive: {exc}") from exc

    if version_text != metadata["version"]:
        raise MetadataError(
            f"VERSION.txt contains {version_text!r}; expected {metadata['version']!r}"
        )
    if manifest.get("version") != metadata["version"]:
        raise MetadataError("Release manifest version does not match project.godot")
    if manifest.get("windows_file_version") != metadata["file_version"]:
        raise MetadataError("Release manifest Windows version does not match export metadata")
    if manifest.get("platform") != "windows-x64":
        raise MetadataError("Release manifest platform is not windows-x64")
    if sorted(manifest.get("bundle_files", [])) != bundle_files():
        raise MetadataError("Release manifest bundle file list does not match ZIP contents")
    _validated_sha(str(manifest.get("source_commit", "")), "Manifest source commit")
    _validated_sha(str(manifest.get("ci_commit", "")), "Manifest CI commit")
    executable_manifest = manifest.get("executable", {})
    if executable_manifest.get("path") != "PixelTrackWorks.exe":
        raise MetadataError("Release manifest executable path is invalid")
    if executable_manifest.get("size_bytes") != len(executable):
        raise MetadataError("Release manifest executable size does not match ZIP content")
    if executable_manifest.get("sha256") != sha256_bytes(executable):
        raise MetadataError("Release manifest executable hash does not match ZIP content")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subcommands = parser.add_subparsers(dest="command", required=True)
    subcommands.add_parser("check")
    subcommands.add_parser("github-output")
    manifest = subcommands.add_parser("manifest")
    manifest.add_argument("--executable", required=True, type=Path)
    manifest.add_argument("--output", required=True, type=Path)
    manifest.add_argument("--source-commit", required=True)
    manifest.add_argument("--ci-commit", required=True)
    manifest.add_argument("--godot-version", default="4.7.1")
    archive = subcommands.add_parser("verify-archive")
    archive.add_argument("--archive", required=True, type=Path)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        metadata = validate()
        if args.command == "check":
            print(
                "Release metadata: "
                f"version={metadata['version']} "
                f"file_version={metadata['file_version']} "
                f"archive={metadata['archive']}"
            )
        elif args.command == "github-output":
            write_github_output(metadata)
        elif args.command == "manifest":
            write_manifest(
                metadata,
                args.executable,
                args.output,
                args.source_commit,
                args.ci_commit,
                args.godot_version,
            )
        elif args.command == "verify-archive":
            verify_archive(metadata, args.archive)
            print(f"Release archive verified: {args.archive}")
        return 0
    except MetadataError as exc:
        print(f"release metadata error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
