import json
import os
from generate_morphology import MorphologyGenerator

def inject():
    json_path = "/Users/hadohadopapi/Desktop/Maru-main/backend/lessons/unit1/lesson2.json"
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    gen = MorphologyGenerator()
    
    modified = False
    for step in data['steps']:
        if step['step_type'] == 'intro' and 'content' in step:
            if 'sentences' in step['content']:
                for s in step['content']['sentences']:
                    korean = s.get('korean', '')
                    if not korean:
                        continue
                        
                    print(f"Injecting chunks for: {korean}")
                    # Analyze and convert to dict for JSON
                    chunks = gen.analyze(korean)
                    s['chunks'] = [c.dict() for c in chunks]
                    modified = True
                    
    if modified:
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print("Successfully injected chunks into lesson1.json")
    else:
        print("No target sentences found to inject.")

if __name__ == "__main__":
    inject()
