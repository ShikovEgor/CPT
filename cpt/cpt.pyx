# distutils: language = c++
from libcpp.vector cimport vector
from libcpp.queue cimport queue
from libcpp cimport bool
from itertools import combinations
from libcpp.iterator cimport back_inserter

from cpt.prediction_tree cimport PredictionTree, Node, ROOT
from cpt.alphabet cimport Alphabet
from cpt.alphabet cimport NOT_AN_INDEX
from cpt.scorer cimport Scorer
from cpt.bitset cimport Bitset

ctypedef vector[int] test

cdef extern from "<algorithm>" namespace "std" nogil:
    Iter find[Iter](Iter first, Iter last, int val)
    Iter remove[Iter](Iter first, Iter last, int val)
    Iter2 remove_copy[Iter, Iter2](Iter first, Iter second, Iter2 third, int val)

cdef class Cpt:
    def __cinit__(self, int split_length=0, int max_level=1):
        self.tree = PredictionTree()
        self.inverted_index = vector[Bitset]()
        self.lookup_table = vector[Node]()
        self.split_index = -split_length
        self.max_level = max_level
        self.alphabet = Alphabet()

    def train(self, sequences):

        number_train_sequences = len(sequences)
        cdef Node current
        for id_seq, sequence in enumerate(sequences):
            current = ROOT
            for index in map(self.alphabet.add_symbol,
                             sequence[self.split_index:]):

                # Adding to the Prediction Tree
                current = self.tree.addChild(current, index)

                # Adding to the Inverted Index
                if not index < self.inverted_index.size():
                    self.inverted_index.push_back(Bitset(number_train_sequences))

                self.inverted_index[index].add(id_seq)

            # Add the last node in the lookup_table
            self.lookup_table.push_back(current)

    cpdef predict(self, list sequences, float noise_ratio, int MBR):
        cdef vector[int] sequence_indexes, least_frequent_items = vector[int]()
        cdef Py_ssize_t i
        cdef int len_sequences = len(sequences)
        cdef vector[int] int_predictions = vector[int](len_sequences)

        for i in range(self.alphabet.length):
            if self.inverted_index[i].compute_frequency() <= noise_ratio:
                least_frequent_items.push_back(i)
        # TODO warn if no noisy items are found

        for i in range(len_sequences):
            sequence = sequences[i]
            sequence_indexes = <vector[int]>[self.alphabet.get_index(symbol) for symbol in sequence]
        for i in range(len_sequences):
            int_predictions[i] = self.predict_seq(sequence_indexes, least_frequent_items, MBR)

        return [self.alphabet.get_symbol(x) for x in int_predictions]

    cdef int predict_seq(self, vector[int] target_sequence, vector[int] least_frequent_items, int MBR) nogil:
        cdef:
            Scorer score = Scorer(self.alphabet.length)
            queue[vector[int]] queueVector = queue[vector[int]]()
            vector[int] suffix_without_noise, suffix
            cdef Py_ssize_t i
            cdef int noise

        target_sequence.erase(remove(target_sequence.begin(), target_sequence.end(), NOT_AN_INDEX), target_sequence.end())

        queueVector.push(target_sequence)
        score = self.update_score(target_sequence, score)

        while score.m_update_count < MBR and not queueVector.empty():
            suffix = queueVector.front()
            queueVector.pop()
            for i in range(least_frequent_items.size()):
                noise = least_frequent_items[i]
                if find(suffix.begin(), suffix.end(), noise) != suffix.end():
                    suffix_without_noise = vector[int]()
                    remove_copy(suffix.begin(), suffix.end(), back_inserter(suffix_without_noise), noise)
                    if not suffix_without_noise.empty():
                        queueVector.push(suffix_without_noise)
                    score = self.update_score(suffix_without_noise, score)

        return score.get_best_prediction()

    cdef Bitset _find_similar_sequences(self, vector[int] sequence) nogil:
        if sequence.empty():
            return Bitset(self.alphabet.length)

        cdef Bitset bitset_temp
        cdef size_t i

        bitset_temp = Bitset(self.inverted_index[sequence[0]])
        for i in range(1, sequence.size()):
            bitset_temp.inter(self.inverted_index[sequence[i]])

        return bitset_temp

    cdef Scorer update_score(self, vector[int] target_sequence, Scorer score) nogil:
        cdef:
            Bitset similar_sequences, bitseq = Bitset(self.alphabet.length)
            size_t i, similar_sequence_id
            bint updated
            Node end_node
            int next_transition

        for i in range(target_sequence.size()):
            bitseq.add(target_sequence[i])
        similar_sequences = self._find_similar_sequences(target_sequence)

        for similar_sequence_id in range(similar_sequences.size()):
            if similar_sequences[similar_sequence_id]:
                updated = False
                end_node = self.lookup_table[similar_sequence_id]
                next_transition = self.tree.getTransition(end_node)

                while not bitseq[next_transition]:
                    score.update(next_transition)
                    updated = True
                    end_node = self.tree.getParent(end_node)
                    next_transition = self.tree.getTransition(end_node)

                if updated:
                    score.m_update_count += 1

        return score
