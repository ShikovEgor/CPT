import cProfile
import json
import sys
from cpt.Cpt import Cpt


def main():
    mode, data_path, output_path = sys.argv[1:]  # pylint: disable=unbalanced-tuple-unpacking

    if data_path.endswith('.json'):
        with open(data_path) as file:
            data = list(json.load(file).values())
    else:
        with open(data_path) as file:
            data = [[int(x) for x in l.rstrip().split()]
                    for l in file.readlines()]

    cpt = Cpt()

    if mode == 'predict':
        *data, = map(lambda sequence: sequence[-10:], data)
        cpt.train(data)

    cProfile.runctx('cpt.{}(data)'.format(mode), None, locals(), output_path)


if __name__ == '__main__':
    main()
