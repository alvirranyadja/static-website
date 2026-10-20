#!/usr/bin/env python3
"""Contrôles de sécurité bloquants : secrets, hôtes approuvés, en-têtes, moindre privilège."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEPLOY_HOST = "16.192.253.80"
JENKINS_HOST = "16.192.73.184"
PINNED_ED25519 = "AAAAC3NzaC1lZDI1NTE5AAAAIBHdZKI3q4akl5qNeQ3PIMfvr4b++rXX+6W8jUeLt10Q"

SECRET_PATTERNS = (
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"-----BEGIN (?:RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----"),
    re.compile(r"aws_secret_access_key\s*=", re.IGNORECASE),
    re.compile(r"(?i)(password|passwd|secret)\s*[:=]\s*['\"][^'\"]{8,}['\"]"),
)

REQUIRED_HEADERS = (
    "X-Frame-Options",
    "X-Content-Type-Options",
    "Referrer-Policy",
    "Permissions-Policy",
    "Content-Security-Policy",
)

SKIP_DIRS = {".git", "dist", "images"}
TEXT_SUFFIXES = {".html", ".css", ".js", ".groovy", ".sh", ".conf", ".py", ".txt", ".md"}


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def check_secrets(errors: list[str]) -> None:
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        if SKIP_DIRS.intersection(path.relative_to(ROOT).parts):
            continue
        if path.name.endswith(".min.js") or path.suffix.lower() not in TEXT_SUFFIXES:
            if path.name not in {"Jenkinsfile", "known_hosts", "sudoers-deploy", "reload-static-site"}:
                continue
        if path.stat().st_size > 2_000_000:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for pattern in SECRET_PATTERNS:
            if pattern.search(text):
                fail(errors, f"secret potentiel dans {path.relative_to(ROOT)}")
                break


def check_forbidden_files(errors: list[str]) -> None:
    forbidden_names = {".env", "id_rsa", "credentials.json", "secrets.json"}
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        if ".git" in path.parts or "dist" in path.parts:
            continue
        if path.name in forbidden_names or path.suffix.lower() in {".pem", ".p12", ".key"}:
            fail(errors, f"fichier sensible présent : {path.relative_to(ROOT)}")


def check_approved_hosts(errors: list[str]) -> None:
    jenkinsfile = (ROOT / "Jenkinsfile").read_text(encoding="utf-8")
    if JENKINS_HOST not in jenkinsfile or DEPLOY_HOST not in jenkinsfile:
        fail(errors, "Jenkinsfile ne déclare pas les hôtes approuvés")
    known = (ROOT / "deploy" / "known_hosts").read_text(encoding="utf-8")
    if f"{DEPLOY_HOST} ssh-ed25519 {PINNED_ED25519}" not in known:
        fail(errors, "clé d'hôte du serveur de déploiement absente ou modifiée")
    publish = (ROOT / "ci" / "publish.sh").read_text(encoding="utf-8")
    common = (ROOT / "ci" / "ssh_common.sh").read_text(encoding="utf-8")
    if "ssh_common.sh" not in publish or "StrictHostKeyChecking=yes" not in common:
        fail(errors, "la connexion de déploiement ne vérifie pas la clé d'hôte")
    combined = publish + common
    if "StrictHostKeyChecking=no" in combined or "ssh-keyscan" in combined:
        fail(errors, "le déploiement accepte une clé d'hôte non épinglée")


def check_nginx_headers(errors: list[str]) -> None:
    headers = (ROOT / "deploy" / "nginx" / "security-headers.conf").read_text(encoding="utf-8")
    for name in REQUIRED_HEADERS:
        if name not in headers:
            fail(errors, f"en-tête de sécurité absent : {name}")
    site = (ROOT / "deploy" / "nginx" / "static-website.conf").read_text(encoding="utf-8")
    if "security-headers.conf" not in site:
        fail(errors, "le vhost nginx n'inclut pas les en-têtes de sécurité")


def check_least_privilege(errors: list[str]) -> None:
    sudoers = (ROOT / "deploy" / "sudoers-deploy").read_text(encoding="utf-8").strip()
    expected = "deploy ALL=(root) NOPASSWD: /usr/local/sbin/reload-static-site"
    if sudoers != expected:
        fail(errors, "le sudoers de déploiement n'est plus limité au rechargement nginx")
    if "NOPASSWD: ALL" in sudoers:
        fail(errors, "sudo sans restriction")


def main() -> int:
    errors: list[str] = []
    check_secrets(errors)
    check_forbidden_files(errors)
    check_approved_hosts(errors)
    check_nginx_headers(errors)
    check_least_privilege(errors)
    if errors:
        print(f"Sécurité en échec ({len(errors)}) :", file=sys.stderr)
        for item in errors:
            print(f"  - {item}", file=sys.stderr)
        return 1
    print("Sécurité OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
