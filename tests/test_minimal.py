import subprocess
import sys


def test_minimal_app_runs():
    result = subprocess.run(
        [sys.executable, "minimal/app.py"],
        capture_output=True,
        text=True,
        timeout=10,
    )
    assert result.returncode == 0
    assert "Lightwell Python Demo" in result.stdout
    assert "cryptography" not in result.stderr


def test_minimal_app_output_contains_sql(capfd):
    result = subprocess.run(
        [sys.executable, "minimal/app.py"],
        capture_output=True,
        text=True,
        timeout=10,
    )
    assert "SELECT" in result.stdout
    assert "sqlparse" in result.stdout


def test_minimal_app_output_contains_pdf():
    result = subprocess.run(
        [sys.executable, "minimal/app.py"],
        capture_output=True,
        text=True,
        timeout=10,
    )
    assert "PyPDF2" in result.stdout
