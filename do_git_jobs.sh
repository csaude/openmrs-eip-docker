commit_message=$1

git add .
git commit -m "$commit_message"
git push origin develop
git checkout prod_test
git pull origin develop
git push origin prod_test
git checkout develop
