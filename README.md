---

# 📚 Codebase Genius

Codebase Genius is an **agentic code‑documentation system** built with **JacLang** and multi‑agent orchestration. Given a GitHub repository URL, it automatically maps the repo, analyzes source code, and generates high‑quality Markdown documentation with summaries, diagrams, and API references.

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

### 2. Create a virtual environment
```bash
python3 -m venv venv
source venv/bin/activate   # Linux/Mac
venv\Scripts\activate      # Windows
```

### 3. Install dependencies
```bash
pip install -r requirements.txt
```

### 4. Configure environment variables
Create a `.env` file in the project root and set your LLM provider key:
```
GEMINI_API_KEY=your_api_key_here
```

### 5. Run the Jac server
```bash
jac serve supervisor.jac
```

This launches the backend server exposing walkers such as `CodeGenius`.

---

## 🧭 Usage

1. Send a POST request to the Jac server with a GitHub repo URL:
   ```json
   {
     "walker": "CodeGenius",
     "params": {
       "repo_url": "https://github.com/owner/repo"
     }
   }
   ```
2. The pipeline runs through **mapping → analysis → documentation**.  
3. Generated docs are saved under:
   ```
   ./outputs/<repo_name>/docs.md
   ```

---

## 📁 Project Structure
```
code-base-genius/
├── BE/                          # Backend root
│   ├── src/                     # All Jac source files and utilities
│   │   ├── agents/              # Agent walkers
│   │   │   ├── mapper.jac       # RepoMapper agent
│   │   │   ├── analyzer.jac     # RepoAnalyzer agent
│   │   │   ├── genie.jac        # DocGenie agent
│   │   │   └── supervisor.jac   # CodeGenius orchestrator (Supervisor)
│   │   ├── utils/               # Helper modules
│   │   │   ├── parser.jac       # Git repo parser/cleanup
│   │   │   ├── rate_limiter.jac # LLM call limiter
│   │   │   └── __init__.jac     # optional init
│   │   └── __init__.jac         # marks src as a Jac package
│   ├── requirements.txt         # Python deps for Jac server + utils
│   ├── .env.example             # Example environment variables
│   ├── .gitignore
│   └── README.md                # Backend-specific readme
│
├── FE/                          # Frontend (Next.js 16)
│                 # Frontend-specific readme
│
├── outputs/                     # Generated documentation
│   └── <repo_name>/docs.md
│
├── README.md                    # Root readme (project overview)
└── LICENSE
```

---

## 📊 Example Output

- **Repository Statistics Table** (files by language)  
- **File Tree Explorer**  
- **Mermaid Diagrams** showing architecture and code relationships  
- **Markdown Documentation** with summaries, API references, and dependencies  

---

## 🛠️ Development Notes

- Optimized for **Python** and **Jac** repositories, but extensible to other languages.  
- Uses **LLM‑based summarization** with normalization and error handling.  
- Future work: integrate **Tree‑sitter** for deterministic parsing.  

---

