# Build flusight
set -e

# Parse data model data files to flusight format
npm install
npm run parse-data

# Download flusight master
wget "https://github.com/reichlab/flusight/archive/master.zip"
unzip ./master.zip
rm ./master.zip

# Replace already present data and config
rm -rf ./flusight-master/data ./flusight-master/config.yaml
mv ./config.yaml ./flusight-master
mv ./data ./flusight-master

# Change branding and metadata of website
cd ./flusight-master

# Clean footer
sed -i '/.modal#dis/,/footer.modal-card/d' ./src/components/Foot.vue
sed -ni '/and dis/{s/.*//;x;d;};x;p;${x;p;}' ./src/components/Foot.vue
sed -i '/let showModa/,/})$/d' ./src/components/Foot.vue

# Clean navbar
sed -i '/a($/,/logo")$/d' ./src/components/Navbar.vue
sed -i '/padding-left/,/border-left-width/d' ./src/components/Navbar.vue
sed -i '/href="branding.aboutUrl"/,/span Source/d' ./src/components/Navbar.vue

# Change text above map
# CDC FluSight Network Collaborative Ensemble
sed -i 's/Real-time <b>Influenza Forecasts<\/b>/CDC FluSight Network/' ./src/components/Panels.vue
sed -i 's/CDC FluSight Challenge/Collaborative Ensemble/' ./src/components/Panels.vue

# Build the site
npm install
npm run get-actual
npm run parse
npm run test
npm run build
cp -r ./dist/* ../../ # Copy to repo root
cd .. # at ./flusight-deploy
