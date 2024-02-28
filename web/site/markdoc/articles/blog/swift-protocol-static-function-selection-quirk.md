---
title: 'Swift Protocol Static Function Selection Quirk'
date: '2022-04-27T15:56:05Z'
description:
  I've been writing a lot of heavily generic Swift code lately, and figured out what seems
  (to me at least) to be a really useful quirk/edge-case having to do with how Swift
  selects between a protocol extension _static_ method, and a static method implemented on
  a conforming type.
category: engineering
---

I've been writing a lot of heavily generic Swift code lately, and figured out what seems
(to me at least) to be a really useful quirk/edge-case having to do with how Swift selects
between a protocol extension _static_ method, and a static method implemented on a
conforming type.

Consider this Swift code:

```swift
protocol Animal {
  static var type: String { get }
}

extension Animal {
  static func greeting() -> String {
    return "I am an animal of type: \(type)"
  }
}

struct Cat: Animal {
 static var type = "Cat"

 static func greeting() -> String {
    return "Meow, I'm a cute Cat"
  }
}

func greet<A: Animal>(_ AnimalType: A.Type) {
  print(AnimalType.greeting())
}

greet(Cat.self) // 🧐 what will this line print ???
```

My intuition was that the line marked would print `"Meow, I'm a cute Cat"`, but in fact it
prints `"I am an animal of type: Cat"`, with Swift for some reason choosing the generic,
fallback method supplied as a protocol extension instead of the specific implementation
provided by the conforming type.

I've run into this seemingly wrong function selection in a way that was pretty frustrating
for a ORM-type Swift library I've been working on. However, I just figured out that I can
get Swift to use the correct method by _also declaring the function as **protocol
requirement**_, that is, by adding the line marked below:

```swift
protocol Animal {
  static var type: String { get }
  static func greeting() -> String // 👋 🎉 this fixes the issue
}
```
