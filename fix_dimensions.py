import os
import re

lib_dir = "lib"
app_dim_import = "import 'package:dentlink/core/constants/app_dimensions.dart';"

spacing_map = {
    2: "AppDimensions.spacing2",
    4: "AppDimensions.spacing4",
    6: "AppDimensions.spacing6",
    8: "AppDimensions.spacing8",
    10: "AppDimensions.spacing10",
    12: "AppDimensions.spacing12",
    16: "AppDimensions.spacing16",
    20: "AppDimensions.spacing20",
    24: "AppDimensions.spacing24",
    32: "AppDimensions.spacing32",
    40: "AppDimensions.spacing40",
    48: "AppDimensions.spacing48",
    56: "AppDimensions.spacing56",
    64: "AppDimensions.spacing64",
}

radius_map = {
    6: "AppDimensions.radiusSmall",
    10: "AppDimensions.radiusMedium",
    14: "AppDimensions.radiusLarge",
    20: "AppDimensions.radiusXLarge",
    999: "AppDimensions.radiusRound",
}

def replace_dimensions(text):
    modified = False
    
    # Replace SizedBox(height/width: X)
    def box_repl(match):
        nonlocal modified
        prop = match.group(1)
        val_str = match.group(2)
        val = float(val_str) if '.' in val_str else int(val_str)
        if val in spacing_map:
            modified = True
            return f"SizedBox({prop}: {spacing_map[val]})"
        return match.group(0)
    
    text = re.sub(r"SizedBox\(\s*(height|width)\s*:\s*(\d+(?:\.\d+)?)\s*\)", box_repl, text)

    # Replace EdgeInsets.all(X)
    def edge_all_repl(match):
        nonlocal modified
        val_str = match.group(1)
        val = float(val_str) if '.' in val_str else int(val_str)
        if val in spacing_map:
            modified = True
            return f"EdgeInsets.all({spacing_map[val]})"
        return match.group(0)

    text = re.sub(r"EdgeInsets\.all\(\s*(\d+(?:\.\d+)?)\s*\)", edge_all_repl, text)

    # Replace EdgeInsets kwargs (symmetric, only, fromLTRB)
    def edge_kwargs_repl(match):
        nonlocal modified
        method = match.group(1)
        args_str = match.group(2)
        
        def arg_repl(m):
            nonlocal modified
            key = m.group(1)
            val_str = m.group(2)
            val = float(val_str) if '.' in val_str else int(val_str)
            if val in spacing_map:
                modified = True
                return f"{key}: {spacing_map[val]}"
            return m.group(0)
            
        new_args = re.sub(r"([a-zA-Z0-9_]+)\s*:\s*(\d+(?:\.\d+)?)", arg_repl, args_str)
        return f"EdgeInsets.{method}({new_args})"
        
    text = re.sub(r"EdgeInsets\.(symmetric|only)\(([^)]+)\)", edge_kwargs_repl, text)
    
    # Replace Radius.circular(X)
    def radius_repl(match):
        nonlocal modified
        val_str = match.group(1)
        val = float(val_str) if '.' in val_str else int(val_str)
        if val in radius_map:
            modified = True
            return f"Radius.circular({radius_map[val]})"
        return match.group(0)
        
    text = re.sub(r"Radius\.circular\(\s*(\d+(?:\.\d+)?)\s*\)", radius_repl, text)
    
    return text, modified

def main():
    changed_files = 0
    for root, _, files in os.walk(lib_dir):
        if 'constants' in root:
            continue
        for file in files:
            if not file.endswith('.dart'): continue
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content, modified = replace_dimensions(content)
            
            if modified:
                # Add import if not present
                if "import 'package:dentlink/core/constants/app_dimensions.dart';" not in new_content and \
                   "import '../../../core/constants/app_dimensions.dart';" not in new_content and \
                   "import '../../core/constants/app_dimensions.dart';" not in new_content and \
                   "import '../core/constants/app_dimensions.dart';" not in new_content and \
                   "import 'core/constants/app_dimensions.dart';" not in new_content and \
                   "import '../../../../core/constants/app_dimensions.dart';" not in new_content:
                    
                    imports = list(re.finditer(r"^import\s+.*;", new_content, re.MULTILINE))
                    if imports:
                        last_import = imports[-1]
                        idx = last_import.end()
                        new_content = new_content[:idx] + f"\n{app_dim_import}" + new_content[idx:]
                    else:
                        new_content = f"{app_dim_import}\n" + new_content
                        
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                changed_files += 1
                print(f"Updated: {filepath}")
                
    print(f"Total files updated: {changed_files}")

if __name__ == '__main__':
    main()
