import os
import tempfile
import git
from git.exc import GitCommandError

from tree_sitter import Language, Parser

# Load the Python grammar (we'll need to add other languages later)
try:
    PY_LANGUAGE = Language("build/my-languages.so", "python")
except:
    Language.build_library(
      'build/my-languages.so',
      ['vendor/tree-sitter-python'] # Path to the grammar repo (you'll need to git clone this)
    )
    PY_LANGUAGE = Language("build/my-languages.so", "python")

PARSER = Parser()
PARSER.set_language(PY_LANGUAGE)

# ⬇️ --- ADD THIS NEW FUNCTION --- ⬇️

def extract_code_elements(file_path: str) -> dict:
    """
    Parses a Python file and extracts classes and functions.
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            source_code = f.read()
    except Exception:
        return {} # Return empty if file can't be read

    tree = PARSER.parse(bytes(source_code, "utf8"))
    root_node = tree.root_node
    
    elements = {
        "classes": [],
        "functions": []
    }

    # This query finds all top-level functions and classes
    query_str = """
    (class_definition name: (identifier) @class.name body: (block . (function_definition name: (identifier) @method.name body: (block) @method.body) @method.def))
    (function_definition name: (identifier) @function.name body: (block) @function.body)
    """
    
    query = PY_LANGUAGE.query(query_str)
    captures = query.captures(root_node)
    
    # We'll need a way to store methods found so we don't add them as top-level functions
    processed_methods = set()

    # Find classes and their methods
    for node, capture_name in captures:
        if capture_name == "class.name":
            class_name = node.text.decode('utf8')
            class_methods = []
            
            # Find methods within this class's body
            for sub_node, sub_capture in captures:
                if sub_capture == "method.def" and sub_node.parent.parent == node.parent: # Check if it's a method of *this* class
                    method_name_node = next(c[0] for c in captures if c[1] == "method.name" and c[0].parent == sub_node)
                    method_body_node = next(c[0] for c in captures if c[1] == "method.body" and c[0].parent == sub_node)
                    
                    method_name = method_name_node.text.decode('utf8')
                    method_body = method_body_node.text.decode('utf8')
                    
                    class_methods.append({
                        "name": method_name,
                        "code": method_body
                    })
                    processed_methods.add(method_name)

            elements["classes"].append({
                "name": class_name,
                "methods": class_methods
            })

    # Find top-level functions (and ignore methods we already found)
    for node, capture_name in captures:
        if capture_name == "function.name":
            func_name = node.text.decode('utf8')
            if func_name not in processed_methods:
                body_node = next(c[0] for c in captures if c[1] == "function.body" and c[0].parent == node.parent)
                func_body = body_node.text.decode('utf8')
                elements["functions"].append({
                    "name": func_name,
                    "code": func_body
                })

    return elements

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