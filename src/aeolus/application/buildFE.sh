echo "building /"
cd resource/frontend || exit
make build
rm -rf ../static
mkdir "../static"
cp index.html ../static/index.html
cp main.js ../static/main.js