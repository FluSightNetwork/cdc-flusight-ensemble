import json
import glob
from collections import OrderedDict
from os import path

try:
    if path.exists('flusight-master/src/assets/data/history.json'):
        with open('flusight-master/src/assets/data/history.json', 'r') as f:
            data = json.load(f)

            # Getting the list of seasons that is already downloaded, i.e. 2003-2014
            oldYears = []
            for season in data['nat']:
                oldYears.append(season['season'])
            lst = glob.glob('flusight-master/src/assets/data/season-20*.json')
            lst.sort()
            for year in lst:
                year = year.strip('.json').split('season-')[1]

                # Skipping seasons that are already downloaded, i.e. 2003-2014
                if year in oldYears:
                    continue

                # Add data from 2015 and onwards to history.json file to be loaded up by the site
                with open('flusight-master/src/assets/data/season-'+year+'.json', 'r') as f2:
                    thisSeason = json.load(f2)
                    for key in data.keys():
                        seasonJSON = OrderedDict()
                        seasonJSON["season"] = year
                        seasonJSON["data"] = []
                        for region in thisSeason['regions']:
                            if region['id']!=key:
                                continue
                            for weeks in region['actual']:
                                season = OrderedDict()
                                season["week"] = weeks['week']
                                season["data"] = weeks['actual']
                                seasonJSON["data"].append(season)
                        data[key].append(seasonJSON)
                    with open('flusight-master/src/assets/data/history.json', 'w') as fp:
                        json.dump(data, fp, indent=2, separators=(',', ': '))
                        fp.close()
                    f2.close()
            f.close()
except ValueError as ex:
    logging.exception('Caught an error')
