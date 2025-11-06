import os
import tempfile
import git
from git.exc import GitCommandError

# -- Git Operations --
def clone_repo(url: str) -> str | None:
    """
    Clones a public GitHub repo to a temporary directory.
    Returns the path to the temporary directory, or None on error.
    """

    try:
        # Create a new temporary directory for each clone
        temp_dir = tempfile.mkdtemp(prefix="codebase_genius_")
        print(f"Cloning {url} into {temp_dir}...")
        git.Repo.clone_from(url, temp_dir)
        print(f"Cloning complete")
        return temp_dir
    except GitCommandError as e:
        print(f"Errror cloning repo: {e}")
        return None
    
# -- File System Operation --
def get_file_tree(start_path: str) -> list[str]:
    """
    Generates a list of all file paths in a directory, ignoring specified folders.
    """
    file_list = []
    # These are the directories we will not scan
    ignore_dirs = {'.git', 'node_modules', '__pycache__', '.venv', 'build', 'dist'}

    for root, dirs, files in os.walk(start_path, topdown=True):
        # Tells os not to descend to ignored directories
        dirs[:] = [d for d in dirs if d not in ignore_dirs]

        for file in files:
            # We create a relative path (e.g.  "src/main.jac")
            full_path = os.path.join(root, file)
            relative_path = os.path.relpath(full_path, start_path)
            file_list.append(relative_path.replace(os.sep, '/')) # Normalize slashes
        
    return file_list

def read_file_content(file_path: str) -> str | None:
    """
    Safely reads the content of a file.
    Returns the content as a string, or None on error.
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        print(f"File not found: {file_path}")
        return None
    except Exception as e:
        print(f"Error reading file {file_path}: {e}")
        return None