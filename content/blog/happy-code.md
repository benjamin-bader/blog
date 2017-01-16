+++
date = "2016-04-06T21:42:04-07:00"
description = ""
draft = false
tags = ["java", "code", "design"]
title = "happy code"
topics = []

+++

My favorite parts of being a programmer are those moments when, after ruminating on a bit of not-quite-clean code, elegant solutions just present themselves to you.  Today's installment is from [Thrifty](https://github.com/Microsoft/thrifty), the Thrift implementation for Android I wrote at Microsoft.

Briefly, part of Thrifty's job is to generate Java classes corresponding to structs defined in Thrift IDL.  Part of that is generating descriptive `.toString()` methods.  For the first release, Thrifty generated code like this:

``` java
public String toString() {
  StringBuilder sb = new StringBuilder("Foo{");
  sb.append("bar=");
  sb.append(this.bar);
  sb.append(", ");
  sb.append("baz=");
  sb.append(this.baz);
  sb.append("}");
  return sb.toString();
}
```

Not terrible, for generated code, but nothing to write home about.  In particular, it lacks in readability and efficiency - it doesn't resemble code you or I would write by hand, and some of those literals strings could be combined to reduce the number of method calls here.  IntelliJ correctly calls out code like this as in need of replacement.

If you or I were to write this by hand, it would look something like:

``` java
public String toString() {
  return "Foo{bar=" + this.bar + ", baz=" + this.baz + "}";
}
```

I should point out that this is far from the most pressing issue - nobody realistically depends on `toString()` for anything perf-sensitive.  The only reason to improve this code is personal satisfaction - and a recent cross-country plane ride provided the perfect opportunity.

Before the fix, the code to generate `toString()` was relatively easy to follow, once you know the idioms of Square's JavaPoet codegen library.  Here's the (only slightly) simplified original version, which is hacky and very much rushed out the door by me

``` java
// The actual code is hairier, handling some extra things
MethodSpec.Builder toString = MethodSpec.methodBuilder("toString")
    .addAnnotation(Override.class)
    .addModifiers(Modifier.PUBLIC)
    .returns(String.class);

// Two things going on here:
// 1. Adding a single statement to the method
// 2. Statements can take format specifiers - here, $S means "a quoted literal string",
//    properly escaped.
toString.addStatement("StringBuilder sb = new StringBuilder($S)", struct.name() + "{");

int index = 0;  // what even was I thinking lol
for (Field f : struct.fields()) {
  boolean isLast = ++index == struct.fields().size();

  toString.addStatement("sb.append($S)", field.name() + "=");
  if (field.redacted()) {
    toString.addStatement("sb.append($S)", "<REDACTED>");
  } else {
    toString.addStatement("sb.append(this.$N)", field.name()); // "$N" as a format means "Java name"
  }

  if (isLast) {
    toString.addStatement("sb.append(\"}\")");
  } else {
    toString.addStatement("sb.append(\", \")");
  }
}

toString.addStatement("return sb.toString()");
```

OK!  Pretty simple, right?  Except for that `index` bit, it's not so bad.  Easy to read, relatively speaking.  It's easy because generating this kind of code is uncomplicated.  The better example, the one without `StringBuilder`, takes a good deal more consideration.  Around 20,000 feet into the air, I started to think.  What needs to change here?  Obviously, we need to detect when two "compile-time-constant" strings are adjacent, like the example above of the `", "` followed by `"baz="`.  How do we track that?  We could keep the same structure, but just add pieces of strings together:

``` java
return "Foo{" + "bar=" + this.bar + ", " + "baz=" + this.baz + "}";
```

An improvement!  This is significantly more readable, and just about every compiler out there will optimize out the constant concatenations.  The fact is, though, it still looks kind of goofy, and with this reduced character count the extra contatenations are quite a bit of noise obscuring the actual signal.

Turns out, the solution that I hit on is to introduce a new class (hey, it's Java) to represent a chunk of code, which can be either a literal string or a reference to a field.  You can build a list of these chunks in one pass through the field list, and then emit each chunk of code in order.  Splitting the generation into two passes removes the need for hard-to-reason-about flags, and lets us focus on doing this more-complicated process correctly:

``` java
class Chunk {
  final String formatSpecifier;
  final String value;

  Chunk(boolean isString, String value) {
    this.formatSpecifier = isString ? "$S" : "$L";
    this.value = value;
  }
};

List<Chunk> chunks = new ArrayList<>();

StringBuilder sb = new StringBuilder();
boolean appendedOneField = false; // no more index
for (Field field : struct.fields()) {
  if (appendedOneField) {
    sb.append(", ");
  } else {
    appendedOneField = true;
  }

  if (field.redacted()) {
    sb.append("<REDACTED>");
  } else {
    chunks.add(new Chunk(true, sb.toString()));
    chunks.add(new Chunk(false, "this." + field.name))

    sb.setLength(0);
  }
}

sb.append("}");
chunks.add(new Chunk(true, sb.toString()));

// Now, we can actually generate code!
boolean firstChunk = true;

// MethodSpec.Builder lets us work with whole statements at once;
// we want finer-grained control over the emitted Java right now.
// CodeBlock.Builder is an in-progress Java snippet.
CodeBlock.Builder block = CodeBlock.builder();

for (Chunk chunk : chunks) {
  if (firstChunk) {
    block.add("$[");  // Start-of-statement
    block.add("return ");
  } else {
    block.add(" + ");
  }

  block.add(chunk.formatSpecifier, chunk.value);
}

block.add(";$]\n"); // end-of-statement gibberish
toString.addCode(block.build());
```

...and, that's it!  The method is significantly longer now, but it remains readable - and best of all, we acheived what we set out to accomplish!  `.toString()` methods that look the way we want them to.  This is pretty 
