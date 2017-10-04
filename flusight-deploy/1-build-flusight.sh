#!/usr/bin/env bash

# Build flusight
set -e

# Change branding and metadata of website
rm -rf ./flusight-master/config.yaml
mv ./config.yaml ./flusight-master

cd ./flusight-master

# Clean footer
sed -i '/.modal#dis/,/footer.modal-card/d' ./src/components/Foot.vue
sed -ni '/and dis/{s/.*//;x;d;};x;p;${x;p;}' ./src/components/Foot.vue
sed -i '/let showModa/,/})$/d' ./src/components/Foot.vue

# Clean navbar
sed -i '/a($/,/logo")$/d' ./src/components/Navbar.vue
sed -i '/padding-left/,/border-left-width/d' ./src/components/Navbar.vue
sed -i '/href="branding.aboutUrl"/,/span Source/d' ./src/components/Navbar.vue
sed -i 's/span.brand.title-text {{ branding.title }}/a.brand.title-text(v-bind:href="branding.parentUrl") {{ branding.title }}/'\
    ./src/components/Navbar.vue

# Change text above map
# CDC FluSight Network Collaborative Ensemble
sed -i 's/| Real-time <b>Influenza Forecasts<\/b>/a(v-bind:href="branding.parentUrl") CDC FluSight Network/' ./src/components/Panels.vue
sed -i 's/CDC FluSight Challenge/Collaborative Ensemble/' ./src/components/Panels.vue
sed -i "/computed/a...mapGetters(['branding'])," ./src/components/Panels.vue

# Clean footer text from bottom of score table
sed -i '/.score-footer$/,/Calculated using the most/d' ./src/components/Panels/TimeChart.vue

# Change max heap size
sed -i 's/node build\/build.js/node --max_old_space_size=6000 build\/build.js/' ./package.json

# Build the site
yarn run build
cp -r ./dist/* ../../ # Copy to repo root
cd .. # in ./flusight-deploy
rm -rf ./flusight-master
