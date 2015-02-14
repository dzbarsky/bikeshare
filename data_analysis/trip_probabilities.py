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

        self.startStations = []

        # 24 dictionaries of string to dictionary
        for i in range(24):
            self.hours.append(dict())
            self.startStations.append(dict())

        lines = pandas.read_csv(args.filename)
        print len(lines.index)
        # for i in range(100000):
        for i in range(len(lines.index)):
            self.process_line(lines.loc[i])

        # Compute transition matrix
        stationIndices = dict()
        index = 0
        for station in self.stations:
            stationIndices[station] = index
            index += 1
        print len(stationIndices)


        # Output transition matrix
        f = open(filename + '.matrix', 'w')
        g = open(filename + '_start.matrix', 'w')
        for hr in range(24):
            hour = self.hours[hr]
            matrix = []
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
            start_probabilities = [0 for l in range(len(stationIndices))]
            for station in start.keys():
                total = sum(start[station].values())
                start_probabilities[stationIndices[station]] = total / outgoingTrips

            g.write(self.string_vector(start_probabilities))


        # Output the distributions for each station
        for i in range(24):
            starts = self.startStations[i]

            for station in starts.keys():
                per_day_counts = starts[station].values()
                mean = sum(per_day_counts) / float(len(per_day_counts))
                variance = reduce(lambda acc, x: acc + (mean - x) ** 2, per_day_counts) / float(len(per_day_counts))
                print "Station: ", station, "Mean: ", mean, "Var: %s", variance
                print per_day_counts



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

        if start_station not in self.startStations[current_hour]:
            self.startStations[current_hour][start_station] = dict()

        if current_day not in self.startStations[current_hour][start_station]:
            self.startStations[current_hour][start_station][current_day] = 0

        self.startStations[current_hour][start_station][current_day] += 1

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

