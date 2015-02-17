import argparse
import sys
import pandas
import time
import os
import json
import numpy

class CSVParser:

    def __init__(self, filename):
        self.hours = []
        self.stations = set()

        self.startStations = []
        self.tripTotals = []

        # 24 dictionaries of string to dictionary
        for i in range(24):
            self.hours.append(dict())
            self.startStations.append(dict())
            self.tripTotals.append(dict())

        lines = pandas.read_csv(args.filename)
        for i in range(len(lines.index)):
            self.process_line(lines.loc[i])

        # Compute transition matrix
        stationIndices = dict()
        index = 0
        for station in self.stations:
            stationIndices[station] = index
            index += 1

        # Output transition matrix
        f = open(filename + '.matrix', 'w')
        g = open(filename + '_start.matrix', 'w')
        h = open(filename + '_tripcounts.matrix', 'w')
        for hr in range(24):
            hour = self.hours[hr]
            matrix = [[0 for l in range(len(stationIndices))] for k in range(len(stationIndices))]
            for i in hour.iterkeys():
                outgoingTrips = 0.0
                for j in hour[i].values():
                    outgoingTrips += j

                for j in hour[i].iterkeys():
                    matrix[stationIndices[i]][stationIndices[j]] = hour[i][j] / outgoingTrips

            f.write(self.string_matrix(matrix))

            # Output the overall distribution of start stations
            start = self.startStations[hr]
            outgoingTrips = sum(start.values())
            start_probabilities = [0 for l in range(len(stationIndices))]
            for station in start.keys():
                total = start[station]
                start_probabilities[stationIndices[station]] = total / float(outgoingTrips)

            g.write(self.string_vector(start_probabilities))


        # Output the distributions of trips for each hour
        m = [[numpy.mean(x.values()), numpy.var(x.values())] for x in self.tripTotals]
        h.write(self.string_matrix(m))

    def process_line(self, line):
        current_hour = time.strptime(line['starttime'], '%Y-%m-%d %H:%M:%S').tm_hour
        current_day = time.strptime(line['starttime'], '%Y-%m-%d %H:%M:%S').tm_yday

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

        # Keep track of probability of starting at each station
        if start_station not in self.startStations[current_hour]:
            self.startStations[current_hour][start_station] = 0

        self.startStations[current_hour][start_station] += 1

        if current_day not in self.tripTotals[current_hour]:
            self.tripTotals[current_hour][current_day] = 0

        self.tripTotals[current_hour][current_day] += 1

    def string_matrix(self, matrix):
        ret = ''
        for row in matrix:
            ret += ' '.join(map(str, row)) + '\n'
        return ret

    def string_vector(self, vec):
        ret = ''
        for row in vec:
            ret += str(row) + '\n'
        return ret


parser = argparse.ArgumentParser()
parser.add_argument('filename', nargs='?')
args = parser.parse_args()
if args.filename:
    #json_file = args.filename + '.json'
    csvparser = CSVParser(args.filename)

else:
    parser.print_help()

