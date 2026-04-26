import os

path = 'lib/ui/main_screen.dart'
with open(path, 'r') as f:
    content = f.read()

# Fix const ExamplesGallery
content = content.replace("Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamplesGallery()));",
                          "Navigator.push(context, MaterialPageRoute(builder: (_) => ExamplesGallery()));")

with open(path, 'w') as f:
    f.write(content)
