import utils.parser as git_parser;
import utils.rate_limiter as limiter;
import os;
import from byllm.lib { Model }

# Define Gemini model globally
glob gemini_llm = Model(model_name="gemini/gemini-2.0-flash");

"""You are an expert technical writer. Summarize this README into a concise, one paragraph project overview. Focus on what the project does and the main technologies used. Return ONLY the summary paragraph, no preamble or extra text."""
def summarize_readme(content: str) -> str by gemini_llm();

"""You are a language detection assistant. Given a filename, identify the programming language or file type (e.g. python, javascript, typescript, markdown, css, html, json, yaml). Return ONLY the language name in lowercase, nothing else."""
def guess_language_from_name(name: str) -> str by gemini_llm();


def detect_language_from_path(path: str) -> str {
    """Detect language from file extension with LLM fallback.""";
    ext_tuple = os.path.splitext(path);
    ext = ext_tuple[1];
    ext = ext.lower();

    # Fast path for common extensions
    if ext == ".py" { return "python"; }
    elif ext == ".jac" { return "jac"; }
    elif ext == ".js" or ext == ".mjs" or ext == ".cjs" { return "javascript"; }
    elif ext == ".ts" or ext == ".tsx" { return "typescript"; }
    elif ext == ".jsx" { return "javascript"; }
    elif ext == ".md" { return "markdown"; }
    elif ext == ".json" { return "json"; }
    elif ext == ".yml" or ext == ".yaml" { return "yaml"; }
    elif ext == ".css" or ext == ".scss" { return "css"; }
    elif ext == ".html" { return "html"; }
    elif ext == ".xml" { return "xml"; }
    elif ext == ".sh" or ext == ".bash" { return "shell"; }
    elif ext == ".java" { return "java"; }
    elif ext == ".c" { return "c"; }
    elif ext == ".cpp" { return "cpp"; }
    elif ext == ".go" { return "go"; }
    elif ext == ".rs" { return "rust"; }
    elif ext == ".rb" { return "ruby"; }
    elif ext == ".php" { return "php"; }
    elif ext == ".swift" { return "swift"; }
    elif ext == ".kt" { return "kotlin"; }
    else {
        # Fallback to LLM with rate limiting
        guessed = limiter.rate_limited_call(guess_language_from_name, name=path);
        
        if type(guessed) == "dict" {
            print(f"Language detection failed for {path}: {guessed}");
            return "unknown";
        }
        
        return guessed.strip().lower() if guessed else "unknown";
    }
}


def normalize_readme_summary(summary_text: str, max_length: int = 500) -> str {
    """Normalize and truncate README summary.""";
    # Check if input is invalid
    if not summary_text {
        return "No project description available.";
    }
    
    if type(summary_text) == "dict" {
        return "No project description available.";
    }
    
    # Clean up the text - chain string methods
    cleaned = str(summary_text);
    cleaned = cleaned.strip();
    cleaned = cleaned.replace("\n\n", " ");
    cleaned = cleaned.replace("\n", " ");
    
    # Remove common LLM preambles using Python string methods
    cleaned_lower = cleaned.lower();
    
    # Check and remove preambles
    if "here is the summary:" in cleaned_lower[:25] {
        cleaned = cleaned[20:];
        cleaned = cleaned.strip();
    }
    
    if "summary:" in cleaned_lower[:15] {
        cleaned = cleaned[8:];
        cleaned = cleaned.strip();
    }
    
    if "the summary is:" in cleaned_lower[:20] {
        cleaned = cleaned[15:];
        cleaned = cleaned.strip();
    }
    
    if "project overview:" in cleaned_lower[:20] {
        cleaned = cleaned[17:];
        cleaned = cleaned.strip();
    }
    
    # Truncate if too long
    if len(cleaned) > max_length {
        cleaned = cleaned[:max_length];
        cleaned = cleaned + "...";
    }
    
    # Return cleaned or default
    if cleaned and len(cleaned) > 0 {
        return cleaned;
    } else {
        return "No project description available.";
    }
}


walker RepoMapper {
    has url: str;
    has result: dict = {};

    obj __specs__ {
        static has auth: bool = False;
    }

    can run with `root entry {
        print(f"[RepoMapper] Starting mapping for: {self.url}");
        
        # Step 1: Clone repository
        repo_path = git_parser.clone_repo(self.url);
        
        if not repo_path {
            print("[RepoMapper] ERROR: Repository could not be cloned");
            self.result = {
                "status": "error",
                "stage": "clone",
                "message": "Failed to clone repository. Check URL and network connection."
            };
            report self.result;
            return;
        }
        
        print(f"[RepoMapper] Repository cloned to: {repo_path}");
        
        # Step 2: Get file tree (already filters out .git, node_modules, etc.)
        file_tree = git_parser.get_file_tree(repo_path);
        print(f"[RepoMapper] Found {len(file_tree)} files");
        
        # Step 3: Read and summarize README
        readme_path = os.path.join(repo_path, "README.md");
        readme_content = git_parser.read_file_content(readme_path);
        
        readme_summary: str;
        
        if (not readme_content) or (len(readme_content) == 0) {
            readme_summary = "No README.md file found or file is empty.";
            print("[RepoMapper] No README.md found");
        } else {
            print("[RepoMapper] Summarizing README.md with rate-limited Gemini call...");
            
            # Rate-limited LLM call
            raw_summary = limiter.rate_limited_call(
                summarize_readme,
                content=readme_content
            );
            
            # Normalize the summary
            readme_summary = normalize_readme_summary(raw_summary);
            print(f"[RepoMapper] README summary generated");
        }
        
        # Step 4: Build rich file list with language detection
        files = [];
        print("[RepoMapper] Detecting languages for all files...");
        
        for f in file_tree {
            lang = detect_language_from_path(f);
            content = git_parser.read_file_content(os.path.join(repo_path, f));
            
            # Normalize content (handle None)
            if content == None {
                content = "";
            }
            
            files.append({
                "path": f,
                "language": lang,
                "content": content,
                "size": len(content)
            });
        }
        
        print(f"[RepoMapper] Mapping complete. Processed {len(files)} files.");
        
        # Step 5: Calculate total size
        total_size = 0;
        for f in files {
            total_size = total_size + f.get("size", 0);
        }
        
        # Step 6: Build final result
        self.result = {
            "status": "success",
            "data": {
                "repo": self.url,
                "local_path": repo_path,
                "file_tree": file_tree,
                "summary": readme_summary,
                "files": files,
                "stats": {
                    "total_files": len(files),
                    "total_size": total_size
                }
            }
        };
        
        report self.result;
    }
}