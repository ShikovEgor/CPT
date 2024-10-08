from cpt.prediction_tree cimport PredictionTree
from cpt.alphabet cimport Alphabet
from cpt.bitset cimport Bitset
from cpt.scorer cimport Scorer
from libcpp.vector cimport vector


cdef class Cpt:
    cdef:
        PredictionTree tree
        vector[Bitset] inverted_index
        vector[size_t] lookup_table
        int predict_seq(self, vector[int] target_sequence, vector[int] least_frequent_items) nogil
        vector[int] predict_seq_k(self, vector[int] target_sequence, vector[int] least_frequent_items,  vector[int]& scores, int k=*) nogil
        Scorer make_scorer(self, vector[int], vector[int]) nogil
        vector[int] c_retrieve_reversed_sequence(self, int index) nogil
        vector[int] c_compute_noisy_items(self, float noise_ratio) nogil
        Bitset c_find_similar_sequences(self, vector[int] sequence) nogil
        int update_score(self, vector[int] suffix, Scorer& score) nogil
        list retrieve_similar_sequences(self, vector[int] sequence_index)

    cpdef predict(self, list sequences, bint multithreading=*)
    cpdef predict_k(self, list sequences, int k, bint multithreading=*)
    cpdef vector[vector[int]] _prepare_data(self, list sequences)

    cdef public:
        int split_length
        float noise_ratio
        int MBR

    cdef readonly:
        Alphabet alphabet
        size_t _number_trained_sequences
