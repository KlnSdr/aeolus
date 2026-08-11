echo "building /"
cd resource/frontend || exit
make build
rm -rf ../static
mkdir "../static"
cp index.html ../static/index.html
cp elm.js ../static/elm.js
cp favicon.png ../static/favicon.png