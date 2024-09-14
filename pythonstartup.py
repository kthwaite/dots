"""Python startup script.

This script is executed on startup of the Python interpreter.
"""

import re
from pathlib import Path
from typing import Any, Generator, List

HOME = Path("~").expanduser()

try:
    from rich import pretty, traceback

    pretty.install()
    traceback.install(show_locals=True)
except ImportError:
    pass


def iter_findattr(
    obj: Any, expr: str, include_magic: bool = False
) -> Generator[str, None, None]:
    """Iterate over attributes of an object, yielding names matching a regular
    expression.
    """
    attrs = dir(obj)
    if not include_magic:
        attrs = [a for a in attrs if not a.startswith("__")]
    for attr in attrs:
        if re.search(expr, attr) is not None:
            yield attr


def findattr(obj: Any, expr: str, include_magic: bool = False) -> List[str]:
    """Locate an attribute by regular expression."""
    return list(iter_findattr(obj, expr, include_magic))
