Run `flutter test --coverage` from the `stanag_app/` directory, then use `lcov --summary coverage/lcov.info` for the overall line rate.

Parse `stanag_app/coverage/lcov.info` to extract per-file line coverage. For each source file under `lib/`, report:
- lines covered / lines total
- coverage percentage

Then produce two sections:

**Coverage report** — a table of all instrumented files sorted by coverage % ascending.

**Testing priorities** — for each uncovered or under-covered file, one sentence on what the highest-value test would be, informed by how critical the code path is (auth, data writes, business logic first; UI glue and providers second). Base the priority ranking on the implementation phase the file belongs to and the risk of the logic it contains, not just line count.

If `lcov` is not installed, note that and show only the raw `flutter test --coverage` output plus the per-file breakdown parsed directly from `lcov.info`.
