import agents.supervisor as SupervisorModule;

walker generate_docs {
    has repo_url: str;

    obj __specs__ {
        static has auth: bool = False;
    }

    can run with `root entry {
        print(f"API: Received request for {self.repo_url}");

        supervisor = here spawn SupervisorModule.CodeGenius(repo_url=self.repo_url);

        # Access the final_result attribute from the walker
        if supervisor.final_result {
            report supervisor.final_result;
        } else {
            # Fallback if no result was set
            report {
                "status": "error",
                "message": "Supervisor completed but returned no result"
            };
        }
    }
}