import utils.parser as git_parser;
import os;

# 1. Only import 'Model'. 'by' is a keyword, not an import.
import from byllm.lib { Model }

# Define Gemini model globally
glob gemini_llm = Model(model_name="gemini/gemini-2.0-flash");

# --- THIS IS THE FIX (based on your docs) ---
# We define a function that is powered by Gemini.
# The 'by' keyword is followed by our global model variable.
 """You are an expert technical writer. Summarize this README into a concise, one-paragraph project overview. Focus on what the project *does*."""
def summarize_readme(content: str) -> str by gemini_llm();
    # This docstring automatically becomes the prompt for the LLM

# Node definition for RepoMap
node RepoMap {
    has file_tree: list[str];
    has summary: str;
    has local_path: str;
}

# Walker definition
walker RepoMapper {
    has url: str;

    obj __specs__ {
        static has auth: bool = False;
    }

    can enter with `root entry {
    
        repo_path = git_parser.clone_repo(self.url);
        
        if not repo_path {
            print("Error: Repository could not be cloned.");
            report {"status": "error", "message": "Repo could not be cloned"};
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
            
            # --- THIS IS THE FIX ---
            # Now we just call our new, AI-powered function
            readme_summary = summarize_readme(content=readme_content);
        }

        final_map = RepoMap(
            file_tree=file_tree,
            summary=readme_summary,
            local_path=repo_path
        );

        report {
            "status": "success",
            "data": final_map
        };
    }
}