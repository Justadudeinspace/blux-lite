# -*- coding: utf-8 -*-
"""
BLUX Lite — ROM Manager (safe)

Provides curated links to official ROM portals (LineageOS, GrapheneOS) based on
device code. No automatic flashing; printing URLs and checksums guidance only.
"""
from __future__ import annotations
import json, re
import click

LINEAGE = "https://download.lineageos.org/"
GRAPHENE = "https://grapheneos.org/install/"


def register(cli: click.Group) -> None:
    @cli.group(name="roms")
    def roms():
        """ROM info (links only)."""
        pass

    @roms.command("lineage")
    @click.argument("device_code")
    def lineage(device_code: str):
        url = f"{LINEAGE}{device_code}"
        click.echo(url)

    @roms.command("graphene")
    def graphene():
        click.echo(GRAPHENE)

    @roms.command("notes")
    def notes():
        click.echo(
            "Always verify SHA256 checksums/signatures from official portals before flashing."
        )
