git stash save --include-untracked # saves local un/stage changes

echo 'pull last changes on master and staging'
git checkout master
git pull -u --rebase
git checkout staging
git pull -u --rebase

echo 'tag staging branch'
LAST_COMMIT_SEMVER=$(git log --format=oneline -n 1 $CIRCLE_SHA1  | sed -n 's/.*\[\(major|minor|patch\)\].*/\1/p')
npm version ${LAST_COMMIT_SEMVER:=minor} -m "version %s [skip ci]"
TAGGED_VERSION=$(awk '/version/{gsub(/("|",)/,"",$2);print $2};' package.json)

echo 'rebase master and merge (ff)'
git rebase staging master
git merge master --ff-only

echo 'push changes'
git push -u origin staging
git push -u origin master
git push origin tag $TAGGED_VERSION

# debug
git log --all --color --oneline --decorate --graph -n 15

echo 'restore previous state'
git checkout -
git stash pop # restore un/stage changes