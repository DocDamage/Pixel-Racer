#!/usr/bin/env python3
"""Deterministically inventory supplied Pixel Track Works source archives.

This script never edits source archives. It records archive/file hashes, PNG
geometry, exact duplicate relationships, and source-only authoring formats so
runtime selection can be reviewed before anything enters res://.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import zipfile
from collections import defaultdict
from pathlib import Path
from typing import Any

from PIL import Image

AUTHORING_ONLY = {".ai", ".eps", ".psd", ".aseprite", ".scml"}


def sha256_bytes(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def archive_record(path: Path) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    archive_hash = hashlib.sha256(path.read_bytes()).hexdigest()
    files: list[dict[str, Any]] = []
    with zipfile.ZipFile(path) as archive:
        for info in sorted(archive.infolist(), key=lambda item: item.filename.lower()):
            if info.is_dir():
                continue
            payload = archive.read(info)
            suffix = Path(info.filename).suffix.lower()
            record: dict[str, Any] = {
                "archive": path.name,
                "path": info.filename,
                "extension": suffix,
                "bytes": len(payload),
                "sha256": sha256_bytes(payload),
                "authoring_only": suffix in AUTHORING_ONLY,
            }
            if suffix == ".png":
                with Image.open(io.BytesIO(payload)) as image:
                    record.update(
                        {
                            "width": image.width,
                            "height": image.height,
                            "mode": image.mode,
                            "has_alpha": "A" in image.getbands(),
                        }
                    )
            files.append(record)
    return (
        {
            "filename": path.name,
            "sha256": archive_hash,
            "file_count": len(files),
            "png_count": sum(1 for item in files if item["extension"] == ".png"),
            "uncompressed_bytes": sum(int(item["bytes"]) for item in files),
        },
        files,
    )


def build_duplicate_report(files: list[dict[str, Any]]) -> dict[str, Any]:
    by_hash: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for item in files:
        if item["extension"] == ".png":
            by_hash[str(item["sha256"])].append(item)
    groups = []
    for digest, matches in sorted(by_hash.items()):
        archives = {str(match["archive"]) for match in matches}
        if len(matches) < 2 or len(archives) < 2:
            continue
        groups.append(
            {
                "sha256": digest,
                "copies": [
                    {"archive": match["archive"], "path": match["path"]}
                    for match in matches
                ],
            }
        )
    return {"schema_version": 1, "exact_duplicate_groups": groups}


def write_csv(path: Path, files: list[dict[str, Any]]) -> None:
    fields = [
        "archive",
        "path",
        "extension",
        "bytes",
        "sha256",
        "width",
        "height",
        "mode",
        "has_alpha",
        "authoring_only",
    ]
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        for item in files:
            writer.writerow(item)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("archives", nargs="+", type=Path)
    parser.add_argument("--out", type=Path, default=Path("asset_inventory_out"))
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    archive_rows = []
    file_rows: list[dict[str, Any]] = []
    for archive_path in sorted(args.archives, key=lambda path: path.name.lower()):
        archive_row, files = archive_record(archive_path)
        archive_rows.append(archive_row)
        file_rows.extend(files)

    (args.out / "source_archives.json").write_text(
        json.dumps({"schema_version": 1, "archives": archive_rows}, indent=2) + "\n",
        encoding="utf-8",
    )
    (args.out / "asset_manifest.json").write_text(
        json.dumps({"schema_version": 1, "files": file_rows}, indent=2) + "\n",
        encoding="utf-8",
    )
    (args.out / "duplicate_report.json").write_text(
        json.dumps(build_duplicate_report(file_rows), indent=2) + "\n",
        encoding="utf-8",
    )
    write_csv(args.out / "asset_inventory.csv", file_rows)
    print(f"Inventoried {len(file_rows)} files from {len(archive_rows)} archives")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
