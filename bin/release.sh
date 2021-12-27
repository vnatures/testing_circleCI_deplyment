export yellow="\033[1;33m"
export red="\033[1;31m"
export cyan="\033[1;36m"
export green="\033[1;32m"
export reset="\033[m"


# ensure we're not double tagging
CURRENT_TAG=$(git tag --points-at HEAD)
OG_BRANCH=$(git symbolic-ref --short -q HEAD)
if [ -n "$CURRENT_TAG" ]; then
  echo "${red}Can't tag this commit again. Commit already tagged with ${CURRENT_TAG}."
  exit 1
fi
if [ "$OG_BRANCH" != 'staging' ] || [[ -n $(git status -s) ]]; then # not sure we need
  echo "${red}Make sure you're on clean staging branch before running release."
  exit 1
fi

echo "${cyan}cd to temp repo"
REPO_NAME=$(git remote get-url origin)
git clone $REPO_NAME temp_repo
cd temp_repo

echo "${yellow}pull last changes on master and staging${reset}"
git fetch --tags
git checkout master
git pull --set-upstream --rebase
git checkout staging
git pull --set-upstream --rebase

echo "${yellow}tag staging branch${reset}"
LAST_COMMIT_SEMVER=$(git log --format=oneline -n 1 $(git rev-parse HEAD)  | sed -n 's/.*\[\(major|minor|patch\)\].*/\1/p')
npm version ${LAST_COMMIT_SEMVER:=minor} -m "version %s [skip ci]"
TAGGED_VERSION=$(awk '/version/{gsub(/("|",)/,"",$2);print $2};' package.json)

echo "${yellow}rebase master and merge (ff)${reset}"
git rebase staging master

echo "${yellow}push changes${reset}"
git push origin staging
git push origin master
git push origin tag v$TAGGED_VERSION

# debug
git log --all --color --oneline --decorate --graph -n 15

echo "${cyan}clean temp repo"
cd ..
cd rm -rf temp_repo
git fetch origin master:master
git fetch origin staging:staging


echo "${green}Release v${TAGGED_VERSION} successfuly pushed"