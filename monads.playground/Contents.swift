//: Playground - noun: a place where people can play

import Cocoa

enum Result<Wrapped> {
    case success(Wrapped)
    case failure(Error)
}

struct ExampleError: Error {
    
}

func curry<A, B, C>(_ function: @escaping (A, B) -> C) -> (A) -> (B) -> C {
    return { first in
        return { second in
            return function(first, second)
        }
    }
}

// https://fsharpforfunandprofit.com/posts/elevated-world/#return
func pure<T>(_ value: T) -> Result<T> {
    return .success(value)
}

// https://fsharpforfunandprofit.com/posts/elevated-world/#apply
func apply<T, U>(transform: Result<(T) -> U>, with result: Result<T>) -> Result<U> {
    switch transform {
    case .success(let function):
        switch result {
        case .success(let value):
            return .success(function(value))
            
        case .failure(let error):
            return .failure(error)
        }
        
    case .failure(let error):
        return .failure(error)
    }
}

// curried
func apply<T, U>(_ transform: Result<(T) -> U>) -> (Result<T>) -> Result<U> {
    return { input in
        switch transform {
        case .success(let function):
            switch input {
            case .success(let value):
                return .success(function(value))
                
            case .failure(let error):
                return .failure(error)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }
}

func concat<T>(_ result: Result<Result<T>>) -> Result<T> {
    switch result {
    case .success(let value):
        return value
        
    case .failure(let error):
        return .failure(error)
    }
}

// https://fsharpforfunandprofit.com/posts/elevated-world/#map
func map<T, U>(transform: @escaping (T) -> U, with result: Result<T>) -> Result<U> {
    return apply(transform: pure(transform), with: result)
}

// curried
func map<T, U>(_ transform: @escaping (T) -> U) -> (Result<T>) -> Result<U> {
    return { input in
        return apply(pure(transform))(input)
    }
}

// https://fsharpforfunandprofit.com/posts/elevated-world-2/#bind
func flatMap<T, U>(transform: @escaping (T) -> Result<U>, with result: Result<T>) -> Result<U> {
    return concat(map(transform: transform, with: result))
}

// curried
func flatMap<T, U>(_ transform: @escaping (T) -> Result<U>) -> (Result<T>) -> Result<U> {
    return { input in
        return concat(map(transform)(input))
    }
}

// Pretend this was from a remote resource / database / etc, it could "fail"
func getNumber(_ number: Int, fail: Bool) -> Result<Int> {
    return fail ? .failure(ExampleError()) : .success(number)
}

let numberOne = getNumber(1, fail: false)
let numberTwo = getNumber(2, fail: false)

func add(lhs: Int, rhs: Int) -> Int {
    return lhs + rhs
}

// We want to add our two number together but we can't because they're not an Int they're a Result<Int>
// add(lhs: getNumber(1, fail: false), rhs: getNumber(2, fail: false))

// So instead of writing a new add function we can bring it into the Result context with Apply
// We can only do this with functions that take one parameter and return one parameter, so we'll curry the
// add function
let addResult = apply(transform: apply(transform: pure(curry(add)), with: numberOne), with: numberTwo)

switch addResult {
case .success(let value):
    print("The result is \(value)")
    
case .failure:
    print("Failed to add \(numberOne) and \(numberTwo)")
}

// This can look prettier with a custom opperator and making the add function curried by default
precedencegroup Apply {
    associativity: left
}

infix operator <*>: Apply
func <*><A, B>(lhs: Result<(A) -> B>, rhs: Result<A>) -> Result<B> {
    return apply(transform: lhs, with: rhs)
}

func add(_ lhs: Int) -> (Int) -> Int {
    return { input in
        return lhs + input
    }
}

let addResult2 = pure(add) <*> numberOne <*> numberTwo

switch addResult2 {
case .success(let value):
    print("The result is \(value)")
    
case .failure:
    print("Failed to add \(numberOne) and \(numberTwo)")
}

// Another option is to make multiple versions of apply, which looks gross but usage is nice
func apply<A, B, C>(transform: Result<(A, B) -> C>, _ lhs: Result<A>, _ rhs: Result<B>) -> Result<C> {
    switch transform {
    case .success(let function):
        switch lhs {
        case .success(let lhsValue):
            switch rhs {
            case .success(let rhsValue):
                return .success(function(lhsValue, rhsValue))
                
            case .failure(let error):
                return .failure(error)
            }
            
        case .failure(let error):
            return .failure(error)
        }
        
    case .failure(let error):
        return .failure(error)
    }
}

let addResult3 = apply(transform: pure(add), numberOne, numberTwo)

switch addResult3 {
case .success(let value):
    print("The result is \(value)")
    
case .failure:
    print("Failed to add \(numberOne) and \(numberTwo)")
}

