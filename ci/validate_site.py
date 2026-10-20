#!/usr/bin/env python3
"""Contrôles du site statique avant empaquetage. Bibliothèque standard uniquement."""

from __future__ import annotations

import re
import sys
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = (
    "index.html",
    "error/index.html",
    "assets/css/main.css",
    "assets/css/ie9.css",
    "assets/css/noscript.css",
    "assets/css/font-awesome.min.css",
    "assets/js/jquery.min.js",
    "assets/js/skel.min.js",
    "assets/js/util.js",
    "assets/js/main.js",
    "assets/fonts/fontawesome-webfont.woff2",
    "images/bg.jpg",
    "images/overlay.png",
    "images/pic01.jpg",
    "images/pic02.jpg",
    "images/pic03.jpg",
)

SECRET_PATTERNS = (
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"-----BEGIN (?:RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----"),
    re.compile(r"aws_secret_access_key\s*=", re.IGNORECASE),
    re.compile(r"(?i)api[_-]?key\s*[:=]\s*['\"][A-Za-z0-9_\-]{16,}['\"]"),
)

CSS_URL = re.compile(r"url\(\s*['\"]?([^)'\"]+)['\"]?\s*\)", re.IGNORECASE)
CSS_IMPORT = re.compile(
    r"@import\s+(?:url\(\s*)?['\"]?([^)'\";]+)['\"]?\s*\)?",
    re.IGNORECASE,
)
SKIP_PREFIXES = ("http://", "https://", "//", "data:", "mailto:", "javascript:", "#")


class LinkParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.refs: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = {key: value for key, value in attrs}
        for key in ("href", "src"):
            value = values.get(key)
            if value:
                self.refs.append(value.strip())


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def strip_css_noise(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    text = re.sub(r"'[^']*'", "''", text)
    text = re.sub(r'"[^"]*"', '""', text)
    return text


def local_target(raw: str) -> str | None:
    value = raw.strip().strip("'\"")
    if not value or value.startswith(SKIP_PREFIXES):
        return None
    value = value.split("#", 1)[0].split("?", 1)[0].strip()
    if not value or value.startswith(SKIP_PREFIXES):
        return None
    return value


def resolve_ref(html_file: Path, raw: str) -> Path | None:
    target = local_target(raw)
    if target is None:
        return None
    if target.startswith("/"):
        return ROOT / target.lstrip("/")
    return (html_file.parent / target).resolve()


def check_required(errors: list[str]) -> None:
    for relative in REQUIRED_FILES:
        path = ROOT / relative
        if not path.is_file():
            fail(errors, f"fichier obligatoire absent : {relative}")


def check_html(errors: list[str]) -> None:
    for html_file in sorted(ROOT.rglob("*.html")):
        if "dist" in html_file.parts:
            continue
        text = html_file.read_text(encoding="utf-8", errors="replace")
        lowered = text.lower()
        for marker in ("<html", "</html>", "<head", "</head>", "<body", "</body>", "<title"):
            if marker not in lowered:
                fail(errors, f"{html_file.relative_to(ROOT)} : balise manquante ({marker})")
        parser = LinkParser()
        parser.feed(text)
        for ref in parser.refs:
            resolved = resolve_ref(html_file, ref)
            if resolved is None:
                continue
            try:
                resolved.relative_to(ROOT)
            except ValueError:
                fail(errors, f"{html_file.relative_to(ROOT)} : lien hors du site ({ref})")
                continue
            if not resolved.is_file():
                fail(
                    errors,
                    f"{html_file.relative_to(ROOT)} : ressource introuvable ({ref})",
                )


def check_css(errors: list[str]) -> None:
    for css_file in sorted((ROOT / "assets" / "css").glob("*.css")):
        text = css_file.read_text(encoding="utf-8", errors="replace")
        cleaned = strip_css_noise(text)
        if cleaned.count("{") != cleaned.count("}"):
            fail(errors, f"{css_file.relative_to(ROOT)} : accolades CSS déséquilibrées")

        refs = CSS_URL.findall(text) + CSS_IMPORT.findall(text)
        for ref in refs:
            target = local_target(ref)
            if target is None:
                continue
            resolved = (css_file.parent / target).resolve()
            try:
                resolved.relative_to(ROOT)
            except ValueError:
                fail(errors, f"{css_file.relative_to(ROOT)} : url hors du site ({ref})")
                continue
            if not resolved.is_file():
                fail(errors, f"{css_file.relative_to(ROOT)} : url introuvable ({ref})")


def check_secrets(errors: list[str]) -> None:
    candidates = [ROOT / "index.html", ROOT / "Jenkinsfile"]
    candidates.extend((ROOT / "error").rglob("*.html"))
    candidates.extend((ROOT / "assets").rglob("*.css"))
    candidates.extend((ROOT / "assets").rglob("*.js"))
    candidates.extend((ROOT / "ci").rglob("*"))
    candidates.extend((ROOT / "deploy").rglob("*"))
    seen: set[Path] = set()
    for path in candidates:
        if not path.is_file() or path in seen:
            continue
        seen.add(path)
        if path.stat().st_size > 2_000_000:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for pattern in SECRET_PATTERNS:
            if pattern.search(text):
                fail(errors, f"secret potentiel dans {path.relative_to(ROOT)}")
                break


def main() -> int:
    errors: list[str] = []
    check_required(errors)
    check_html(errors)
    check_css(errors)
    check_secrets(errors)
    if errors:
        print(f"Validation en échec ({len(errors)}) :", file=sys.stderr)
        for item in errors:
            print(f"  - {item}", file=sys.stderr)
        return 1
    print("Validation OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
