import re

file_path = "lib/data/datasources/mock_datasource.dart"

with open(file_path, "r") as f:
    content = f.read()

# We want to replace PostModel( with CasePostModel( if type: PostType.casePost is in the block,
# and with QuestionPostModel( if type: PostType.question is in the block.

# Split by "    PostModel("
parts = content.split("    PostModel(")
new_content = parts[0]

for part in parts[1:]:
    if "type: PostType.casePost" in part:
        new_content += "    CasePostModel(" + part
    elif "type: PostType.question" in part:
        new_content += "    QuestionPostModel(" + part
    else:
        new_content += "    PostModel(" + part

with open(file_path, "w") as f:
    f.write(new_content)
print("Done")
