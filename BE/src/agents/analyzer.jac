import os;
import utils.parser as git_parser;
import from byllm.lib { Model }

glob gemini_llm = Model(model_name="gemini/gemini-2.0-flash");

"""Given file contents, produce a single concise one-sentence description of what the file does. Return EXACTLY one sentence, no trailing newline."""
def summarize_file(content: str) -> str by gemini_llm();

"""Given file contents, return a comma separated list of top symbols or identifiers (functions, classes, modules). Return plain text like: funcA,ClassB,CONST_C"""
def extract_top_symbols(content: str) -> str by gemini_llm();

walker RepoAnalyzer {
  has report_data: obj;  # the RepoMapper.data object

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

    # normalizers
    def norm_lang(l: str) -> str {
      if type(l) != "str" { return "unknown"; }
      ln = l.strip().lower();
      if ln in ["js","javascript\n","javascript\r"] { return "javascript"; }
      if ln in ["md","markdown\n"] { return "markdown"; }
      if ln == "" { return "unknown"; }
      return ln.replace("\n","").replace("\r","");
    }

    # counters and outputs
    lang_count = {};
    docs = [];
    errors = [];

    for file_obj in files {
      path = file_obj.get("path", "");
      raw_lang = file_obj.get("language", "unknown");
      content = file_obj.get("content", "");

      lang = norm_lang(raw_lang);

      # deterministic fallback for empty file or dotfiles
      if content == "" {
        if path.endswith(".gitkeep") or path.startswith(".") { lang = "text"; }
        if lang == "unknown" { lang = "text"; }
      }

      # increment counts
      lang_count[lang] = lang_count.get(lang, 0) + 1;

      # create doc entry
      doc_entry = {
        "path": path,
        "language": lang,
        "summary": "",
        "symbols": [],
        "size": len(content)
      };

      # best-effort extraction only for non-empty content
      if content != "" {
        # use deterministic regex heuristics for common languages first (quick)
        if lang == "javascript" or lang == "typescript" {
          # simple heuristic for top symbols
          tokens = [];
          # (pseudo) find function/class names -- keep small for runtime
          # fallback to LLM if heuristics produce nothing
          # (Note: Jac doesn't have full regex library in all runtimes; prefer LLM when in doubt)
          tokens_text = extract_top_symbols(content=content);
          if type(tokens_text) == "str" {
            cleaned = tokens_text.strip().replace("\n","").replace("\r","");
            if cleaned != "" { tokens = cleaned.split(","); }
          }
          if len(tokens) == 0 {
            # try summarizer for a concise description
            s = summarize_file(content=content);
            if type(s) == "str" { doc_entry["summary"] = s.strip(); }
            else { doc_entry["summary"] = ""; }
          } else {
            doc_entry["symbols"] = tokens;
            # also get a short summary
            s = summarize_file(content=content);
            if type(s) == "str" { doc_entry["summary"] = s.strip(); }
          }
        } else {
          # generic path: ask model for summary + symbols
          s = summarize_file(content=content);
          sym_text = extract_top_symbols(content=content);
          if type(s) == "str" { doc_entry["summary"] = s.strip(); }
          if type(sym_text) == "str" {
            cleaned = sym_text.strip().replace("\n","").replace("\r","");
            if cleaned != "" { doc_entry["symbols"] = cleaned.split(","); }
          }
        }
      } else {
        # empty content -> small deterministic summary
        doc_entry["summary"] = "Empty file";
      }

      # sanity canonicalization of summary and symbols
      if type(doc_entry["summary"]) != "str" { doc_entry["summary"] = ""; }
      if type(doc_entry["symbols"]) != "list" { doc_entry["symbols"] = []; }

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
