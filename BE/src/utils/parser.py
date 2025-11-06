import os
import tempfile
import git
from git.exc import GitCommandError

from tree_sitter import Language, Parser

# Load the Python grammar (we'll need to add other languages later)
Language.build_library(
  'build/my-languages.so', # Output file
  [
    'vendor/tree-sitter-python',
    'vendor/tree-sitter-javascript',
  ]
)
# --- Load Each Language Grammar ---
PY_LANG = Language("build/my-languages.so", "python")
JS_LANG = Language("build/my-languages.so", "javascript")

def extract_python_elements(file_path: str) -> dict:
    """
    Parses a Python file and extracts classes, methods, and functions.
    """
    parser = Parser()
    parser.set_language(PY_LANG)
    
    code_content = read_file_content(file_path)
    if not code_content:
        return {"classes": [], "functions": []}
    
    tree = parser.parse(bytes(code_content, "utf8"))
    root_node = tree.root_node
    
    elements = {"classes": [], "functions": []}

    # Query to find all top-level classes and functions
    class_query = PY_LANG.query("(class_definition name: (identifier) @name body: (block) @body)")
    func_query = PY_LANG.query("(function_definition name: (identifier) @name body: (block) @body)")
    
    # Capture classes
    for capture in class_query.captures(root_node):
        if capture[1] == "name":
            class_name = capture[0].text.decode('utf8')
            class_body_node = next(c[0] for c in class_query.captures(root_node) if c[1] == "body" and c[0].parent == capture[0].parent)
            
            methods = []
            # Query for methods *within* this class
            method_query = PY_LANG.query("(function_definition name: (identifier) @meth.name body: (block) @meth.body)")
            for meth_capture in method_query.captures(class_body_node):
                if meth_capture[1] == "meth.name":
                    methods.append({
                        "name": meth_capture[0].text.decode('utf8'),
                        "code": meth_capture[0].parent.text.decode('utf8') # Get full function code
                    })
            
            elements["classes"].append({
                "name": class_name,
                "code": capture[0].parent.text.decode('utf8'), # Get full class code
                "methods": methods
            })

    # Capture top-level functions
    for capture in func_query.captures(root_node):
        # Ensure it's a top-level function, not a method
        if capture[0].parent.parent.type == "module":
            elements["functions"].append({
                "name": capture[0].text.decode('utf8'),
                "code": capture[0].parent.text.decode('utf8') # Get full function code
            })
            
    return elements

# --- We would add more specialist functions below ---
def extract_js_elements(file_path: str) -> dict:
    # (Similar logic but with JS_LANG and a JS query)
    print(f"JavaScript parser not yet implemented for {file_path}")
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