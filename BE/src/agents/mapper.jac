import utils.parser as git_parser;
import os;

import from byllm.lib { Model }

# Define Gemini model globally
glob gemini_llm = Model(model_name="gemini/gemini-2.0-flash");


# readme summarizer
 """You are an expert technical writer. Summarize this README into a concise, one paragraph project overview. Focus on what the project *does and the main technologies used* Example:This project is a personal portfolio website built using TypeScript, React, and CSS. It showcases the developer’s skills, projects, and contact information in a clean, responsive layout.."""
def summarize_readme(content: str) -> str by gemini_llm();


# Language detector
"""You are a language detection assistant. Given a filename, guess the programming language or file type (e.g. python, jac, javascript, markdown, css, html, json). If it is uknown output unknown."""
def guess_language_from_name(name: str) -> str by gemini_llm();

def detect_language_from_path(path: str) -> str {
    ext = os.path.splitext(path)[1].lower();

    if ext == ".py" { return "python"; }
    elif ext == ".jac" { return "jac"; }
    elif ext in [".js", ".mjs", ".cjs"] { return "javascript"; }
    elif ext in [".ts", ".tsx"] { return "typescript"; }
    elif ext == ".md" { return "markdown"; }
    elif ext == ".json" { return "json"; }
    elif ext in [".yml", ".yaml"] { return "yaml"; }
    elif ext == ".css" { return "css"; }
    elif ext == ".html" { return "html"; }
    else {
        guessed = guess_language_from_name(name = path);
        return guessed.strip().lower();
    }
}

# Node definition for RepoMap
obj RepoMap {
    has file_tree: list[str];
    has summary: str;
    has local_path: str;
    has result: dict;
}

# Repo Mapper Walkek
walker RepoMapper {
    has url: str;

    obj __specs__ {
        static has auth: bool = False;
    }

    can run with `root entry {

        repo_path = git_parser.clone_repo(self.url);
               
        if not repo_path {
            print("Error: Repository could not be cloned.");
            return {"status": "error", "message": "Repo could not be cloned"};
            return;
        }

        file_tree = git_parser.get_file_tree(repo_path);
        readme_path = os.path.join(repo_path, "README.md");
        readme_content = git_parser.read_file_content(readme_path);

        readme_summary: str;
        
        if (not readme_content) or (len(readme_content) == 0) {
            readme_summary = "No README.md file found or file is empty.";
        } else {
            print("Summarizing README.md with Gemini...");
            

            # Now we just call our new, AI-powered function
            readme_summary = summarize_readme(content=readme_content);
        }

        # build rich files with language + content
        files = [];
        for f in file_tree {
            lang = detect_language_from_path(f);
            # if (type(lang) != 'str') {
            #     print('detect_language_from_path returned non-string:', lang);
            # }

            content = git_parser.read_file_content(os.path.join(repo_path, f));
            files.append({
                "path": f,
                "language": lang,
                "content": content
            });
        }
        self.result = {
            "status": "success",
            "data": {
                "repo": self.url,
                "local_path": repo_path,
                "file_tree": file_tree,
                "summary": readme_summary,
                "files": files,
            }
        };
    }
}

