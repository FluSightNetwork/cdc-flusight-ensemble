#!/usr/bin/env fish

# Tests involving reading the csvs
set -g error 0

# Check if all the 2014-2015 CSVs have bins for week 53
function test_bin_53
    set -l bin_counts (cat $argv[1] | grep -E "week\"?,\"?53" | wc -l)
    if [ $bin_counts != "22" ]
        echo "✖ Absent bin 53 in $argv[1]"
        set -g error 1
    end
end

for csv in (ls ./model-forecasts/component-models/*/*.csv | grep "EW[4-5][0-9]-2014\|EW[0-2][0-9]-2015")
    test_bin_53 $csv
end

for csv in (ls ./model-forecasts/cv-ensemble-models/*/*.csv | grep "EW[4-5][0-9]-2014\|EW[0-2][0-9]-2015")
    test_bin_53 $csv
end

for csv in (ls ./model-forecasts/real-time-component-models/*/*.csv | grep "EW[4-5][0-9]-2014\|EW[0-2][0-9]-2015")
    test_bin_53 $csv
end

for csv in (ls ./model-forecasts/real-time-ensemble-models/*/*.csv | grep "EW[4-5][0-9]-2014\|EW[0-2][0-9]-2015")
    test_bin_53 $csv
end

# Check if the latest season has bin 52,53 and not 52,1
function test_bin_52
    cat $argv[1] | egrep "week\"?,\"?52\"?,\"?1" >> /dev/null
    if test $status -eq 0
        echo "✖ Found bin 52,1 in $argv[1]"
        set -g error 1
    end
end

for csv in (ls ./model-forecasts/real-time-component-models/*/*.csv | grep -v "UTAustin")
    test_bin_52 $csv
end

# Check that there is no NaN,NaN (should be NA,NA)
function test_nan
    cat $argv[1] | grep "NaN" >> /dev/null
    if test $status -eq 0
        echo "✖ Found NaN in $argv[1]"
        set -g error 1
    end
end

for csv in ./model-forecasts/real-time-component-models/*/*.csv
    test_nan $csv
end

if test $error -eq 0
    echo "✓ All tests passed"
else
    exit 1
end
