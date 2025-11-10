import agents.supervisor as SupervisorModule;

walker generate_docs {
    has repo_url: str;

    obj __specs__ {
        static has auth: bool = False;
    }

    can run with `root entry {
        print("╔════════════════════════════════════════════════════════════╗");
        print("║         CODEBASE GENIUS - Documentation Generator         ║");
        print("╚════════════════════════════════════════════════════════════╝");
        print(f"\n[API] Received documentation request");
        print(f"[API] Repository: {self.repo_url}");
        print("");

        # Validate input
        if not self.repo_url or self.repo_url == "" {
            error_result = {
                "status": "error",
                "message": "Repository URL is required",
                "code": "MISSING_URL"
            };
            print("[API] ✗ Error: Missing repository URL");
            report error_result;
            return;
        }
        
        # Basic URL validation
        if not (self.repo_url.startswith("http://") or self.repo_url.startswith("https://")) {
            error_result = {
                "status": "error",
                "message": "Invalid repository URL. Must start with http:// or https://",
                "code": "INVALID_URL"
            };
            print(f"[API] ✗ Error: Invalid URL format");
            report error_result;
            return;
        }

        # Spawn supervisor walker - it executes immediately
        print("[API] Spawning CodeGenius supervisor walker...\n");
        
        supervisor = here spawn SupervisorModule.CodeGenius(repo_url=self.repo_url);

        # Access the final result from supervisor
        if supervisor.final_result and supervisor.final_result.get("status") == "success" {
            print("\n[API] ✓ Pipeline completed successfully");
            print(f"[API] Output file: {supervisor.final_result.get('output', {}).get('markdown_file', 'N/A')}");
            print(f"[API] Files analyzed: {supervisor.final_result.get('output', {}).get('files_analyzed', 0)}");
            
            report supervisor.final_result;
            
        } elif supervisor.final_result {
            # Pipeline failed at some stage
            print(f"\n[API] ✗ Pipeline failed at stage: {supervisor.final_result.get('stage', 'unknown')}");
            print(f"[API] Error: {supervisor.final_result.get('message', 'Unknown error')}");
            
            report supervisor.final_result;
            
        } else {
            # Unexpected: no result at all
            fallback_result = {
                "status": "error",
                "message": "Pipeline completed but returned no result",
                "code": "NO_RESULT",
                "repo_url": self.repo_url
            };
            
            print("[API] ✗ Error: Pipeline returned no result");
            report fallback_result;
        }
        
        print("\n" + "─" * 60);
    }
}