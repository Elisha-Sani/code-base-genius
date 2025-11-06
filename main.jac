import from byllm.lib { Model }
glob llm = Model(model_name="gemini/gemini-2.0-flash");

enum Personality {
    INTROVERT,
    EXTROVERT,
    AMBIVERT
}

def get_personality (name: str) -> Personality by llm();

with entry {
    name = "Albert Einsten";
    result = get_personality(name);
    print(f"{result} personality detected for {name}");
}