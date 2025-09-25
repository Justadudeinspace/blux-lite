# -*- coding: utf-8 -*-

import logging, logging.config, json, os


def setup_logging(root: str):
    cfgp = os.path.join(root, ".config", "blux-lite-gold", "logging.json")
    try:
        with open(cfgp, "r") as f:
            logging.config.dictConfig(json.load(f))
    except Exception:
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
        )
    return logging.getLogger("blux.orchestrator")
