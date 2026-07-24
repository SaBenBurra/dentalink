import re

file_path = "lib/data/datasources/mock_datasource.dart"
with open(file_path, "r") as f:
    content = f.read()

# Remove branch and imageUrls from QuestionPostModel
def remove_args(match):
    block = match.group(0)
    block = re.sub(r'^\s*branch:.*?\n', '', block, flags=re.MULTILINE)
    block = re.sub(r'^\s*imageUrls:.*?\n', '', block, flags=re.MULTILINE)
    return block

content = re.sub(r'QuestionPostModel\([\s\S]*?\);', remove_args, content)

with open(file_path, "w") as f:
    f.write(content)
print("Done")
