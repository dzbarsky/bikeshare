import argparse
import sys
import pandas
import time
import os
import json

# CSVParser is responsible for parsing the CSV into an intermediate form,
# to make future analyses faster.
class CSVParser:

    def __init__(self, filename):
        # We keep track of the historical trips and rebalances to create
        # summary statistics.
        self.historical_counts = dict()
        self.historical_rebalances = dict()
        self.station_counts = dict()
        self.bike_locations = dict()
        self.rebalances = dict()

        # Read and process all the lines in the file
        lines = pandas.read_csv(args.filename)
        self.current_date = time.strptime(lines.loc[0]['starttime'], '%Y-%m-%d %H:%M:%S')
        for i in range(len(lines.index)):
            self.process_line(lines.loc[i])

        f = open(filename + '.json', 'w')
        o = dict()
        o['historical_counts'] = self.historical_counts
        o['historical_rebalances'] = self.historical_rebalances
        f.write(json.dumps(o))

    # Process a single line of the CSV.
    def process_line(self, line):
        start_date = time.strptime(line['starttime'], '%Y-%m-%d %H:%M:%S')

        if time.mktime(start_date) - time.mktime(self.current_date) >= 24 * 60 * 60:
            # At least a day has elapsed, so reset our counts
            self.current_date = start_date
            for (k, v) in self.station_counts.iteritems():
                if k not in self.historical_counts:
                    self.historical_counts[k] = list()
                self.historical_counts[k].append(v)

            for (k, v) in self.rebalances.iteritems():
                if k not in self.historical_rebalances:
                    self.historical_rebalances[k] = list()
                self.historical_rebalances[k].append(v)

            self.station_counts = dict()
            self.rebalances = dict()

        start_station = line['start station name']
        end_station = line['end station name']
        bikeid = line['bikeid']
        # Keep track of where the bike came from so we know whether it has been
        # rebalanced
        if bikeid in self.bike_locations:
            prev_station = self.bike_locations[bikeid]
        else:
            prev_station = None

        self.bike_locations[bikeid] = end_station

        # If a rebalance occurred, record it.
        if prev_station and start_station is not prev_station:
            key = prev_station + "?" + start_station
            if key not in self.rebalances:
                self.rebalances[key] = 1
            else:
                self.rebalances[key] += 1

        if start_station not in self.station_counts:
            self.station_counts[start_station] = 0
        if end_station not in self.station_counts:
            self.station_counts[end_station] = 0

        # Change each station's respective flow for this day.
        self.station_counts[start_station] -= 1
        self.station_counts[end_station] += 1

# Data parser performs the actual analysis from the intermediate data
# representation. It prints the station followed by the average daily net flow.
class DataParser:

    def __init__(self, filename):
        f = open(filename)

        o = json.loads(f.read())
        self.historical_counts = o['historical_counts']
        self.historical_rebalances = o['historical_rebalances']

    def analyze(self):
        for (k, v) in self.historical_counts.iteritems():
            print k + "\t" + str(sum(v)/float(len(v)))

# Parsing the trips takes a while so only parse if the -f flag is passed
# or there were no previous intermediate results.  Otherwise, reuse
# the previous results.

parser = argparse.ArgumentParser()
parser.add_argument('filename', nargs='?')
parser.add_argument('-f', '--force',
                    help='force rereading of csv',
                    action='store_true')
args = parser.parse_args()
if args.filename:
    json_file = args.filename + '.json'
    if not os.path.isfile(json_file) or args.force:
        csvparser = CSVParser(args.filename)
    dataparser = DataParser(json_file)
    dataparser.analyze()

else:
    parser.print_help()

