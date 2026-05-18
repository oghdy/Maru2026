import pandas as pd
from kiwipiepy import Kiwi

# Initialize Kiwi
# Kiwi() loads the default model and dictionary
kiwi = Kiwi()

def parse_csv(file_path: str):
    print(f"Reading {file_path}...")
    df = pd.read_csv(file_path)
    
    for index, row in df.iterrows():
        sentence = row['Sentence']
        target_pos = row['Target_POS']
        
        print(f"\n[{index+1}] Sentence: '{sentence}' | Target: '{target_pos}'")
        print("-" * 50)
        
        # Tokenize using Kiwi
        # kiwi.tokenize returns a list of Token objects
        tokens = kiwi.tokenize(sentence)
        for token in tokens:
            # mark visually if this token is our target POS
            is_target_marker = "<-- TARGET" if token.tag == target_pos else ""
            print(f"  Token: '{token.form}'\tPOS: {token.tag}\t{is_target_marker}")

if __name__ == "__main__":
    parse_csv("curriculum.csv")
