# Fitness event feeds: explicit dates, stable identity and visible conflicts

Robin Winters · October 2, 2026 · [robin.ac](https://robin.ac/)

A map can look polished while the events behind it are ambiguous. Two feeds may repeat a record, supply different start times for the same event, or omit the timezone. Guessing produces a neat interface at the cost of hiding uncertainty. A better starting point is a small contract that makes each decision inspectable.

This article accompanies a [standalone Swift teaching package](https://github.com/RobinWinters/fitness-event-data-pipeline), prepared with coding-assistant support. Its fixtures are synthetic. It is separate from private ShowFlex code and does not claim a customer deployment, an implemented product integration or measured performance improvements.

## Start with the fields you can actually defend

The example accepts a provider ID, a feed ID, a title, a start timestamp, an optional end timestamp and an HTTPS source URL. The combination of feed ID and provider ID becomes the stable identity. Titles are display text; a matching title does not justify merging records. Different feeds can describe related real-world events, but cross-feed entity resolution requires evidence that this package deliberately does not invent.

The package normalizes the feed slug to lowercase and trims provider IDs while preserving their case. Neither ID may contain the colon used to join them. That keeps `feed-a:event-17` unambiguous within the stated contract. A real service would also need to establish whether each provider guarantees stable IDs across updates and deletions.

## Timezone ambiguity is a data state

`2027-03-14T10:00:00-07:00` has an explicit offset and can be represented as `2027-03-14T17:00:00Z`. A timestamp without an offset does not establish that instant. The example rejects it instead of using the machine's local timezone. It also rejects invalid calendar dates rather than allowing them to roll into a different day.

An unknown end time remains absent. Adding a guessed two-hour duration would manufacture information. If an end is supplied, it must be later than the start. Date-only events, recurring schedules, named timezones and fractional seconds need their own policies; unsupported timestamp forms are rejected here.

UTC output makes the normalization reproducible. A calendar or mobile interface would still need a deliberate display-timezone policy. That interface work is outside this package's execution evidence.

## A duplicate and a conflict deserve different treatment

Two valid rows with the same identity and the same normalized payload are retransmissions. Keep one event and issue a duplicate receipt for the other row. Equivalent explicit-offset timestamps and collapsed title whitespace can produce an identical normalized payload.

Two different valid payloads with the same identity are a conflict. The example removes that event from accepted output and marks every related valid row as conflicted, including a duplicate already seen earlier. No row wins simply because it arrived first. Permuting the input order therefore cannot choose a different accepted version of that conflicting identity.

This is a teaching policy, not the only useful production policy. A provider revision number, authenticated correction or trusted snapshot might establish a winner. Without that evidence, a quarantine is easier to explain than a silent overwrite.

## Return a receipt for every row

The output includes sorted accepted events and one receipt per input row: accepted, duplicate, conflict or rejected. Each receipt records the input index and a reason. A rejected row can therefore be traced to the input rather than disappearing into an apparently successful empty array.

The supplied five-row fixture produces one accepted event, one duplicate receipt, two conflict receipts and one invalid-date rejection. Invalid JSON exits with status 1 and produces no successful JSON report. That distinction matters when a command-line tool is used in a larger workflow: malformed input and a valid feed containing no accepted events are different outcomes.

## Keep provenance narrower than proof

The source URL is retained as a retrieval pointer. The package rejects non-HTTPS URLs, embedded credentials and fragments. It does not fetch those URLs, authenticate a provider or establish that a claimed event exists. Every fixture URL uses the reserved example.org domain.

Storing provenance is a useful first step toward investigating a record. It should not be described as verification of that record. A production ingestion system needs provider authorization, versioned snapshots, update and deletion rules, observability and retry behavior alongside its field validation.

## Evidence a reviewer can inspect

On October 2, 2026, the package passed 12 Swift Testing checks on macOS with Swift 6.4. The checks cover timezone equivalence, retransmissions, conflict propagation and ordering, source-scoped identity, malformed dates, missing offsets, end-time rules, URL restrictions, unknown ends and sorted output. The command-line fixture and malformed-JSON failure path were also exercised. The repository includes [fixtures](https://github.com/RobinWinters/fitness-event-data-pipeline/tree/Radpository/Fixtures) and [verification details](https://github.com/RobinWinters/fitness-event-data-pipeline/blob/Radpository/verification.json).

These results describe this educational package. They do not establish iPhone-device execution, Linux execution, an App Store release or an improvement to an existing product. The value of the example is that its contracts and failure decisions are small enough to inspect and reproduce.

[Professional work and evidence](../professional/README.md) · [Full writing index](README.md) · [Source package](https://github.com/RobinWinters/fitness-event-data-pipeline)
