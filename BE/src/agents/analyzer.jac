# Import our Python parser tools
import utils.parser as parser;
import os;

# Import the Gemini model and 'by' keyword
import from byllm.lib { Model, by }

# Define Gemini model globally
glob gemini_llm = Model(model_name="gemini/gemini-2.0-flash");

# ---------------------------------
# 1. DEFINE AI-HELPER DATA NODES
# (Temporary data containers for our AI parser)
# ---------------------------------
node ExtractedFunction {
    has name: str;
    has code: str;
}

node ExtractedClass {
    has name: str;
    has code: str;
    has methods: list[ExtractedFunction];
}

node CodeStructure {
    has functions: list[ExtractedFunction];
    has classes: list[ExtractedClass];
}

# ---------------------------------
# 2. DEFINE OUR CCG (CODE CONTEXT GRAPH)
# (This is our main graph "database")
# ---------------------------------
node Module { has name: str; has path: str; }
node Class { has name: str; has code: str; }
node Function { has name: str; has code: str; }

# Correct: Archetype definitions must have a body {}
edge defines {}
edge inherits_from {}
edge calls {}

# ---------------------------------
# 3. DEFINE OUR "AI BRAIN" FUNCTIONS
# (Correct: 'by-llm' declarations end with '();')
# ---------------------------------

"You are an expert code parser. Analyze this source code. Extract all top-level functions, and all classes with their methods. Return the data as a 'CodeStructure' object."
def extract_structure_from_code(code: str) -> CodeStructure by gemini_llm();

"Analyze this code block. Return a list of function names that are called inside it. Only include calls to other functions defined in the repo, not built-in (like 'print') or imported (like 'os.path.join'). Return only a Python-style list of strings."
def find_function_calls(code: str) -> list[str] by gemini_llm();

"Analyze this class definition's code block. Return the name of the single class it inherits from, or 'None' if it does not inherit."
def find_inheritance(code: str) -> str by gemini_llm();


# ---------------------------------
# 4. DEFINE THE ANALYZER AGENT
# ---------------------------------

walker CodeAnalyzer {
    has file_paths: list[str];
    has local_path: str;

    # Make this walker a public API endpoint
    obj __specs__ {
        static has auth: bool = False;
    }

    has graph_root: Module;

    # This ability runs when the API endpoint is called
    can enter with `root entry {
        
        # --- All statements below end with a semicolon (;) ---
        
        self.graph_root = spawn Module(name="REPO_ROOT", path=self.local_path);
        print("Starting Pass 1: Node Creation (Triage)...");

        for file in self.file_paths {
            full_path = os.path.join(self.local_path, file);
            elements: dict = {"classes": [], "functions": []};
            ai_elements: CodeStructure = null;
            use_ai_fallback = False;

            # --- This is the "Triage" Logic ---
            if file.endswith(".py") {
                elements = parser.extract_python_elements(full_path);
            } 
            elif file.endswith(".js") or file.endswith(".tsx") {
                elements = parser.extract_js_elements(full_path);
            }
            # (As you noted, 'tree-sitter-jac' doesn't exist, so we skip it)
            else {
                print(f"No parser for {file}, using Gemini fallback.");
                code_content = parser.read_file_content(full_path);
                
                if (not code_content) or (len(code_content) == 0) {
                    continue;
                }
                
                # Correct: try...except Exception { ... }
                try {
                    ai_elements = extract_structure_from_code(code=code_content);
                    use_ai_fallback = True;
                } except Exception {
                    print(f"LLM failed to parse {file}. Skipping.");
                    continue;
                }
            }
            
            # --- Populate Graph ---
            if (not elements and not ai_elements) {
                continue; # Skip if parsing failed or returned nothing
            }

            mod_node = spawn Module(name=file, path=full_path);
            self.graph_root ++> mod_node; # Connect RepoRoot to Module

            if(use_ai_fallback) {
                # Populate from AI-generated nodes
                for c in ai_elements.classes {
                    class_node = spawn Class(name=c.name, code=c.code);
                    mod_node +>: defines :+> class_node;
                    for m in c.methods {
                        meth_node = spawn Function(name=m.name, code=m.code);
                        class_node +>: defines :+> meth_node;
                    }
                }
                for f in ai_elements.functions {
                    func_node = spawn Function(name=f.name, code=f.code);
                    mod_node +>: defines :+> func_node;
                }
            } else {
                # Populate from Tree-sitter dict
                for c in elements["classes"] {
                    class_node = spawn Class(name=c["name"], code=c["code"]);
                    mod_node +>: defines :+> class_node;
                    for m in c["methods"] {
                        meth_node = spawn Function(name=m["name"], code=m["code"]);
                        class_node +>: defines :+> meth_node;
                    }
                }
                for f in elements["functions"] {
                    func_node = spawn Function(name=f["name"], code=f["code"]);
                    mod_node +>: defines :+> func_node;
                }
            }
        }

      # --- PASS 2: Connect Graph with AI ---
        print("Starting Pass 2: Edge Creation (AI Reasoning)...");

        # --- THIS IS THE FIX ---
        # 1. Get ALL nodes first. This syntax is valid.
        all_funcs = [self.graph_root --> Function];
        all_classes = [self.graph_root --> Class];

        # 2a. Find 'calls' edges
        for func_node in all_funcs {
            called_names = find_function_calls(code=func_node.code);
            
            for call_name in called_names {
                # 2. Now, loop and filter in Jac to find the match
                for target_func in all_funcs {
                    if target_func.name == call_name {
                        func_node +>: calls :+> target_func;
                        break; # Found it, stop inner loop
                    }
                }
            }
        }
        
        # 2b. Find 'inherits_from' edges
        for class_node in all_classes {
            p_name = find_inheritance(code=class_node.code);
            
            if(p_name != "None") {
                # 2. Loop and filter in Jac to find the match
                for target_class in all_classes {
                    if target_class.name == p_name {
                        class_node +>: inherits_from :+> target_class;
                        break; # Found it, stop inner loop
                    }
                }
            }
        }
        
        print("Code analysis complete!");
        report {"status": "success", "graph_root_id": self.graph_root.id};
    }
}