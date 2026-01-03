"""
Tests for pymischooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pymischooldata
    assert pymischooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pymischooldata
    assert hasattr(pymischooldata, 'fetch_enr')
    assert callable(pymischooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pymischooldata
    assert hasattr(pymischooldata, 'get_available_years')
    assert callable(pymischooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pymischooldata
    assert hasattr(pymischooldata, '__version__')
    assert isinstance(pymischooldata.__version__, str)
