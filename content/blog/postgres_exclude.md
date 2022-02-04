---
title: "Postgres EXCLUDE constraints"
date: 2020-04-28T17:43:44-07:00
draft: true
slug: "postgres-exclude-constraints"
---

TIL about [exclusion constraints](https://www.postgresql.org/docs/12/sql-createtable.html#SQL-CREATETABLE-EXCLUDE) in postgres.  Constraints are familiar to most - primary & foreign keys, unique, check, etc, are all relatively common.  This, on the other hand, is something rather different and powerful (and, it must be said, vendor-specific).  Exclusion constraints are kind of esoteric, but today at least were incredibly useful!

### Motivation

My use-case is that I have a table where nothing is ever updated or deleted - instead, rows are "versioned".  Like so:
```
CREATE TABLE example (uuid text, name text, version integer);
```

Entities are uniquely identifed by UUID.  Changes to entities are realized as new rows, with a higher version number - older versions are simply "inactive".  To spice things up, I wanted to add a unique constraint on "name".  The naive way, `CREATE UNIQUE INDEX ON example (uuid, name)` won't work due to our versioning scheme.  Next I thought of creating a unique partial index on only active rows, but was thwarted there as well - partial-index predicates can only refer to one row at a time, which means that we can't tell the DB "index only those rows where version = MAX(version) group by uuid".  I had nearly resigned myself to just handling this in code when a stray Stack Overflow post gave me a crucial hint.

TL;DR:
```
ALTER TABLE example
ADD CONSTRAINT unique_names
EXCLUDE USING gist (name WITH =, uuid WITH <>);
```

### What is EXCLUDE, really?

Exclude constraints are expressed in terms of _indexes_, _exclude elements_, and _operators_.  An exclude constraint states that


This is gibberish, but it works. What it says is, using a `gist` index, block any inserts/updates that cause two rows to match the following column/operator pairs.  In other words, comparing column "name" via operator "=", and column "uuid" with operator "<>".  So, any rows with the same name, but different UUIDs, will fail the constraint and be rejected.  You can get really fancy with these - there are a ton of different operators you can use, like `&&` (overlaps, for time ranges),

### Motivation, explained