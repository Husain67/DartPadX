git rm -r --cached dartmini/
echo "dartmini/" >> .gitignore
git add .gitignore
git commit -m "Remove dartmini from git tracking to prevent large diff warnings"
