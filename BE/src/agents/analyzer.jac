import os;
import utils.rate_limiter as limiter;
import from byllm.lib { Model }

glob gemini_llm = Model(model_name="gemini/gemini-2.0-flash");

"""Given file contents, produce a single concise one-sentence description of what the file does. Return EXACTLY one sentence, no preamble or extra text."""
def summarize_file(content: str) -> str by gemini_llm();

"""Given file contents, return a comma-separated list of top symbols or identifiers (functions, classes, modules, constants). Return ONLY the comma-separated list, no extra text or formatting."""
def extract_top_symbols(content: str) -> str by gemini_llm();

"""Given file contents, identify dependencies or imports. Return a comma-separated list of module/file names that this file depends on. Return ONLY the list, no extra text."""
def extract_dependencies(content: str) -> str by gemini_llm();


def normalize_llm_response(response: any, default: str = "") -> str {
    """Normalize LLM response, handling errors and unexpected formats.""";
    if response == None {
        return default;
    }
    
    # if type(response) == "dict" {
    #     print(f"LLM Error: {response}");
    #     return default;
    # }
    
    # if type(response) == "str" {
    #     return response.strip();
    # }
    
    return str(response).strip();
}


def parse_symbol_list(text: str) -> list {
    """Parse comma-separated symbol list from LLM output.""";
    if not text or text == "" {
        return [];
    }
    
    # Clean up common LLM artifacts
    cleaned = text.replace("```", "").replace("`", "");
    cleaned = cleaned.replace("\n", ",").replace("\r", "");
    
    # Split and clean
    raw_symbols = cleaned.split(",");
    symbols = [];
    for s in raw_symbols {
        trimmed = s.strip();
        if trimmed != "" {
            symbols.append(trimmed);
        }
    }
    
    # Remove duplicates while preserving order
    seen = {};
    unique_symbols = [];
    for sym in symbols {
        if sym not in seen and len(sym) > 0 {
            seen[sym] = True;
            unique_symbols.append(sym);
        }
    }
    
    return unique_symbols;
}


# Node types for Code Context Graph
node CodeFile {
    has path: str;
    has language: str;
    has summary: str;
    has symbols: list[];
    has size: int;
}

node CodeSymbol {
    has name: str;
    has type: str;  # "function", "class", "constant", etc.
    has file_path: str;
}

edge imports { }
edge contains { }
edge defines { }


walker RepoAnalyzer {
    has return_data: dict;
    has result: dict = {};

    obj __specs__ {
        static has auth: bool = False;
    }

    can analyze with `root entry {
        print("[RepoAnalyzer] Starting analysis...");
        
        if not self.return_data {
            print("[RepoAnalyzer] ERROR: No mapper data provided");
            self.result = {
                "status": "error",
                "stage": "validation",
                "message": "Missing mapper data"
            };
            report self.result;
            return;
        }

        repo = self.return_data.get("repo", "unknown");
        local_path = self.return_data.get("local_path", "");
        files = self.return_data.get("files", []);
        summary = self.return_data.get("summary", "");

        print(f"[RepoAnalyzer] Analyzing {len(files)} files from {repo}");

        # Counters and outputs
        lang_count = {};
        docs = [];
        errors = [];
        
        # Code context graph structure
        file_nodes = {};
        total_symbols_count = 0;
        total_deps_count = 0;

        # Analyze each file
        idx = 0;
        for file_obj in files {
            path = file_obj.get("path", "");
            lang = file_obj.get("language", "unknown").strip().lower();
            content = file_obj.get("content", "");
            size = file_obj.get("size", 0);
            
            if idx % 10 == 0 {
                print(f"[RepoAnalyzer] Progress: {idx}/{len(files)} files");
            }
            idx = idx + 1;

            # Count by language
            lang_count[lang] = lang_count.get(lang, 0) + 1;

            # Initialize doc entry
            doc_entry = {
                "path": path,
                "language": lang,
                "summary": "",
                "symbols": [],
                "dependencies": [],
                "size": size
            };

            # Skip analysis for empty files or certain types
            if content == "" or size == 0 {
                doc_entry["summary"] = "Empty file or placeholder";
                docs.append(doc_entry);
                continue;
            }
            
            # Skip binary/config files
            if lang == "unknown" or lang == "json" or lang == "yaml" or lang == "xml" or lang == "text" {
                doc_entry["summary"] = f"Configuration or data file ({lang})";
                docs.append(doc_entry);
                continue;
            }

            # Perform LLM-based analysis for code files
            is_code_file = (lang == "python" or lang == "javascript" or lang == "typescript" or 
                           lang == "jac" or lang == "java" or lang == "cpp" or 
                           lang == "go" or lang == "rust");
            
            if is_code_file {
                print(f"[RepoAnalyzer] Analyzing code file: {path}");
                
                # Extract summary
                summary_raw = limiter.rate_limited_call(
                    summarize_file,
                    content=content
                );
                doc_entry["summary"] = normalize_llm_response(summary_raw, "Code file");
                
                # Extract symbols
                symbols_raw = limiter.rate_limited_call(
                    extract_top_symbols,
                    content=content
                );
                symbols_text = normalize_llm_response(symbols_raw, "");
                doc_entry["symbols"] = parse_symbol_list(symbols_text);
                total_symbols_count = total_symbols_count + len(doc_entry["symbols"]);
                
                # Extract dependencies
                deps_raw = limiter.rate_limited_call(
                    extract_dependencies,
                    content=content
                );
                deps_text = normalize_llm_response(deps_raw, "");
                doc_entry["dependencies"] = parse_symbol_list(deps_text);
                total_deps_count = total_deps_count + len(doc_entry["dependencies"]);
                
            } else {
                # For other languages, just get summary
                summary_raw = limiter.rate_limited_call(
                    summarize_file,
                    content=content
                );
                doc_entry["summary"] = normalize_llm_response(summary_raw, f"Source file ({lang})");
            }

            docs.append(doc_entry);
            
            # Build graph structure (for future use)
            file_nodes[path] = {
                "path": path,
                "language": lang,
                "symbols": doc_entry["symbols"],
                "dependencies": doc_entry["dependencies"]
            };
        }

        print(f"[RepoAnalyzer] Analysis complete. Processed {len(docs)} files.");

        # Count code files and config files
        code_files_count = 0;
        config_files_count = 0;
        for d in docs {
            d_lang = d.get("language", "");
            if d_lang != "unknown" and d_lang != "json" and d_lang != "yaml" and d_lang != "text" {
                code_files_count = code_files_count + 1;
            }
            if d_lang == "json" or d_lang == "yaml" or d_lang == "xml" {
                config_files_count = config_files_count + 1;
            }
        }

        # Build analysis index
        index = {
            "repo": repo,
            "local_path": local_path,
            "summary": summary,
            "total_files": len(files),
            "by_language": lang_count,
            "code_files": code_files_count,
            "config_files": config_files_count
        };

        # Build final result
        self.result = {
            "status": "success",
            "data": {
                "index": index,
                "docs": docs,
                "errors": errors,
                "graph": {
                    "files": file_nodes,
                    "total_symbols": total_symbols_count,
                    "total_dependencies": total_deps_count
                }
            }
        };
        
        report self.result;
    }
}