import os
import tempfile
import git
from git.exc import GitCommandError

# ---------------------------------
# --- NEW TREE-SITTER SETUP ---
# ---------------------------------
from tree_sitter import Language, Parser

# Import the installed grammar packages
import tree_sitter_python as tspython
import tree_sitter_javascript as tsjavascript

# Get the language object directly from the imported package
PY_LANG = tspython.language()
JS_LANG = tsjavascript.language()
# We don't have one for Jac, so we'll just use these two

# ---------------------------------
# --- (The rest of your file is correct) ---
# ---------------------------------

# --- Git Operations ---
def clone_repo(url: str) -> str | None:
    """
    Clones a public GitHub repo to a temporary directory.
    Returns the path to the temporary directory, or None on error.
    """
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
    """
    Generates a list of all file paths in a directory, ignoring specified folders.
    """
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
    """
    Safely reads the content of a file.
    Returns the content as a string, or None on error.
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read() # Corrected with ()
    except FileNotFoundError:
        print(f"File not found: {file_path}")
        return None
    except Exception as e:
        print(f"Error reading file {file_path}: {e}")
        return None

# ---------------------------------
# --- SPECIALIST FUNCTIONS ---
# ---------------------------------

def extract_python_elements(file_path: str) -> dict:
    """
    Parses a Python file and extracts classes, methods, and functions.
    """
    parser = Parser()
    parser.set_language(PY_LANG) # This now uses the correct language object
    code_content = read_file_content(file_path)
    if not code_content:
        return {"classes": [], "functions": []}
    
    tree = parser.parse(bytes(code_content, "utf8"))
    root_node = tree.root_node
    elements = {"classes": [], "functions": []}

    # (The rest of this function's query logic is correct)
    class_query_str = """
    (class_definition
        name: (identifier) @name
        body: (block) @body)
    """
    class_query = PY_LANG.query(class_query_str)
    
    func_query_str = """
    (function_definition
        name: (identifier) @name
        body: (block) @body)
    """
    func_query = PY_LANG.query(func_query_str)
    
    class_nodes = [c[0] for c in class_query.captures(root_node) if c[1] == "name"]
    
    for class_node in class_nodes:
        if class_node.parent.parent.type == "module":
            class_name = class_node.text.decode('utf8')
            class_body_node = class_node.parent.child_by_field_name("body")
            
            methods = []
            if class_body_node:
                method_query_str = """
                (function_definition
                    name: (identifier) @meth.name
                    body: (block) @meth.body)
                """
                method_query = PY_LANG.query(method_query_str)
                for meth_capture in method_query.captures(class_body_node):
                    if meth_capture[1] == "meth.name":
                        methods.append({
                            "name": meth_capture[0].text.decode('utf8'),
                            "code": meth_capture[0].parent.text.decode('utf8')
                        })
            
            elements["classes"].append({
                "name": class_name,
                "code": class_node.parent.text.decode('utf8'),
                "methods": methods
            })

    func_nodes = [c[0] for c in func_query.captures(root_node) if c[1] == "name"]
    for func_node in func_nodes:
        if func_node.parent.parent.type == "module":
            elements["functions"].append({
                "name": func_node.text.decode('utf8'),
                "code": func_node.parent.text.decode('utf8')
            })
            
    return elements

def extract_js_elements(file_path: str) -> dict:
    parser = Parser()
    parser.set_language(JS_LANG) # This now uses the correct language object
    code_content = read_file_content(file_path)
    if not code_content:
        return {"classes": [], "functions": []}
    
    print(f"JavaScript parser loaded, but query not yet implemented for {file_path}")
    # (We would add the JS query logic here later)
    return {"classes": [], "functions": []}

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