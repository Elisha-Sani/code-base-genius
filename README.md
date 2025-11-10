# 📚 Codebase Genius

Codebase Genius is an **agentic code‑documentation system** built with **JacLang** and multi‑agent orchestration.  
Given a GitHub repository URL, it automatically maps the repo, analyzes source code, and generates high‑quality Markdown documentation with summaries, diagrams, and API references.

---

## ✨ Features
- 🔗 **Supervisor (CodeGenius)** orchestrates the pipeline end‑to‑end
- 📂 **RepoMapper** clones repositories, builds file trees, and summarizes README files
- 🧩 **Analyzer** parses source files, extracts symbols, and builds a Code Context Graph (CCG)
- 📝 **DocGenie** synthesizes professional Markdown documentation with tables, diagrams, and clear prose
- ⚙️ **Rate Limiter** ensures safe and efficient LLM calls
- 🌐 **Jac Server API** exposes endpoints for triggering documentation generation

---

## 🚀 Getting Started

### 1. Clone the repository
```bash
git clone https://github.com/Elisha-Sani/code-base-genius.git
cd code-base-genius
```

### 2. Backend Setup
See [BE/README.md](./BE/README.md) for backend setup instructions.

### 3. Frontend Setup
See [FE/stremlit-app/README.md](./FE/stremlit-app/README.md) for frontend setup instructions.

---

## 🧭 Usage
1. Send a POST request to the Jac server with a GitHub repo URL:
   ```json
   {
     "walker": "CodeGenius",
     "params": { "repo_url": "https://github.com/owner/repo" }
   }
   ```
2. The pipeline runs through **mapping → analysis → documentation**.
3. Generated docs are saved under:  
   `./outputs/<repo_name>/docs.md`

---

## 📂 Project Structure
```
code-base-genius/
├── BE/                 # Backend root (JacLang agents + server)
├── FE/stremlit-app/    # Frontend (Streamlit UI)
├── outputs/            # Generated documentation
│   └── <repo_name>/docs.md
├── .env.example        # Example environment variables
├── .gitignore
├── README.md           # Root readme (project overview)
└── LICENSE
```

---

## 📊 Example Output
- **Repository Statistics Table** (files by language)
- **File Tree Explorer**
- **Mermaid Diagrams** showing architecture and code relationships
- **Markdown Documentation** with summaries, API references, and dependencies

---

## 🛠 Development Notes
- Optimized for **Python** and **Jac** repositories, but extensible to other languages.
- Uses **LLM‑based summarization** with normalization and error handling.
- Future work: integrate **Tree‑sitter** for deterministic parsing.