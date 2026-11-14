#!/data/data/com.termux/files/usr/bin/bash
set -e
cd "$HOME/pagaille"
if ! command -v gh >/dev/null 2>&1; then echo 'Installe GitHub CLI : pkg install gh'; exit 1; fi
if ! gh auth status >/dev/null 2>&1; then echo 'Connecte GitHub : gh auth login'; exit 1; fi
if [ ! -d .git ]; then git init -b main; fi
git add .
if ! git diff --cached --quiet; then git -c user.name='janintibo-art' -c user.email='actions@users.noreply.github.com' commit -m 'V2 Pagaille jeu de réflexion'; fi
if ! gh repo view janintibo-art/pagaille >/dev/null 2>&1; then
  gh repo create janintibo-art/pagaille --public --source=. --remote=origin --push
else
  if ! git remote get-url origin >/dev/null 2>&1; then git remote add origin https://github.com/janintibo-art/pagaille.git; fi
  git push -u origin main
fi
