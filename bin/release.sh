export yellow="\033[1;33m"
export red="\033[1;31m"
export cyan="\033[1;36m"
export green="\033[1;32m"
export reset="\033[m"

REPO_NAME=$(git remote get-url origin)
echo "\n${cyan}cd to temp repo${reset}"
git clone $REPO_NAME temp_repo
cd temp_repo

echo "\n${yellow}fetch lastest changes on master, staging and tags${reset}"
git fetch --tags
git checkout master
git pull --set-upstream --rebase origin master
git checkout staging
git pull --set-upstream --rebase origin staging

# ensure we're not double tagging
echo "\n${cyan}validate double tag${reset}"
CURRENT_TAG=$(git tag --points-at HEAD)
if [ -n "$CURRENT_TAG" ]; then
  echo "${red}Can't tag this commit again. Commit already tagged with ${CURRENT_TAG}."
  cd ..
  rm -rf temp_repo
  exit 1
fi

echo "\n${yellow}tag staging branch${reset}"
LAST_COMMIT_SEMVER=$(git log --format=oneline -n 1 $(git rev-parse HEAD)  | sed -n 's/.*\[\(major|minor|patch\)\].*/\1/p')
npm version ${LAST_COMMIT_SEMVER:=minor} -m "version %s [skip ci]"
TAGGED_VERSION=$(awk '/version/{gsub(/("|",)/,"",$2);print $2};' package.json)

echo "\n${yellow}rebase master and merge (ff)${reset}"
git rebase staging master

echo "\n${yellow}push changes${reset}"
git push origin staging
git push origin master
git push origin tag v$TAGGED_VERSION

git log --all --color --oneline --decorate --graph -n 20

echo "\n${cyan}clean temp repo${reset}"
cd ..
rm -rf temp_repo
git fetch origin master:master || git pull --rebase origin master
git fetch origin staging:staging || git pull --rebase origin staging

echo "\n${green}Release v${TAGGED_VERSION} successfuly pushed"