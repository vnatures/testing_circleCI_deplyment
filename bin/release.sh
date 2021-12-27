export yellow="\033[1;33m"
export red="\033[1;31m"
export cyan="\033[1;36m"
export green="\033[1;32m"
export reset="\033[m"

OG_BRANCH=$(git symbolic-ref --short -q HEAD)
if [ "$OG_BRANCH" != 'staging' ] || [[ -n $(git status -s) ]] || [[ -n $(git log origin/staging..staging) ]]; then
  echo "${red}Make sure you're on synced clean staging branch before running release."
  exit 1
fi

REPO_NAME=$(git remote get-url origin)
echo "${cyan}cd to temp repo\n"
git clone $REPO_NAME temp_repo
cd temp_repo

echo "${yellow}fetch lastest changes on master, staging and tags${reset}\n"
git fetch --tags
git checkout master
git pull --set-upstream --rebase
git checkout staging
git pull --set-upstream --rebase

# ensure we're not double tagging
echo "${cyan}validate double tag${reset}\n"
CURRENT_TAG=$(git tag --points-at HEAD)
if [ -n "$CURRENT_TAG" ]; then
  echo "${red}Can't tag this commit again. Commit already tagged with ${CURRENT_TAG}."
  exit 1
fi


echo "${yellow}tag staging branch${reset}\n"
LAST_COMMIT_SEMVER=$(git log --format=oneline -n 1 $(git rev-parse HEAD)  | sed -n 's/.*\[\(major|minor|patch\)\].*/\1/p')
npm version ${LAST_COMMIT_SEMVER:=minor} -m "version %s [skip ci]"
TAGGED_VERSION=$(awk '/version/{gsub(/("|",)/,"",$2);print $2};' package.json)

echo "${yellow}rebase master and merge (ff)${reset}\n"
git rebase staging master

echo "${yellow}push changes${reset}\n"
git push origin staging
git push origin master
git push origin tag v$TAGGED_VERSION

git log --all --color --oneline --decorate --graph -n 20

echo "${cyan}clean temp repo\n"
cd ..
echo $(pwd)
cd rm -rf temp_repo
git fetch origin master:master
git fetch origin staging:staging


echo "${green}Release v${TAGGED_VERSION} successfuly pushed"