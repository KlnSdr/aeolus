# rm -rf resource/static
# mkdir resource/static

echo "building /"
cd resource/static || exit
# ed pack
tsc
# cp -r docs/* ../resource/static
# rm -rf docs

# perl -i -pe 'next if /src="https/; s/src="/src="{{CONTEXT}}\//g' index.html
# perl -i -pe 'next if /src="https/; s/src="/src="{{CONTEXT}}\//g' ../resource/static/index.html

# perl -i -pe 'next if /href="https/; s/href="/href="{{CONTEXT}}\//g' index.html
# perl -i -pe 'next if /href="https/; s/href="/href="{{CONTEXT}}\//g' ../resource/static/index.html