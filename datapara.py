###########################################################################################################
# (c) 2011, José Martinez, Polytech'Nantes
# July 11:  - Definition of a set of (pseudo) parallel operators with actual complexities reckoning along a
#             "parallel" computation.
#           - This is just provided as a pedagogical help to learning data parallelisation.
# July 13:  - Mixing efficient and optimal parallel complexities rather than choosing between them.
#             These are based on a EREW PRAM model, i.e., the less efficient.
#           - Adding helper functions, namely:
#                - 'single_sequential_complexity';
#                - 'make_complexities';
#                - 'add_complexities';
#             to develop function definitions that do not rely entirely on data parallel operators
#             (See 'vectorpara' as an example).
#
# The use of this library is not authorised outside the Polytechnic School of the University of Nantes.
###########################################################################################################
            
#
# intermediate results with (or without) parallel complexities
#

def single_sequential_complexity ():
    """
    This helper function is to be used in functions that combine sequential steps with data parallel operators
    in the return statement when complexities are added together.
    """
    return (1, (1, 1), (1, 1))

def make_complexities (time_sequential, time_efficient, surface_efficient, time_optimal, surface_optimal):
    """
    This helper function allows to create the complexities that are provided along a result.

    In the optimum case, the surface is minimised as long as the time complexity remains logarithmic.
    Usually, this should lead to less rapid algorithms but ones that use efficiently the processing power.
    
    Conversely, there occurs a waste of processing power but the speed-up is maximal for efficient algorithms.

    All of them should be compared to their sequential counterparts.
    """
    assert type(time_sequential)   == int
    assert type(time_efficient)    == int
    assert type(surface_efficient) == int
    assert type(time_optimal)      == int
    assert type(surface_optimal)   == int
    assert time_sequential   >= 1
    assert time_efficient    >= 1
    assert surface_efficient >= 1
    assert time_optimal      >= 1
    assert surface_optimal   >= 1
    return (time_sequential, (time_efficient, surface_efficient), (time_optimal, surface_optimal))

def add_complexities (*complexities):
    assert all([__are_complexities__(c) \
                for c in complexities])
    if len(complexities) == 0:
        return single_sequential_complexity()
    else:
        time_sequential   = 0
        time_efficient    = 0
        surface_efficient = 0
        time_optimal      = 0
        surface_optimal   = 0
        for (ts, (te, se), (to, so)) in complexities:
            time_sequential   = time_sequential + ts
            time_efficient    = time_efficient + te
            surface_efficient = max(surface_efficient, se)
            time_optimal      = time_optimal + to
            surface_optimal   = max(surface_optimal, so)
        return make_complexities(time_sequential, time_efficient, surface_efficient, time_optimal, surface_optimal)

def __are_complexities__ (complexities):
    if type(complexities)    == tuple and \
       len(complexities)     == 3     and \
       type(complexities[1]) == tuple and \
       len(complexities[1])  == 2     and \
       type(complexities[2]) == tuple and \
       len(complexities[2])  == 2:
        (time_sequential, (time_efficient, surface_efficient), (time_optimal, surface_optimal)) = complexities
        return type(time_sequential)   == int and \
               type(time_efficient)    == int and \
               type(surface_efficient) == int and \
               type(time_optimal)      == int and \
               type(surface_optimal)   == int and \
               time_sequential   >= 0         and \
               time_efficient    >= 0         and \
               surface_efficient >= 0         and \
               time_optimal      >= 0         and \
               surface_optimal   >= 0
    else:
        return False
        
def __data_with_complexities__ (data_complexities):
    """
    The role of this (internal) function is to verify the type of the data, especially in preconditions.
    """
    if type(data_complexities) == tuple and \
       len(data_complexities) == 2:
        (data, complexities) = data_complexities
        return __are_complexities__(complexities)
    else:
        return False

def __normalise_data__ (data):
    if __data_with_complexities__(data):
        return data
    else:
        return (data, (0, (0, 0), (0, 0)))
        
def analyse_parallel_result (data_complexities):
    """
    This function is to be called on top of a "parallel" computation
    in order to display the main properties of the algorithm, i.e.,
    its parallel complexities, and its speed-up and efficiency with
    respect to the equivalent sequential version.
    """
    if __data_with_complexities__(data_complexities):
        (data, (time_sequential, (time_efficient, surface_efficient), (time_optimal, surface_optimal))) = data_complexities
        print('Sequential time complexity:', time_sequential)
        print('Efficient complexities:')
        print('   Parallel time complexity:', time_efficient)
        print('   Surface:', surface_efficient)
        print('   Work:', time_efficient * surface_efficient)
        if time_efficient > 0:
            print('   Speed-up:', time_sequential / time_efficient, 'times faster')
        else:
            print('   Speed-up:', None)
        if time_efficient > 0 and \
           surface_efficient > 0:
            print('   Efficiency:', (time_sequential / surface_efficient) / time_efficient * 100, '%')
            assert (time_sequential / surface_efficient) / time_efficient <= 1
        else:
            print('   Efficiency:', None)
        print('Optimal complexities:')
        print('   Parallel time complexity:', time_optimal)
        print('   Surface:', surface_optimal)
        print('   Work:', time_optimal * surface_optimal)
        if time_optimal > 0:
            print('   Speed-up:', time_sequential / time_optimal, 'times faster')
        else:
            print('   Speed-up:', None)
        if time_optimal > 0 and \
           surface_optimal > 0:
            print('   Efficiency:', (time_sequential / surface_optimal) / time_optimal * 100, '%')
            assert (time_sequential / surface_optimal) / time_optimal <= 1
        else:
            print('   Efficiency:', None)
        return data
    else:
        print('No complexity information available')
        return data_complexities

#
# length
#

def length (data):
    if __data_with_complexities__(data):
        (data, _) = data
    assert type(data) == list
    return len(data)

#
# mappings
#

from math import ceil, log 

def clog2 (x):
    return ceil(log(x, 2))

def map1 (function, data, function_complexity = 1):
    """
    This operator applies the same function to each item of an "array" of data.
    
    The complexity of the operation is supposed to be in O(1), though this can be changed through the third, optional,
    parameter.
    
    In most cases, the function will be a lambda function.

    Therefore, in the efficient case:
       - the parallel time complexity is the function complexity;
       - the surface is equal to the size of the "array";

    In the optimal case:
       - the parallel time complexity is only the logarithm of
         the size of the array.
       - the surface is only the size of the "array" divided by
         its logarithm.

    The sequential complexity is the size of the "array".

    All the complexities ara bounded by O(1).  This control is necessary in order to deal with the case of empty data.
    """
    data = __normalise_data__(data)
    assert __data_with_complexities__(data)
    assert function_complexity >= 1
    (data, complexities) = data
    result = [function(e) \
              for e in data]
    assert len(result) == len(data)
    return (result, \
            add_complexities(complexities, \
                             make_complexities(function_complexity * len(data), \
                                               function_complexity, \
                                               len(data), \
                                               function_complexity * clog2(len(data)), \
                                               ceil(len(data) / clog2(len(data))))))

def map2 (function, data1, data2, function_complexity = 2):
    """
    This version of the mapping function allows to apply a binary function, hence taking its parameters from two "arrays",
    having the same size.
    
    Everything else is mostly unchanged.  Let us note that the default function complexity is set to 2 rather than 1
    in order to emphasize the fact that it uses two parameters.
    """
    data1 = __normalise_data__(data1)
    data2 = __normalise_data__(data2)
    assert __data_with_complexities__(data1)
    assert __data_with_complexities__(data2)
    (data1, complexities1) = data1
    (data2, complexities2) = data2
    assert len(data1) == len(data2)
    assert function_complexity >= 1
    result = [function(e1, e2) \
              for (e1, e2) in zip(data1, \
                                  data2)]
    assert len(result) == len(data1)
    return (result, \
            add_complexities(complexities1, \
                             complexities2, \
                             make_complexities(function_complexity * len(data1), \
                                               function_complexity, \
                                               len(data1), \
                                               function_complexity * clog2(len(data1)), \
                                               ceil(len(data1) / clog2(len(data1))))))

def map3 (function, data1, data2, data3, function_complexity = 3):
    """
    This is the ternary version of the mapping operator.
    """
    data1 = __normalise_data__(data1)
    data2 = __normalise_data__(data2)
    data3 = __normalise_data__(data3)
    assert __data_with_complexities__(data1)
    assert __data_with_complexities__(data2)
    assert __data_with_complexities__(data3)
    (data1, complexities1) = data1
    (data2, complexities2) = data2
    (data3, complexities3) = data3
    assert len(data1) == len(data2)
    assert len(data2) == len(data3)
    assert function_complexity >= 1
    result = [function(e1, e2, e3) \
              for (e1, e2, e3) in zip(data1, \
                                      data2, \
                                      data3)]
    assert len(result) == len(data1)
    return (result, \
            add_complexities(complexities1, \
                             complexities2, \
                             complexities3, \
                             make_complexities(function_complexity * len(data1), \
                                               function_complexity, \
                                               len(data1), \
                                               function_complexity * clog2(len(data1)), \
                                               ceil(len(data1) / clog2(len(data1))))))

#
# diffusions
#

def diffuse (e, n, copy_complexity = 1):
    """
    The diffuse operator duplicates an element a given number of times.
    
    It is mostly useful in order to build a new array.
    
    In case the element is not a basic type, such as an integer or a boolean, the optional copy_complexity parameter
    allows to provide the complexity of copying a single element.
    """
    assert type(n) == int
    assert n >= 0
    assert copy_complexity >= 1
    result = [e] * n
    assert len(result) == n
    assert all([e_i == e \
                for e_i in result])
    return (result, \
            make_complexities(copy_complexity * n, \
                              copy_complexity * clog2(n), \
                              ceil(n / 2), \
                              copy_complexity * clog2(n / clog2(n)) + copy_complexity * clog2(n), \
                              ceil(n / clog2(n) / 2)))

def arithmetic (u_0, r, n):
    """
    A common use of the diffuse operator is to create an array of "consecutive" integers.
    
    This is a derived function that computes a prefix of an arithmetic series.
    
    Note that with a CREW PRAM, we could have devised a much more efficient implementation:
        result = [u_0 + r * i \
                  for i in range(n)]
    with complexities:
        make_complexities(n, \
                          1, \
                          n, \
                          clog2(n), \
                          ceil(n / clog2(n))))
    """
    assert type(u_0) in [int, float]
    assert type(r)   in [int, float]
    assert type(n)   ==  int
    assert n >= 0
    result = map3(lambda u_0, i_plus_1, r: u_0 + (i_plus_1 - 1) * r, \
                  diffuse(u_0, n), \
                  prefix_sum(diffuse(1, n)), \
                  diffuse(r, n))
    assert len(result[0]) == n
    return result

#
# reductions
#

import functools

def reduce (binary_associative_function, data, neutral_element, function_complexity = 2):
    """
    Computing repetitively the same binary and associative operator on a series of values can be conducted in any order.
    
    Therefore, parallelisation can be very efficient by choosing a balanced tree computation.
    
    This is the general version.  For common operators, which are listed below, we provide specific versions.
    """
    data = __normalise_data__(data)
    assert __data_with_complexities__(data)
    (data, complexities) = data
    assert True                                   if len(data) == 0                else \
           type(neutral_element) in [int, float]  if type(data[0]) in [int, float] else \
           type(neutral_element) == type(data[0])
    assert function_complexity >= 1
    result = functools.reduce(binary_associative_function, data, neutral_element)
    return (result, \
            add_complexities(complexities, \
                             make_complexities(function_complexity * len(data), \
                                               function_complexity * clog2(len(data)), \
                                               ceil(len(data) / 2), \
                                               function_complexity * clog2(len(data) / clog2(len(data))) + function_complexity * clog2(len(data)), \
                                               ceil(len(data) / clog2(len(data)) / 2))))

def summation (data, function_complexity = 2):
    """
    The common '+' operator gives rise to a common generalised operator, namely the sum of a series.
    
    This, and the following, derived operators also take care of the neutral elements associated to the binary function.
    """
    return reduce(lambda x, y: x + y, data, 0, function_complexity)

def product (data, function_complexity = 2):
    """
    More generally, the most common associative binary operators generate specific n-ary generalisations.
    
    This is the short-hand for a reduction though the '*' operator.
    """
    return reduce(lambda x, y: x * y, data, 1, function_complexity)

def minimum (data, function_complexity = 2):
    """
    Short-hand for a reduction though the 'min' operator.
    """
    return reduce(lambda x, y: min(x, y), data, +'Infinity', function_complexity)

def maximum (data, function_complexity = 2):
    """
    Short-hand for a reduction though the 'max' operator.
    """
    return reduce(lambda x, y: max(x, y), data, -'Infinity', function_complexity)

def forall (data, function_complexity = 2):
    """
    Short-hand for a reduction though the 'and' operator.
    """
    return reduce(lambda x, y: x and y, data, True, function_complexity)

def exists (data, function_complexity = 2):
    """
    Short-hand for a reduction though the 'or' operator.
    """
    return reduce(lambda x, y: x or y, data, False, function_complexity)

#
# prefixes
#

def prefix (binary_associative_function, data, neutral_element = 0, function_complexity = 2):
    data = __normalise_data__(data)
    assert __data_with_complexities__(data)
    (data, complexities) = data
    assert type(neutral_element) == type(data[0]) if len(data) > 0 else \
           True
    assert function_complexity >= 1
    result = []
    next_value = neutral_element
    for e in data:
        next_value = binary_associative_function(next_value, e)
        result = result + [next_value]
    assert len(result) == len(data)
    return (result, \
            add_complexities(complexities, \
                             make_complexities(len(data), \
                                               function_complexity * 2 * clog2(len(data)), \
                                               ceil(len(data) / 2), \
                                               function_complexity * 2 * clog2(len(data)), \
                                               ceil(len(data) / clog2(len(data)) / 2))))

def prefix_sum (data, neutral_element = 0, function_complexity = 2):
    """
    As for reductions, we provide the derived prefix functions for the most common associative binary operators.
    """
    return prefix(lambda x, y: x + y, data, 0, function_complexity)

def prefix_prod (data, neutral_element = 0, function_complexity = 2):
    return prefix(lambda x, y: x * y, data, 1, function_complexity)

def prefix_min (data, neutral_element = 0, function_complexity = 2):
    return prefix(lambda x, y: min(x, y), data, +'Infinity', function_complexity)

def prefix_max (data, neutral_element = 0, function_complexity = 2):
    return prefix(lambda x, y: max(x, y), data, -'Infinity', function_complexity)

def prefix_forall (data, neutral_element = 0, function_complexity = 2):
    return prefix(lambda x, y: x and y, data, True, function_complexity)

def prefix_exists (data, neutral_element = 0, function_complexity = 2):
    return prefix(lambda x, y: x or y, data, False, function_complexity)

#
# selection
#

def select (predicate, data, predicate_complexity = 1, copy_complexity = 1):
    """
    The selection is a derived algorithm that could be implemented, even here, as
    (within taking into account the complexities):
        signature = map1(lambda x: 1 if predicate(x) else 0, data)
        result = diffuse(0, summation(signature))
        for (ok, position, value) in zip(signature, \
                                         prefix_sum(signature), \
                                         data):
            if ok:
                result[position] = value
    where the 'for' loop has to be considered a parallel loop in a parallel environment (it corresponds
    to an indirect assignment).

    Note that in a real environment, the initialisation of the result "array" is not necessary, only its
    allocation is required.
    """
    data = __normalise_data__(data)
    assert __data_with_complexities__(data)
    (data, complexities) = data
    result = [e \
              for e in data \
              if predicate(e)]
    assert len(result) <= len(data)
    assert all([e in data \
                for e in result])
    return (result, \
            add_complexities(complexities, \
                             make_complexities(predicate_complexity * len(data) + copy_complexity * len(result), \
                                               predicate_complexity + 2 * clog2(len(data)) + copy_complexity, \
                                               len(data), \
                                               predicate_complexity * clog2(len(data)) + 2 * clog2(len(data)) + copy_complexity * clog2(len(data)), \
                                               ceil(len(data) / clog2(len(data))))))

#
# decomposition / composition
#

def extract_bottom (data, copy_complexity = 1):
    """
    This function extracts the bottom half of an "array".
    """
    data = __normalise_data__(data)
    assert __data_with_complexities__(data)
    assert copy_complexity >= 1
    (data, complexities) = data
    mid = len(data) // 2
    result = data[:mid]
    return (result, \
            add_complexities(complexities, \
                             make_complexities(len(data) // 2, \
                                               copy_complexity, \
                                               len(data) // 2, \
                                               copy_complexity * clog2(len(data) // 2), \
                                               ceil((len(data) // 2) / clog2(len(data) // 2)))))

def extract_top (data, copy_complexity = 1):
    """
    This function extracts the top half of an "array".
    """
    data = __normalise_data__(data)
    assert __data_with_complexities__(data)
    assert copy_complexity >= 1
    (data, complexities) = data
    mid = len(data) // 2
    result = data[mid:]
    return (result, \
            add_complexities(complexities, \
                             make_complexities(len(data) - len(data) // 2, \
                                               copy_complexity, \
                                               len(data) - len(data) // 2, \
                                               copy_complexity * clog2(len(data) - len(data) // 2), \
                                               ceil((len(data) - len(data) // 2) / clog2(len(data) - len(data) // 2)))))

def concatenate (data1, data2, copy_complexity = 1):
    """
    Concatenation is the reverse function of the couple bottom/top, i.e.:
       data == concatenate(extract_bottom(data), extract_top(data))
    """
    data1 = __normalise_data__(data1)
    data2 = __normalise_data__(data2)
    assert __data_with_complexities__(data1)
    assert __data_with_complexities__(data2)
    assert abs(len(data1) - len(data2)) <= 1
    assert copy_complexity >= 1
    (data1, complexities1) = data1
    (data2, complexities2) = data2
    result = data1 + data2
    assert len(result) == len(data1) + len(data2)
    return (result, \
            add_complexities(complexities1, \
                             complexities2, \
                             make_complexities(len(data1) + len(data2), \
                                               copy_complexity, \
                                               len(data1) + len(data2), \
                                               copy_complexity * ceil(len(data1) / clog2(len(data1))) + copy_complexity * ceil(len(data2) / clog2(len(data2))), \
                                               ceil(len(data1) / clog2(len(data1)) + ceil(len(data2) / clog2(len(data2)))))))

def extract_odd (data, copy_complexity = 1):
    data = __normalise_data__(data)
    assert __data_with_complexities__(data)
    (data, complexities) = data
    result = data[0::2]
    return (result, \
            add_complexities(complexities, \
                             make_complexities(ceil(len(data) // 2), \
                                               copy_complexity, \
                                               ceil(len(data) // 2), \
                                               copy_complexity * clog2(ceil(len(data) // 2)), \
                                               ceil(ceil(len(data) // 2) / clog2(ceil(len(data) // 2))))))

def extract_even (data, copy_complexity = 1):
    data = __normalise_data__(data)
    assert __data_with_complexities__(data)
    (data, complexities) = data
    result = data[1::2]
    return (result, \
            add_complexities(complexities, \
                             make_complexities(ceil(len(data) // 2), \
                                               copy_complexity, \
                                               ceil(len(data) // 2), \
                                               copy_complexity * clog2(ceil(len(data) // 2)), \
                                               ceil(ceil(len(data) // 2) / clog2(ceil(len(data) // 2))))))

def interleave (data1, data2, copy_complexity = 1):
    """
    Interleave is the reverse function of the couple odd/even, i.e.:
       data == interleave(extract_odd(data), extract_even(data))
    """
    data1 = __normalise_data__(data1)
    data2 = __normalise_data__(data2)
    assert __data_with_complexities__(data1)
    assert __data_with_complexities__(data2)
    (data1, complexities1) = data1
    (data2, complexities2) = data2
    assert abs(len(data1) - len(data2)) <= 1
    result = reduce(lambda l1, l2: l1 + l2, \
                    [[e1, e2] \
                     for (e1, e2) in zip(data1, \
                                         data2)],
                    [], \
                    )
    (result, complexities) = result;
    if len(data1) == len(data2):
        pass
    elif len(data1) < len(data2):
        result = result + [data2[-1]]
    else:
        result = result + [data1[-1]]
    assert all([e in result \
                for e in data1])
    assert all([e in result \
                for e in data2])
    return (result, \
            add_complexities(complexities1, \
                             complexities2, \
                             complexities, \
                             single_sequential_complexity()))

##def partition (data, lengths):
##    data = __normalise_data__(data)
##    assert __data_with_complexities__(data)
##    (data, (time_sequential, (time_efficient, surface_efficient), (time_optimal, surface_optimal))) = data
##    assert type(lengths) == list
##    assert all([type(l) == int \
##                for l in lengths])
##    assert sum([l \
##                for l in lengths]) == len(data)
##    working_data = data
##    result = []
##    for l in lengths:
##        result = result + working_data[:l]
##        working_data = working_data[l:]
##    assert len(result) == len(data)
##    assert concatenate_all(result) == data
##    return result
##
##def concatenate_all (data):
##    """
##    This function is the inverse function of partition, as well as a further generalisation à the concatenation, from two
##    sublists to any number.
##    
##    The axiom between bottop and concatenation is easier to state:
##       data == concatenate_all(partition(data, lengths))
##    """
##    data = __normalise_data__(data)
##    assert __data_with_complexities__(data)
##    (data, (time_sequential, (time_efficient, surface_efficient), (time_optimal, surface_optimal))) = data
##    assert all([type(d) == list \
##                for d in data])
##    result = reduce(lambda d1, d2: d1 + d2, \
##                    data, \
##                    [])
##    assert len(result) == sum([len(d) \
##                               for d in data])
##    return result

