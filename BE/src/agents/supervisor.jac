import agents.mapper as mapper;
import agents.analyzer as analyzer;
import agents.genie as genie;
import utils.parser as git_parser;
import utils.rate_limiter as limiter;

walker CodeGenius {
    has repo_url: str;
    has final_result: dict = {};
    
    obj __specs__ {
        static has auth: bool = False;
    }

    can run_pipeline with `root entry {
        print("=" * 60);
        print(f"[CodeGenius] Starting pipeline for: {self.repo_url}");
        print("=" * 60);
        
        # Show rate limiter stats
        stats = limiter.gemini_rate_limiter.get_stats();
        print(f"[CodeGenius] Rate limiter status: {stats['available_calls']}/{stats['calls_per_minute_limit']} calls available");
        
        # --- STAGE 1: REPOSITORY MAPPING ---
        print("\n[Stage 1/3] Repository Mapping");
        print("-" * 40);
        
        mapper_walker = here spawn mapper.RepoMapper(url=self.repo_url);

        # Check mapper result
        if (not mapper_walker.result) or (mapper_walker.result.get("status") != "success") {
            print("[CodeGenius] ✗ Mapping stage failed");
            
            self.final_result = {
                "status": "error",
                "stage": "mapping",
                "message": mapper_walker.result.get("message", "Mapping failed") if mapper_walker.result else "Mapping failed",
                "repo_url": self.repo_url
            };
            
            report self.final_result;
            return;
        }
        
        mapper_data = mapper_walker.result.get("data", {});
        print(f"[CodeGenius] ✓ Mapping complete: {mapper_data.get('stats', {}).get('total_files', 0)} files found");
        
        
        # --- STAGE 2: CODE ANALYSIS ---
        print("\n[Stage 2/3] Code Analysis");
        print("-" * 40);
        
        analyzer_walker = here spawn analyzer.RepoAnalyzer(return_data=mapper_data);

        # Check analyzer result
        if (not analyzer_walker.result) or (analyzer_walker.result.get("status") != "success") {
            print("[CodeGenius] ✗ Analysis stage failed");
            
            self.final_result = {
                "status": "error",
                "stage": "analysis",
                "message": analyzer_walker.result.get("message", "Analysis failed") if analyzer_walker.result else "Analysis failed",
                "repo_url": self.repo_url
            };
            
            # Clean up temporary repo
            local_path = mapper_data.get("local_path", "");
            if local_path {
                git_parser.cleanup_repo(local_path);
                print(f"[CodeGenius] Cleaned up temp directory: {local_path}");
            }
            
            report self.final_result;
            return;
        }
        
        analyzer_data = analyzer_walker.result.get("data", {});
        analysis_index = analyzer_data.get("index", {});
        print(f"[CodeGenius] ✓ Analysis complete: {analysis_index.get('code_files', 0)} code files analyzed");


        # --- STAGE 3: DOCUMENTATION GENERATION ---
        print("\n[Stage 3/3] Documentation Generation");
        print("-" * 40);
        
        genie_walker = here spawn genie.DocGenie(analysis_data=analyzer_data);

        # Check genie result
        if (not genie_walker.result) or (genie_walker.result.get("status") != "success") {
            print("[CodeGenius] ✗ Documentation generation failed");
            
            self.final_result = {
                "status": "error",
                "stage": "generation",
                "message": genie_walker.result.get("message", "Doc generation failed") if genie_walker.result else "Doc generation failed",
                "repo_url": self.repo_url
            };
            
            # Clean up temporary repo
            local_path = mapper_data.get("local_path", "");
            if local_path {
                git_parser.cleanup_repo(local_path);
                print(f"[CodeGenius] Cleaned up temp directory: {local_path}");
            }
            
            report self.final_result;
            return;
        }

        print("[CodeGenius] ✓ Documentation generated successfully");
        
        
        # --- STAGE 4: CLEANUP & FINAL REPORT ---
        print("\n[Cleanup] Removing temporary files");
        print("-" * 40);
        
        local_path = mapper_data.get("local_path", "");
        if local_path {
            git_parser.cleanup_repo(local_path);
            print(f"[CodeGenius] ✓ Cleaned up: {local_path}");
        }
        
        # Build comprehensive final result
        genie_data = genie_walker.result.get("data", {});
        langs_dict = analysis_index.get("by_language", {});
        languages = [];
        for lang in langs_dict {
            languages.append(lang);
        }

        
        self.final_result = {
            "status": "success",
            "repo_url": self.repo_url,
            "pipeline_stages": {
                "mapping": "success",
                "analysis": "success",
                "generation": "success"
            },
            "output": {
                "markdown_file": genie_data.get("markdown_file", ""),
                "content_length": genie_data.get("content_length", 0),
                "files_analyzed": analysis_index.get("total_files", 0),
                "code_files": analysis_index.get("code_files", 0),
                "languages": languages
            },
            "message": "Documentation generated successfully"
        };
        
        # Show final stats
        final_stats = limiter.gemini_rate_limiter.get_stats();
        print(f"\n[CodeGenius] API calls used: {final_stats['calls_in_window']}/{final_stats['calls_per_minute_limit']}");
        
        print("=" * 60);
        print("[CodeGenius] Pipeline completed successfully!");
        print("=" * 60);
        
        report self.final_result;
    }
}