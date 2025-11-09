import os;
import from byllm.lib { Model }

# 1. Define the global LLM model
glob gemini_llm = Model(model_name="gemini/gemini-2.0-flash");

# 2. Define ONE LLM Ability
"""
You are an expert technical writer. You will be given a JSON string representing
a code repository analysis. Your job is to generate a complete, high-quality
Markdown documentation file based *only* on that JSON data.

The document MUST include the following sections:
1.  **Header**: '# Codebase Genius Report: <repo_name>'
2.  **Project Overview**: (Use the 'summary' from the JSON)
3.  **Installation and Usage**: (Infer this from the 'summary' or file types)
4.  **Repository Insights**: (Create a Markdown table for 'by_language' stats)
5.  **High-Level Architecture**: (Create a Mermaid 'graph TD' diagram based on the file list)
6.  **File-by-File Analysis**: (List each file from 'docs' with its 'path', 'summary', and 'symbols')

Return *only* the complete Markdown document.
"""
def generate_full_readme(analysis_json: str) -> str by gemini_llm();


# 3. The Walker
walker DocGenie {
    has analysis_data: dict;
    has output_dir: str = "./outputs";

    obj __specs__ {
        static has auth: bool = False;
    }

    can generate_docs with `root entry {
        if (not self.analysis_data) or (self.analysis_data == {}) {
            print("Error: DocGenie received no analysis_data.");
            report {"status": "error", "message": "Missing analysis data"};
            return;
        }

        # --- 1. Get Repo Name (for saving) ---
        index = self.analysis_data.get("index", {});
        repo_url = index.get("repo", "unknown/repo");
        repo_name = repo_url.split("/")[-1];
        if repo_name == "" { repo_name = "doc_genius_output"; }
        
        # --- 2. Call the AI to do everything ---
        print("Genie: Converting data to JSON for LLM...");
        
        json_payload = str(self.analysis_data);
        
        print("Genie: Calling LLM to generate the entire document...");
        md_content = generate_full_readme(analysis_json = json_payload);

        if type(md_content) == "dict" {
            print(f"Genie: CRITICAL LLM FAILURE: {md_content}");
            report {"status": "error", "message": "LLM failed to generate document"};
            return;
        }

        # --- 3. Save and Report ---
        save_path = os.path.join(self.output_dir, repo_name);
        os.makedirs(save_path, exist_ok=True);
        
        file_name = "docs.md";
        final_path = os.path.join(save_path, file_name);
        
        try {
            with open(final_path, "w", encoding="utf-8") as f {
                f.write(md_content);
            }
            print(f"DocGenie: Successfully saved documentation to {final_path}");
            report {
                "status": "success",
                "markdown_file": final_path,
                "content_length": len(md_content)
            };
        } except FileError as e { 
            print(f"Error: DocGenie failed to write file to {final_path}. Details: {e}");
            report {
                "status": "error",
                "message": "Failed to write documentation file.",
                "path": final_path
            };
        }
    }
}