#!/usr/bin/env fish

# Script for checking if all the 2014-2015 CSVs have bins for week 53

function test_csv
    set -l bin_counts (less $argv[1] | grep -E "week\"?,\"?53" | wc -l)
    if [ $bin_counts != "22" ]
        echo "✖ Absent bin 53 in $argv[1]"
        exit 1
    end
end

for csv in (ls ./model-forecasts/component-models/*/*.csv | grep "EW[4-5][0-9]-2014\|EW[0-2][0-9]-2015")
    test_csv $csv
end
echo "✓ component-models okay"

for csv in (ls ./model-forecasts/cv-ensemble-models/*/*.csv | grep "EW[4-5][0-9]-2014\|EW[0-2][0-9]-2015")
    test_csv $csv
end
echo "✓ cv-ensemble-models okay"

for csv in (ls ./model-forecasts/real-time-component-models/*/*.csv | grep "EW[4-5][0-9]-2014\|EW[0-2][0-9]-2015")
    test_csv $csv
end
echo "✓ real-time-component-models okay"

for csv in (ls ./model-forecasts/real-time-ensemble-models/*/*.csv | grep "EW[4-5][0-9]-2014\|EW[0-2][0-9]-2015")
    test_csv $csv
end
echo "✓ real-time-ensemble-models okay"
