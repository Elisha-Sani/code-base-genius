## This is a Repo Analyzer
import os;
import utils.parser as git_parser;
import from byllm.lib { Model }

glob gemini_llm = Model(model_name="gemini/gemini-2.0-flash");

"""Given file contents, produce a single concise one-sentence description of what the file does. Return EXACTLY one sentence, no trailing newline."""
def summarize_file(content: str) -> str by gemini_llm();

"""Given file contents, return a comma separated list of top symbols or identifiers (functions, classes, modules). Return plain text like: funcA,ClassB,CONST_C"""
def extract_top_symbols(content: str) -> str by gemini_llm();

walker RepoAnalyzer {
    has report_data: dict;

    obj __specs__ {
        static has auth: bool = False;
    }

    can analyze with `root entry {
        if not self.report_data {
            print("No mapper data provided");
            report {"status": "error", "message": "missing mapper data"};
            return;
        }

        repo = self.report_data.get("repo", "unknown");
        local_path = self.report_data.get("local_path", "");
        files = self.report_data.get("files", []);
        summary = self.report_data.get("summary", "");

        # counters and outputs
        lang_count = {};
        docs = [];
        errors = [];

        for file_obj in files {
            path = file_obj.get("path", "");
            raw_lang = file_obj.get("language", "unknown");
            content = file_obj.get("content", "");

            lang = raw_lang.strip().lower();

            if content == "" {
                if path.endswith(".gitkeep") or path.startswith(".") { lang = "text"; }
                if lang == "unknown" { lang = "text"; }
            }

            lang_count[lang] = lang_count.get(lang, 0) + 1;

            doc_entry = {
                "path": path,
                "language": lang,
                "summary": "",
                "symbols": [],
                "size": len(content)
            };

            # best-effort extraction only for non-empty content
            if content != "" {
                if lang == "javascript" or lang == "typescript" {
                    tokens = [];
                    tokens_text = extract_top_symbols(content=content);

                    # --- FIX ---
                    # Check if it's NOT an error dictionary
                    if type(tokens_text) != "dict" {
                        cleaned = tokens_text.strip().replace("\n","").replace("\r","");
                        if cleaned != "" { tokens = cleaned.split(","); }
                    } else {
                        print(f"DEBUG: extract_top_symbols FAILED for {path}. Got: {tokens_text}");
                    }
                    
                    if len(tokens) == 0 {
                        s = summarize_file(content=content);
                        # --- FIX ---
                        if type(s) != "dict" {
                            doc_entry["summary"] = s.strip();
                        } else {
                            print(f"DEBUG: summarize_file FAILED for {path}. Got: {s}");
                            doc_entry["summary"] = "";
                        }
                    } else {
                        doc_entry["symbols"] = tokens;
                        s = summarize_file(content=content);
                        # --- FIX ---
                        if type(s) != "dict" {
                            doc_entry["summary"] = s.strip();
                        } else {
                             print(f"DEBUG: summarize_file (symbols) FAILED for {path}. Got: {s}");
                        }
                    }
                } else {
                    # generic path: ask model for summary + symbols
                    s = summarize_file(content=content);
                    sym_text = extract_top_symbols(content=content);

                    # --- FIX ---
                    if type(s) != "dict" {
                        doc_entry["summary"] = s.strip();
                    } else {
                        print(f"DEBUG: summarize_file (else) FAILED for {path}. Got: {s}");
                    }
                    
                    # --- FIX ---
                    if type(sym_text) != "dict" {
                        cleaned = sym_text.strip().replace("\n","").replace("\r","");
                        if cleaned != "" { doc_entry["symbols"] = cleaned.split(","); }
                    } else {
                        print(f"DEBUG: extract_top_symbols (else) FAILED for {path}. Got: {sym_text}");
                    }
                }
            } else {
                # --- FIX ---
                # This was also blank in your output, let's fix it
                doc_entry["summary"] = "Empty file or placeholder";
            }

            # These final checks are correct, as they check Jac types
            # if type(doc_entry["summary"]) != "str" { doc_entry["summary"] = ""; }
            # if type(doc_entry["symbols"]) != "list" { doc_entry["symbols"] = []; }

            docs.append(doc_entry);
        }

        # build index summary
        index = {
            "repo": repo,
            "local_path": local_path,
            "summary": summary,
            "total_files": len(files),
            "by_language": lang_count
        };

        report {
            "status": "success",
            "data": {
                "index": index,
                "docs": docs,
                "errors": errors
            }
        };
    }
}