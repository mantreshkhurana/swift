// RUN: %target-run-simple-swift(-enable-experimental-feature VariadicGenerics -Xfrontend -disable-availability-checking)

// REQUIRES: executable_test

// Because of -enable-experimental-feature VariadicGenerics
// REQUIRES: asserts

// UNSUPPORTED: use_os_stdlib
// UNSUPPORTED: back_deployment_runtime

import StdlibUnittest

var tuples = TestSuite("VariadicGenericConformances")

protocol TypeMaker {
  func makeType() -> Any.Type
}

struct TupleMaker<each T> : TypeMaker {
  func makeType() -> Any.Type {
    return (repeat (each T)).self
  }
}

func makeTypeIndirectly<T: TypeMaker>(_ t: T) -> Any.Type {
  return t.makeType()
}

struct ElementTupleMaker<each T: Sequence> : TypeMaker {
  func makeType() -> Any.Type {
    return (repeat (each T).Element).self
  }
}

tuples.test("makeTuple1") {
  expectEqual("()", _typeName(makeTypeIndirectly(TupleMaker< >())))

  // FIXME: This should unwrap the one-element tuple!
  // expectEqual("(Swift.Int)", _typeName(makeTypeIndirectly(TupleMaker<Int>())))

  expectEqual("(Swift.Int, Swift.Bool)", _typeName(makeTypeIndirectly(TupleMaker<Int, Bool>())))
}

tuples.test("makeTuple2") {
  expectEqual("()", _typeName(makeTypeIndirectly(ElementTupleMaker< >())))

  // FIXME: This should unwrap the one-element tuple!
  // expectEqual("(Swift.Int)", _typeName(makeTypeIndirectly(ElementTupleMaker<Array<Int>>())))

  expectEqual("(Swift.Int, Swift.Bool)", _typeName(makeTypeIndirectly(ElementTupleMaker<Array<Int>, Set<Bool>>())))
}

protocol Q {
  associatedtype A

  func makeA() -> A
}

extension Q {
  func makeA() -> [Self] { return [self] }
}

extension String: Q {}
extension Int: Q {}
extension Bool: Q {}

protocol HasPackRequirements {
  func doStuff1<each T: Q>(_ value: repeat each T) -> (repeat each T.A)
  func doStuff2<each T: Q>(_ value: repeat each T) -> (repeat each T.A)
}

extension HasPackRequirements {
  func doStuff1<each T: Q>(_ value: repeat each T) -> (repeat each T.A) {
    return (repeat (each value).makeA())
  }
}

struct ConformsPackRequirements: HasPackRequirements {
  func doStuff2<each T: Q>(_ value: repeat each T) -> (repeat each T.A) {
    return (repeat (each value).makeA())
  }
}

func testPackRequirements1<T: HasPackRequirements, each U: Q>(_ t: T, _ u: repeat each U)
    -> (repeat each U.A) {
  return t.doStuff1(repeat each u)
}

func testPackRequirements2<T: HasPackRequirements, each U: Q>(_ t: T, _ u: repeat each U)
    -> (repeat each U.A) {
  return t.doStuff2(repeat each u)
}

tuples.test("packRequirements") {
  expectEqual(([1], ["hi"], [false]), testPackRequirements1(ConformsPackRequirements(), 1, "hi", false))
  expectEqual(([1], ["hi"], [false]), testPackRequirements2(ConformsPackRequirements(), 1, "hi", false))
}

runAllTests()
