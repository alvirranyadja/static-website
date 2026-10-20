#!/usr/bin/env python3
"""Tests d'acceptance du site construit. Chaque test est nommé et indépendant."""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "dist" / "build"
INDEX = (BUILD / "index.html").read_text(encoding="utf-8") if (BUILD / "index.html").is_file() else ""
ERROR = (
    (BUILD / "error" / "index.html").read_text(encoding="utf-8")
    if (BUILD / "error" / "index.html").is_file()
    else ""
)


def accueil_contient_les_sections() -> None:
    for section in ("intro", "work", "about", "contact"):
        if f'id="{section}"' not in INDEX:
            raise AssertionError(f"section absente : {section}")
    if "Dimension" not in INDEX:
        raise AssertionError("titre Dimension absent")


def formulaire_de_contact_complet() -> None:
    for field in ("name", "email", "message"):
        if f'id="{field}"' not in INDEX:
            raise AssertionError(f"champ absent : {field}")
    if 'type="submit"' not in INDEX:
        raise AssertionError("bouton d'envoi absent")


def page_erreur_autonome() -> None:
    if "Page not found" not in ERROR:
        raise AssertionError("message 404 absent")
    if 'href="/assets/css/main.css"' not in ERROR:
        raise AssertionError("la page 404 ne charge pas le CSS depuis la racine")


def medias_obligatoires_presents() -> None:
    required = (
        "images/bg.jpg",
        "images/overlay.png",
        "images/pic01.jpg",
        "images/pic02.jpg",
        "images/pic03.jpg",
        "assets/css/main.css",
        "assets/js/main.js",
    )
    for relative in required:
        if not (BUILD / relative).is_file():
            raise AssertionError(f"média absent du build : {relative}")


def build_produit_un_manifeste() -> None:
    path = BUILD / "build-info.json"
    if not path.is_file():
        raise AssertionError("build-info.json absent")
    info = json.loads(path.read_text(encoding="utf-8"))
    expected = {
        "name": "static-website",
        "jenkinsHost": "16.192.73.184",
        "deployHost": "16.192.253.80",
    }
    for key, value in expected.items():
        if info.get(key) != value:
            raise AssertionError(f"{key} = {info.get(key)!r}, attendu {value!r}")
    for key in ("build", "commit", "libraryVersion"):
        if not str(info.get(key, "")).strip():
            raise AssertionError(f"{key} vide")


def build_ne_publie_pas_le_pipeline() -> None:
    for forbidden in ("Jenkinsfile", "ci", "deploy", "vars", "src"):
        if (BUILD / forbidden).exists():
            raise AssertionError(f"le build contient {forbidden}")


def liens_internes_resolus() -> None:
    script = ROOT / "ci" / "validate_site.py"
    spec = importlib.util.spec_from_file_location("validate_site", script)
    if spec is None or spec.loader is None:
        raise AssertionError("validate_site.py introuvable")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    if module.main() != 0:
        raise AssertionError("des liens HTML ou CSS sont cassés")


TESTS = (
    accueil_contient_les_sections,
    formulaire_de_contact_complet,
    page_erreur_autonome,
    medias_obligatoires_presents,
    build_produit_un_manifeste,
    build_ne_publie_pas_le_pipeline,
    liens_internes_resolus,
)


def main() -> int:
    if not (BUILD / "index.html").is_file():
        print("Build absent. Lancez ci/build.sh avant les tests d'acceptance.", file=sys.stderr)
        return 1
    failed = 0
    for test in TESTS:
        try:
            test()
        except Exception as exc:
            failed += 1
            print(f"FAIL {test.__name__} : {exc}")
        else:
            print(f"PASS {test.__name__}")
    print(f"{len(TESTS) - failed}/{len(TESTS)} tests d'acceptance réussis")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
