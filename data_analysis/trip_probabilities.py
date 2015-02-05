import argparse
import sys
import pandas
import time
import os
import json

class CSVParser:

    def __init__(self, filename):
        print 'reading file'

        self.hours = []
        self.stations = set()

        # 24 dictionaries of string to dictionary
        for i in range(24):
            self.hours.append(dict())

        lines = pandas.read_csv(args.filename)
        print len(lines.index)
        #for i in range(100000):
        for i in range(len(lines.index)):
            self.process_line(lines.loc[i])

        # Compute transition matrix
        stationIndices = dict()
        index = 0
        for station in self.stations:
            stationIndices[station] = index
            index += 1
        print len(stationIndices)


        f = open(filename + '.matrix', 'w')
        for hour in self.hours:
            matrix = []
            matrix = [[0 for l in range(len(stationIndices))] for k in range(len(stationIndices))]
            for i in hour.iterkeys():
                outgoingTrips = 0.0
                for j in hour[i].values():
                    outgoingTrips += j


                for j in hour[i].iterkeys():
                    matrix[stationIndices[i]][stationIndices[j]] = hour[i][j] / outgoingTrips

            f.write(self.string_matrix(matrix))

    def process_line(self, line):
        current_hour = time.strptime(line['starttime'], '%Y-%m-%d %H:%M:%S').tm_hour

        start_station = line['start station name']
        end_station = line['end station name']

        hour = self.hours[current_hour]

        if start_station not in hour:
            hour[start_station] = dict()

        if end_station not in hour[start_station]:
            hour[start_station][end_station] = 0

        self.stations.add(start_station)
        self.stations.add(end_station)

        hour[start_station][end_station] += 1

    def string_matrix(self, matrix):
        ret = ''
        for row in matrix:
            ret += ' '.join(map(str, row)) + '\n'
        return ret

parser = argparse.ArgumentParser()
parser.add_argument('filename', nargs='?')
args = parser.parse_args()
if args.filename:
    #json_file = args.filename + '.json'
    csvparser = CSVParser(args.filename)

else:
    parser.print_help()

