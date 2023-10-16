//
//  MNResult3.swift
//  
//
//  Created by Ido on 19/03/2023.
//

import Foundation


/// A value that represents the result of a transformation on some value - either the value hadn't changed, changed or the transformation failed. including an
/// associated value in each succes case. And an associated Failure value. to access the successValue disregaring the type of success, use .successValue
@frozen public enum MNResult3<Success, Failure> {

    enum Simplified : String, Equatable, Hashable {
        case successChanged
        case successNoChange
        case failure
    }
    
    /// A success, storing a `Success` value.
    case successChanged(Success)
    
    /// A success, storing a `Success` value.
    case successNoChange(Success)

    /// A failure, storing a `Failure` value.
    case failure(Failure)

    /// Returns the value associated with any case of success (successChanged or successNoChange). Will return nil if the result is failure.
    /// This helps extract the success result value regardless of the success type (changed or unchanged compared to the "original" or "initlal" value prior to the transformation)
    var successValue : Success? {
        switch self {
        case .successChanged(let success):
            return success
        case .successNoChange(let success):
            return success
        case .failure:
            return nil
        }
    }

    
    /// Returns the assocuiated success value only when the result is .successChanged, otherwise returns nil. Will return nil if the result is failure.
    /// This helps extract the success result value only in the case where the result is successChanged and contrinue with optionals one-liners only for this case..
    var changedOnlyValue : Success? {
        switch self {
        case .successChanged(let success):
            return success
        case .successNoChange:
            return nil
        case .failure:
            return nil
        }
    }
    
    /// Returns the assocuiated success value only when the result is .successNoChange, otherwise returns nil. Will return nil if the result is failure.
    /// This helps extract the success result value only in the case where the result is successNoChange and contrinue with optionals one-liners only for this case..
    var noChangeOnlyValue : Success? {
        switch self {
        case .successChanged:
            return nil
        case .successNoChange(let success):
            return success
        case .failure:
            return nil
        }
    }
    
    var isFailed : Bool {
        switch self {
        case .failure:
            return true
        default:
            return false
        }
    }
    
    var isSucessChanged : Bool {
        switch self {
        case .successChanged:
            return true
        default:
            return false
        }
    }
    
    var isSucessNoChange : Bool {
        switch self {
        case .successNoChange:
            return true
        default:
            return false
        }
    }
    
    var isSucess : Bool {
        return !self.isFailed
    }
    
    var failure : Failure? {
        switch self {
        case .successChanged: return nil
        case .successNoChange: return nil
        case .failure(let failure): return failure
        }
    }
    
    var simplified : Simplified {
        switch self {
        case .successChanged:   return .successChanged
        case .successNoChange:  return .successNoChange
        case .failure:          return .failure
        }
    }
    
    @inlinable public func when(changed:(_ succ:Success)->Void, noChange:(_ succ:Success)->Void, failed:((_ failed:Failure)->Void)? = nil) {
        switch self {
        case .successChanged(let success):
            changed(success)
        case .successNoChange(let success):
            noChange(success)
        case .failure(let failure):
            failed?(failure)
        }
    }
    
    /// Returns a new result, mapping any success value using the given
    /// transformation.
    ///
    /// Use this method when you need to transform the value of a `Result`
    /// instance when it represents a success. The following example transforms
    /// the integer success value of a result into a string:
    ///
    ///     func getNextInteger() -> Result<Int, Error> { /* ... */ }
    ///
    ///     let integerResult = getNextInteger()
    ///     // integerResult == .success(5)
    ///     let stringResult = integerResult.map { String($0) }
    ///     // stringResult == .success("5")
    ///
    /// - Parameter transform: A closure that takes the success value of this
    ///   instance.
    /// - Returns: A `Result` instance with the result of evaluating `transform`
    ///   as the new success value if this instance represents a success.
    @inlinable public func map<NewSuccess>(_ transform: (Success) -> NewSuccess) -> MNResult3<NewSuccess, Failure> {
        switch self {
        case .successChanged(let success):
            return .successChanged(transform(success))
            
        case .successNoChange(let success):
            return .successNoChange(transform(success))
            
        case .failure(let failure):
            return  .failure(failure)
        }
    }

    /// Returns a new result, mapping any failure value using the given
    /// transformation.
    ///
    /// Use this method when you need to transform the value of a `Result`
    /// instance when it represents a failure. The following example transforms
    /// the error value of a result by wrapping it in a custom `Error` type:
    ///
    ///     struct DatedError: Error {
    ///         var error: Error
    ///         var date: Date
    ///
    ///         init(_ error: Error) {
    ///             self.error = error
    ///             self.date = Date()
    ///         }
    ///     }
    ///
    ///     let result: Result<Int, Error> = // ...
    ///     // result == .failure(<error value>)
    ///     let resultWithDatedError = result.mapError { DatedError($0) }
    ///     // result == .failure(DatedError(error: <error value>, date: <date>))
    ///
    /// - Parameter transform: A closure that takes the failure value of the
    ///   instance.
    /// - Returns: A `Result` instance with the result of evaluating `transform`
    ///   as the new failure value if this instance represents a failure.
    @inlinable public func mapError<NewFailure>(_ transform: (Failure) -> NewFailure) -> MNResult3<Success, NewFailure> where NewFailure : Error {
        switch self {
        case .successChanged(let success):
            return .successChanged(success)
            
        case .successNoChange(let success):
            return .successNoChange(success)
            
        case .failure(let failure):
            return  .failure(transform(failure))
        }
    }

    /// Returns a new result, mapping any success value using the given
    /// transformation and unwrapping the produced result.
    ///
    /// Use this method to avoid a nested result when your transformation
    /// produces another `Result` type.
    ///
    /// In this example, note the difference in the result of using `map` and
    /// `flatMap` with a transformation that returns an result type.
    ///
    ///     func getNextInteger() -> Result<Int, Error> {
    ///         .success(4)
    ///     }
    ///     func getNextAfterInteger(_ n: Int) -> Result<Int, Error> {
    ///         .success(n + 1)
    ///     }
    ///
    ///     let result = getNextInteger().map { getNextAfterInteger($0) }
    ///     // result == .success(.success(5))
    ///
    ///     let result = getNextInteger().flatMap { getNextAfterInteger($0) }
    ///     // result == .success(5)
    ///
    /// - Parameter transform: A closure that takes the success value of the
    ///   instance.
    /// - Returns: A `Result` instance, either from the closure or the previous
    ///   `.failure`.
    @inlinable public func flatMap<NewSuccess>(_ transform: (Success) -> MNResult3<NewSuccess, Failure>) -> MNResult3<NewSuccess, Failure> {
        switch self {
            case let .successChanged(success):
              return transform(success)
            case let .successNoChange(success):
              return transform(success)
            case let .failure(failure):
              return .failure(failure)
            }
    }

    /// Returns a new result, mapping any failure value using the given
    /// transformation and unwrapping the produced result.
    ///
    /// - Parameter transform: A closure that takes the failure value of the
    ///   instance.
    /// - Returns: A `Result` instance, either from the closure or the previous
    ///   `.success`.
    @inlinable public func flatMapError<NewFailure>(_ transform: (Failure) -> MNResult3<Success, NewFailure>) -> MNResult3<Success, NewFailure> where NewFailure : Error {
        switch self {
        case let .successChanged(success):
            return .successChanged(success)
        case let .successNoChange(success):
            return .successNoChange(success)
        case let .failure(failure):
            return transform(failure)
        }
    }
}

extension MNResult3 where Failure : Error {
    
    var error : Error? {
        switch self {
        case .successChanged:
            return nil
        case .successNoChange:
            return nil
        case .failure(let error):
            return error
        }
    }
    
    var asResult : Result<Success, Failure> {
        switch self {
        case .successChanged(let success):  return Result.success(success)
        case .successNoChange(let success): return Result.success(success)
        case .failure(let failure):         return Result.failure(failure)
        }
    }
    
    var asAppResult : MNResult<Success> {
        switch self {
        case .successChanged(let success):  return MNResult.success(success)
        case .successNoChange(let success): return MNResult.success(success)
        case .failure(let failure):         return MNResult<Success>.failure(fromError: failure)
        }
    }
    
    /// Returns the success value as a throwing expression.
    ///
    /// Use this method to retrieve the value of this result if it represents a
    /// success, or to catch the value if it represents a failure.
    ///
    ///     let integerResult: Result<Int, Error> = .success(5)
    ///     do {
    ///         let value = try integerResult.get()
    ///         print("The value is \(value).")
    ///     } catch {
    ///         print("Error retrieving the value: \(error)")
    ///     }
    ///     // Prints "The value is 5."
    ///
    /// - Returns: The success value, if the instance represents a success.
    /// - Throws: The failure value, if the instance represents a failure.
    @inlinable public func get() throws -> Success {
        switch self {
        case let .successChanged(success): return success
        case let .successNoChange(success): return success
        case let .failure(failure):
            throw failure
        }
    }
    
    /// Creates a new result by evaluating a throwing closure, capturing the
    /// returned value as a success, or any thrown error as a failure.
    ///
    /// - Parameter body: A throwing closure to evaluate.
    @_transparent
    public init(prevValue:Success? = nil, catching body: () throws -> Success) {
        do {
            let newValue = try body()
            if prevValue == nil /* newValue is not nil! */ {
                self = MNResult3.successChanged(newValue)
                
            } else {
                print("[Result3] \(Self.self).init(prevValue:catching:) ❌ unable to determine if non-equatable vals have changed. prev: \(prevValue!) == new \(newValue) ?  It is highly reccommended to make \(Success.self) conform to Equatable.")
                self = MNResult3.successNoChange(newValue)
            }
        } catch let error {
            if let error = error as? Failure {
                self = MNResult3.failure(error)
            } else {
                preconditionFailure("[Result3] \(Self.self).init(prevValue:catching:) ❌ was unable to return a failure error of type \(Failure.self) where caught error type was \(type(of: error))")
            }
        }
    }
    
    public init(prevValue:Success? = nil, catching body: () throws -> Success)  where Success : AnyObject {
        do {
            let newValue = try body()
            print("[Result3] \(Self.self).init(prevValue:catching:) ⚠️️ determining if non-equatable any object vals have changed. prev: \(prevValue!) == new \(newValue) ?  It is highly reccommended to make \(Success.self) conform to Equatable.")
            if prevValue == nil || MemoryAddress(of: prevValue!) == MemoryAddress(of: newValue) {
                self = MNResult3.successChanged(newValue)
            } else {
                self = MNResult3.successNoChange(newValue)
            }
        } catch let error {
            if let error = error as? Failure {
                self = MNResult3.failure(error)
            } else {
                preconditionFailure("[Result3] \(Self.self).init(prevValue:catching:) where Success : AnyObject ❌ was unable to return a failure error of type \(Failure.self) where caught error type was \(type(of: error))")
            }
        }
    }
    
    @_transparent
    public init(prevValue:Success? = nil, catching body: () throws -> Success)  where Success : LosslessStringConvertible {
        do {
            let newValue = try body()
            print("[Result3] \(Self.self).init(prevValue:catching:) ⚠️️ determining if non-equatable LosslessStringConvertible vals have changed. prev: \(prevValue!) == new \(newValue) ? It is highly reccommended to make \(Success.self) conform to Equatable.")
            if prevValue?.description == newValue.description {
                self = MNResult3.successChanged(newValue)
            } else {
                self = MNResult3.successNoChange(newValue)
            }
        } catch let error {
            if let error = error as? Failure {
                self = MNResult3.failure(error)
            } else {
                preconditionFailure("[Result3] \(Self.self).init(prevValue:catching:) where Success : LosslessStringConvertible ❌ was unable to return a failure error of type \(Failure.self) where caught error type was \(type(of: error))")
            }
        }
    }
    
    @_transparent
    public init(prevValue:Success? = nil, catching body: () throws -> Success)  where Success : Equatable {
        do {
            let newValue = try body()
            if prevValue == newValue {
                self = MNResult3.successChanged(newValue)
            } else {
                self = MNResult3.successNoChange(newValue)
            }
        } catch let error {
            if let error = error as? Failure {
                self = MNResult3.failure(error)
            } else {
                preconditionFailure("[Result3] \(Self.self).init(prevValue:catching:) where Success : Equatable ❌ was unable to return a failure error of type \(Failure.self) where caught error type was \(type(of: error))")
            }
        }
    }
    
    @_transparent
    public init(prevValue:Success?, newValue: Success, orFailure failure:Failure?) where Success : Equatable {
        if let failure = failure {
            self = .failure(failure)
        } else if prevValue != nil && prevValue == newValue {
            self = .successNoChange(newValue)
        } else {
            self = .successChanged(newValue)
        }
    }
    
    
    /// Returns one of the two success values by comparing between an old value and a new value (using equatable). If both values are equal, will return a .successNoChange(newValue) the result means the transformation was successful but the result item equals the input / previous state of the item, otherwise, will return .successChanged(newValue) - meanin that the treansformation succeeded andresulted in avaslue different than the inital value. (before the transormation)
    /// - Parameters:
    ///   - prevValue: the value before its transitin (in its "original" state)
    ///   - newValue: the value after the transformation
    /// - Returns: .successNoChange(newValue) if prevValue == newValue, and in any other case will return a .successChanged(newValue)
    static func sucessBy(equatingPrevValue prevValue : Success?, with newValue:Success)->MNResult3<Success, Failure>  where Success : Equatable {
        if prevValue != nil && prevValue == newValue {
            return .successNoChange(newValue)
        } else {
            return.successChanged(newValue)
        }
    }
}

extension MNResult3 where Success : Equatable, Failure : Equatable {

    public static func != (lhs: MNResult3<Success, Failure>, rhs: MNResult3<Success, Failure>) -> Bool {
        // Check if not equal by enum case or wrapped value:
        
        guard lhs.simplified == rhs.simplified else {
            return true // no, they are not equal
        }
        
        if lhs.isSucess && lhs.successValue != rhs.successValue {
            return true // yes, they are not equal
        }
        
        if lhs.isFailed && lhs.failure != rhs.failure {
            return true // yes, they are not equal
        }
        
        // They are exactly equal
        return false // no, they are equal
    }
}

extension MNResult3 : Equatable where Success : Equatable, Failure : Equatable {

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: MNResult3<Success, Failure>, rhs: MNResult3<Success, Failure>) -> Bool {
        return (lhs != rhs) == false
    }
}

// MARK: HasHable
extension MNResult3 : Hashable where Success : Hashable, Failure : Hashable {

    /// Hashes the essential components of this value by feeding them into the
    /// given hasher.
    ///
    /// Implement this method to conform to the `Hashable` protocol. The
    /// components used for hashing must be the same as the components compared
    /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
    /// with each of these components.
    ///
    /// - Important: Never call `finalize()` on `hasher`. Doing so may become a
    ///   compile-time error in the future.
    ///
    /// - Parameter hasher: The hasher to use when combining the components
    ///   of this instance.
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .successChanged(let success):
            hasher.combine(100000)
            hasher.combine(success)
        case .successNoChange(let success):
            hasher.combine(200000)
            hasher.combine(success)
        case .failure(let failure):
            hasher.combine(failure)
            hasher.combine(300000)
        }
    }
}

extension MNResult3: Sendable where Success: Sendable, Failure : Sendable {
    
}
