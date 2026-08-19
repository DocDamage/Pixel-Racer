#!/usr/bin/env python3
"""Deterministic high-res-to-Pixel-Track-Works conversion helper.

The high quality resize is only an intermediate silhouette reduction. Runtime
output is a fixed low-resolution canvas with a bounded palette and explicit
alpha policy; Godot must display the result with nearest-neighbor filtering.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


@dataclass(frozen=True)
class Profile:
    width: int
    height: int
    colors: int
    alpha: str


PROFILES = {
    "terrain": Profile(64, 64, 12, "opaque"),
    "road": Profile(64, 64, 14, "binary"),
    "tree": Profile(48, 48, 18, "binary"),
    "bush": Profile(40, 32, 16, "binary"),
    "rock": Profile(48, 24, 14, "binary"),
    "building": Profile(80, 96, 20, "binary"),
    "lights": Profile(96, 12, 14, "binary"),
    "oil": Profile(36, 18, 10, "binary"),
    "barrel": Profile(22, 24, 14, "binary"),
    "vehicle": Profile(46, 54, 24, "binary"),
    "nitro": Profile(16, 30, 16, "soft"),
    "smoke": Profile(32, 28, 12, "soft"),
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def trim_alpha(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    bounds = rgba.getchannel("A").getbbox()
    return rgba.crop(bounds) if bounds else rgba


def quantize_rgba(image: Image.Image, colors: int) -> Image.Image:
    alpha = image.getchannel("A")
    rgb = Image.new("RGB", image.size, (0, 0, 0))
    rgb.paste(image.convert("RGB"), mask=alpha)
    quantized = rgb.quantize(
        colors=colors,
        method=Image.Quantize.MEDIANCUT,
        dither=Image.Dither.NONE,
    ).convert("RGB")
    return Image.merge("RGBA", (*quantized.split(), alpha))


def apply_alpha_policy(image: Image.Image, policy: str) -> None:
    alpha = image.getchannel("A")
    if policy == "opaque":
        alpha = Image.new("L", image.size, 255)
    elif policy == "binary":
        alpha = alpha.point(lambda value: 255 if value >= 112 else 0)
    elif policy == "soft":
        alpha = alpha.point(
            lambda value: 0 if value < 24 else (255 if value > 232 else value)
        )
    else:
        raise ValueError(f"Unknown alpha policy: {policy}")
    image.putalpha(alpha)


def pixelize(source: Path, destination: Path, profile_name: str) -> dict:
    profile = PROFILES[profile_name]
    with Image.open(source) as source_image:
        image = trim_alpha(source_image)
    scale = min(profile.width / image.width, profile.height / image.height)
    reduced_size = (
        max(1, round(image.width * scale)),
        max(1, round(image.height * scale)),
    )
    reduced = image.resize(reduced_size, Image.Resampling.LANCZOS)
    reduced = quantize_rgba(reduced, profile.colors)
    apply_alpha_policy(reduced, profile.alpha)

    output = Image.new("RGBA", (profile.width, profile.height), (0, 0, 0, 0))
    offset = (
        (profile.width - reduced.width) // 2,
        (profile.height - reduced.height) // 2,
    )
    output.alpha_composite(reduced, offset)
    destination.parent.mkdir(parents=True, exist_ok=True)
    output.save(destination, optimize=True)
    return {
        "conversion_profile": f"{profile_name}_v1",
        "conversion_version": 1,
        "source_path": str(source),
        "source_sha256": sha256(source),
        "output_path": str(destination),
        "output_sha256": sha256(destination),
        "runtime_size": [profile.width, profile.height],
        "palette_budget": profile.colors,
        "alpha_policy": profile.alpha,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--profile", choices=sorted(PROFILES), required=True)
    parser.add_argument("--metadata", type=Path)
    args = parser.parse_args()
    metadata = pixelize(args.source, args.destination, args.profile)
    if args.metadata:
        args.metadata.parent.mkdir(parents=True, exist_ok=True)
        args.metadata.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(metadata, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
