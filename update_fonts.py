import os
import re

def update_font_sizes(directory):
    # Pattern to match CustText(..., size: X.Y, ...)
    # It captures the prefix, the digit before dot, the digit after dot, and the suffix
    pattern = re.compile(r"(CustText\s*\([^)]*size:\s*)(\d)\.(\d)(\D)")
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart"):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, "r", encoding="utf-8") as f:
                        content = f.read()
                    
                    new_content = pattern.sub(r"\1\2\3\4", content)
                    
                    if new_content != content:
                        with open(filepath, "w", encoding="utf-8") as f:
                            f.write(new_content)
                        print(f"Updated: {filepath}")
                except Exception as e:
                    print(f"Error processing {filepath}: {e}")

if __name__ == "__main__":
    update_font_sizes('lib')
