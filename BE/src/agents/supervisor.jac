import agents.mapper as mapper;
import agents.analyzer as analyzer;
import agents.genie as genie;
import utils.parser as git_parser;

walker CodeGenius {
    has repo_url: str;
    has final_result: dict = {};  # This stores the result for parent walker access

    obj __specs__ {
        static has auth: bool = False;
    }

    can run_pipeline with `root entry {
        
        # --- 1. MAPPING ---
        print(f"Supervisor: Spawning RepoMapper for {self.repo_url}");
        
        # Spawn walker - it executes immediately due to entry decorator
        mapper_walker = here spawn mapper.RepoMapper(url=self.repo_url);

        # Check the .result attribute of the walker
        if (not mapper_walker.result) or (mapper_walker.result.get("status") != "success") {
            print("Supervisor: RepoMapper failed.");
            # CRITICAL: Store in self.final_result before reporting
            self.final_result = {
                "status": "error",
                "stage": "mapping",
                "message": mapper_walker.result.get("message", "Mapping failed") if mapper_walker.result else "Mapping failed"
            };
            report self.final_result;
            return;
        }
        
        # Get the data from the .result attribute
        mapper_data = mapper_walker.result.get("data", {});
        print("Supervisor: RepoMapper finished successfully.");

        
        # --- 2. ANALYSIS ---
        print("Supervisor: Spawning RepoAnalyzer...");
        analyzer_walker = here spawn analyzer.RepoAnalyzer(return_data=mapper_data);

        # Check the .result attribute
        if (not analyzer_walker.result) or (analyzer_walker.result.get("status") != "success") {
            print("Supervisor: RepoAnalyzer failed.");
            # CRITICAL: Store in self.final_result before reporting
            self.final_result = {
                "status": "error",
                "stage": "analysis",
                "message": analyzer_walker.result.get("message", "Analysis failed") if analyzer_walker.result else "Analysis failed"
            };
            git_parser.cleanup_repo(mapper_data.get("local_path"));
            report self.final_result;
            return;
        }
        
        # Get the data from the .result attribute
        analyzer_data = analyzer_walker.result.get("data", {});
        print("Supervisor: RepoAnalyzer finished successfully.");


        # --- 3. DOCUMENTATION GENERATION ---
        print("Supervisor: Spawning DocGenie...");
        genie_walker = here spawn genie.DocGenie(analysis_data=analyzer_data);

        # Check the .result attribute
        if (not genie_walker.result) or (genie_walker.result.get("status") != "success") {
            print("Supervisor: DocGenie failed.");
            # CRITICAL: Store in self.final_result before reporting
            self.final_result = {
                "status": "error",
                "stage": "generation",
                "message": genie_walker.result.get("message", "Doc generation failed") if genie_walker.result else "Doc generation failed"
            };
            git_parser.cleanup_repo(mapper_data.get("local_path"));
            report self.final_result;
            return;
        }

        print("Supervisor: DocGenie finished successfully.");
        
        
        # --- 4. CLEANUP & FINAL REPORT ---
        git_parser.cleanup_repo(mapper_data.get("local_path"));
        print("Supervisor: Temporary repo cleaned up.");
        
        # CRITICAL: Store the final result in self.final_result BEFORE reporting
        self.final_result = genie_walker.result;
        report self.final_result;
    }
}