with open("lib/providers/file_provider.dart", "r") as f:
    content = f.read()

content = content.replace("print('You entered: $input');", "print('You entered: \\$input');")

with open("lib/providers/file_provider.dart", "w") as f:
    f.write(content)
