import os
import stat
import subprocess

SCRIPTS_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "scripts")


def test_all_scripts_are_executable():
    for name in os.listdir(SCRIPTS_DIR):
        if name.endswith(".sh"):
            path = os.path.join(SCRIPTS_DIR, name)
            mode = os.stat(path).st_mode
            assert mode & stat.S_IXUSR, f"{name} is not executable"


def test_all_scripts_have_shebang():
    for name in os.listdir(SCRIPTS_DIR):
        if name.endswith(".sh"):
            path = os.path.join(SCRIPTS_DIR, name)
            with open(path) as f:
                first_line = f.readline()
            assert first_line.startswith("#!/"), f"{name} missing shebang"


def test_all_scripts_use_set_euo_pipefail():
    for name in os.listdir(SCRIPTS_DIR):
        if name.endswith(".sh"):
            path = os.path.join(SCRIPTS_DIR, name)
            with open(path) as f:
                content = f.read()
            assert "set -euo pipefail" in content, f"{name} missing strict mode"


def test_gitignore_covers_secrets():
    gitignore_path = os.path.join(
        os.path.dirname(os.path.dirname(__file__)), ".gitignore"
    )
    with open(gitignore_path) as f:
        content = f.read()
    assert ".env" in content
    assert ".netrc" in content
    assert "venv/" in content
