import os
import tempfile
import git
from git.exc import GitCommandError

# from tree_sitter_languages import get_language, get_parser
# from tree_sitter import Query

# # --- Tree-sitter setup ---
# PY_LANG = get_language("python")
# JS_LANG = get_language("javascript")

# PY_PARSER = get_parser("python")
# JS_PARSER = get_parser("javascript")

# def read_file_content(file_path: str) -> str:
#     try:
#         with open(file_path, "r", encoding="utf8") as f:
#             return f.read()
#     except Exception:
#         return ""


# --- Git Operations ---
def clone_repo(url: str) -> str | None:
    # (This function is correct)
    try:
        temp_dir = tempfile.mkdtemp(prefix="codebase_genius_")
        print(f"Cloning {url} into {temp_dir}...")
        git.Repo.clone_from(url, temp_dir)
        print(f"Cloning complete")
        return temp_dir
    except GitCommandError as e:
        print(f"Errror cloning repo: {e}")
        return None

# --- File System Operation ---
def get_file_tree(start_path: str) -> list[str]:
    # (This function is correct)
    file_list = []
    ignore_dirs = {'.git', 'node_modules', '__pycache__', '.venv', 'build', 'dist'}
    for root, dirs, files in os.walk(start_path, topdown=True):
        dirs[:] = [d for d in dirs if d not in ignore_dirs]
        for file in files:
            full_path = os.path.join(root, file)
            relative_path = os.path.relpath(full_path, start_path)
            file_list.append(relative_path.replace(os.sep, '/'))
    return file_list

def read_file_content(file_path: str) -> str | None:
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        print(f"File not found: {file_path}")
        return None
    except Exception as e:
        print(f"Error reading file {file_path}: {e}")
        return None