import os;
import utils.rate_limiter as limiter;
import from byllm.lib { Model }

# Define the global LLM model
glob gemini_llm = Model(model_name="gemini/gemini-2.0-flash");

"""
You are an expert technical documentation writer. Given a JSON string representing
a code repository analysis, generate a comprehensive, professional Markdown documentation.

The document MUST include these sections:
1. **Header**: '# 📚 Documentation: <repo_name>'
2. **Project Overview**: Use the 'summary' from JSON
3. **Repository Statistics**: Create a table showing file counts by language
4. **Installation & Setup**: Infer installation steps based on file types and languages
5. **Project Structure**: Show directory tree or file organization
6. **Architecture Overview**: Create a Mermaid diagram showing main components
7. **File Analysis**: Document key files with their purpose and main symbols
8. **API Reference** (if applicable): Document main functions/classes
9. **Dependencies**: List dependencies found in the analysis

Requirements:
- Use proper Markdown formatting with headers, lists, code blocks, tables
- Include emoji icons for visual appeal (📁 📄 ⚙️ 🔧 etc.)
- Make the documentation clear, scannable, and professional
- Return ONLY the complete Markdown document, no preamble or wrapper text

JSON Data:
"""
def generate_comprehensive_docs(analysis_json: str) -> str by gemini_llm();


def build_language_stats_table(by_language: dict) -> str {
    """Build Markdown table for language statistics.""";
    if not by_language or len(by_language) == 0 {
        return "| Language | Files |\n|----------|-------|\n| None | 0 |";
    }
    
    # Sort by count descending - manual bubble sort
    lang_items = [];
    for lang in by_language {
        count = by_language[lang];
        lang_items.append((lang, count));
    }
    
    # Simple sort
    n = len(lang_items);
    for i in range(n) {
        for j in range(0, n - i - 1) {
            if lang_items[j][1] < lang_items[j + 1][1] {
                temp = lang_items[j];
                lang_items[j] = lang_items[j + 1];
                lang_items[j + 1] = temp;
            }
        }
    }
    
    table = "| Language | Files | Percentage |\n";
    table += "|----------|-------|------------|\n";
    
    total = 0;
    for (lang, count) in lang_items {
        total = total + count;
    }
    
    for (lang, count) in lang_items {
        percentage = (count / total * 100.0) if total > 0 else 0.0;
        lang_cap = lang.capitalize();
        table += f"| {lang_cap} | {count} | {percentage:.1f}% |\n";
    }
    
    return table;
}


def build_file_tree_text(files: list, max_files: int = 50) -> str {
    """Build a text representation of the file tree.""";
    if not files or len(files) == 0 {
        return "No files found.";
    }
    
    # Limit output
    tree = "```\n";
    count = 0;
    for file_obj in files {
        if count >= max_files {
            break;
        }
        path = file_obj.get("path", "");
        tree += f"├── {path}\n";
        count = count + 1;
    }
    
    if len(files) > max_files {
        remaining = len(files) - max_files;
        tree += f"... and {remaining} more files\n";
    }
    
    tree += "```";
    return tree;
}


def extract_key_files(docs: list, limit: int = 15) -> list {
    """Extract most important files for detailed documentation.""";
    key_files = [];
    
    # Priority names and languages
    priority_names = ["readme", "main", "index", "app", "server", "__init__"];
    priority_langs = ["python", "javascript", "typescript", "jac", "java"];
    
    for doc in docs {
        path = doc.get("path", "").lower();
        lang = doc.get("language", "").lower();
        symbols = doc.get("symbols", []);
        size = doc.get("size", 0);
        
        # Calculate importance score
        score = 0;
        
        # File name importance
        for name in priority_names {
            if name in path {
                score = score + 10;
                break;
            }
        }
        
        # Language importance
        for plang in priority_langs {
            if lang == plang {
                score = score + 5;
                break;
            }
        }
        
        # Symbol count
        sym_score = len(symbols);
        if sym_score > 10 {
            sym_score = 10;
        }
        score = score + sym_score;
        
        # File size (prefer substantial files)
        if size > 100 {
            score = score + 3;
        }
        
        key_files.append((score, doc));
    }
    
    # Sort by score descending
    n = len(key_files);
    for i in range(n) {
        for j in range(0, n - i - 1) {
            if key_files[j][0] < key_files[j + 1][0] {
                temp = key_files[j];
                key_files[j] = key_files[j + 1];
                key_files[j + 1] = temp;
            }
        }
    }
    
    # Take top N
    result = [];
    count = 0;
    for (score, doc) in key_files {
        if count >= limit {
            break;
        }
        result.append(doc);
        count = count + 1;
    }
    
    return result;
}


walker DocGenie {
    has analysis_data: dict;
    has output_dir: str = "./outputs";
    has result: dict = {};

    obj __specs__ {
        static has auth: bool = False;
    }

    can generate_docs with `root entry {
        print("[DocGenie] Starting documentation generation...");
        
        if (not self.analysis_data) or (self.analysis_data == {}) {
            print("[DocGenie] ERROR: No analysis data provided");
            self.result = {
                "status": "error",
                "stage": "validation",
                "message": "Missing analysis data"
            };
            report self.result;
            return;
        }

        # Extract data
        index = self.analysis_data.get("index", {});
        docs = self.analysis_data.get("docs", []);
        graph = self.analysis_data.get("graph", {});
        
        repo_url = index.get("repo", "unknown/repo");
        repo_parts = repo_url.split("/");
        repo_name = repo_parts[-1] if len(repo_parts) > 0 else "documentation";
        
        if repo_name == "" {
            repo_name = "documentation";
        }
        
        print(f"[DocGenie] Generating docs for: {repo_name}");
        
        # Build supplementary content
        lang_stats_table = build_language_stats_table(index.get("by_language", {}));
        file_tree = build_file_tree_text(docs, max_files=30);
        key_files = extract_key_files(docs, limit=15);
        
        # Prepare enhanced data for LLM
        enhanced_data = {
            "index": index,
            "docs": docs,
            "graph": graph,
            "key_files": key_files,
            "stats_table": lang_stats_table,
            "file_tree": file_tree
        };
        
        # Convert to JSON string for LLM
        json_payload = str(enhanced_data);
        
        print("[DocGenie] Calling rate-limited LLM to generate comprehensive documentation...");
        
        # Rate-limited LLM call
        md_content = limiter.rate_limited_call(
            generate_comprehensive_docs,
            analysis_json=json_payload,
            max_retries=3
        );

        # Check for errors
        if type(md_content) == "dict" {
            print(f"[DocGenie] CRITICAL: LLM generation failed: {md_content}");
            self.result = {
                "status": "error",
                "stage": "generation",
                "message": f"Documentation generation failed: {md_content.get('message', 'Unknown error')}"
            };
            report self.result;
            return;
        }
        
        # Ensure we have string content
        if len(md_content) == 0 {
            print("[DocGenie] ERROR: Generated content is empty or invalid");
            self.result = {
                "status": "error",
                "stage": "generation",
                "message": "Generated documentation is empty"
            };
            report self.result;
            return;
        }

        print(f"[DocGenie] Documentation generated ({len(md_content)} characters)");

        # Save to file
        save_path = os.path.join(self.output_dir, repo_name);
        os.makedirs(save_path, exist_ok=True);
        
        file_name = "docs.md";
        final_path = os.path.join(save_path, file_name);
        
        try {
            with open(final_path, "w", encoding="utf-8") as f {
                f.write(md_content);
            }
            
            print(f"[DocGenie] ✓ Documentation saved to: {final_path}");
            
            self.result = {
                "status": "success",
                "data": {
                    "markdown_file": final_path,
                    "content_length": len(md_content),
                    "repo_name": repo_name,
                    "files_documented": len(docs),
                    "key_files_highlighted": len(key_files)
                }
            };
            
        } except Exception as e { 
            print(f"[DocGenie] ERROR: Failed to write file to {final_path}. Details: {e}");
            self.result = {
                "status": "error",
                "stage": "file_write",
                "message": f"Failed to write documentation file: {str(e)}",
                "path": final_path
            };
        }
        
        report self.result;
    }
}