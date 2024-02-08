//
//  SkipEncoding.swift
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import AppKit

// This will mark a property as a non-encodable propery -
// under the hood, it will encode nothing and decode nothing
@propertyWrapper
public struct SkipEncode<T> {
    public var wrappedValue: T
    public init(wrappedValue value: T) {
        wrappedValue = value
    }
}

extension SkipEncode: Decodable where T: Decodable {
   public init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      self.wrappedValue = try container.decode(T.self)
   }
}

extension SkipEncode: Encodable {
   public func encode(to encoder: Encoder) throws {
      // nothing to do here
   }
}

@propertyWrapper
public struct SkipEncodeSendable<T:Sendable> : Sendable {
    public var wrappedValue: T
    public init(wrappedValue value: T) {
        wrappedValue = value
    }
}

extension SkipEncodeSendable: Decodable where T: Decodable {
   public init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      self.wrappedValue = try container.decode(T.self)
   }
}

extension SkipEncodeSendable: Encodable {
   public func encode(to encoder: Encoder) throws {
      // nothing to do here
   }
}

public extension KeyedEncodingContainer {
    mutating func encode<T>(_ value: SkipEncode<T>, forKey key: K) throws {
      // overload, but do nothing
   }
}
