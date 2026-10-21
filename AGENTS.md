# mulesoft-patterns-examples: project context

Stack: Mule 4, MUnit, Maven

## Purpose

A catalogue of runnable Mule 4 examples of design and integration patterns, one series per folder, each with MUnit tests and an accompanying article series.

- **SOLID** (`solid/`, complete): before-and-after examples of the five SOLID principles. Each principle has a **before** endpoint that breaks the principle and an **after** endpoint that follows it, and MUnit tests show where the two behave the same and where the "before" version causes problems.
- **Enterprise Integration Patterns** (`eip/`, in progress): one folder and one MUnit suite per runnable pattern, using HTTP and object stores only (and the Aggregators module for the aggregator), so the app runs with no external systems. Wave 1 (idempotent receiver, correlation identifier) and wave 2 (content-based router, message filter, splitter, aggregator, recipient list, scatter-gather) are runnable; the patterns and their endpoints are listed in [README.md](README.md#enterprise-integration-patterns). Patterns that need a broker (publish-subscribe, dead letter channel) are documented with Anypoint MQ configuration in the wiki, not here; do not simulate a broker with VM queues.

HTTP endpoint paths are referenced by published articles; do not change them when moving files.

EIP examples use the kit Mule naming rules; SOLID keeps the names its published articles quote.

## Technology declarations

- `app.runtime = 4.9.17` — [pom.xml](pom.xml).
- `mule.maven.plugin.version = 4.9.1` — [pom.xml](pom.xml).
- `munit.version = 3.7.1` — [pom.xml](pom.xml).
- `mule.http.connector.version = 1.11.3` — [pom.xml](pom.xml).
- `mule.objectstore.connector.version = 1.3.2` — [pom.xml](pom.xml).
- `mule.aggregators.module.version = 1.1.5` — [pom.xml](pom.xml).
- `Declared minimum Mule runtime 4.9.0` — [mule-artifact.json](mule-artifact.json).

These are source declarations, not evidence of installed runtimes. Maven properties may describe build/test dependencies rather than supported runtime minima; unresolved expressions remain inherited until verified.

## Layout and operation sources

Top-level source/documentation directories: `docs`, `src`.

- `src/main/mule/global.xml`: shared global configuration (HTTP listener, properties, error handler) for every series.
- `src/main/mule/eip/eip-global.xml`: configuration shared by the EIP examples only (HTTP requester to this app).
- `src/main/mule/eip/<pattern>/`: one folder per EIP pattern, holding its flows and its own global elements (object stores); `src/test/munit/eip/<pattern>-test-suite.xml` is its suite.
- `src/main/mule/<series>/`, `src/test/munit/<series>/`, `docs/contracts/<series>/`: flows, MUnit suites and contracts of one series (`solid`, `eip`).
- [README.md](README.md).
- [mule-artifact.json](mule-artifact.json).
- [pom.xml](pom.xml).

GitHub default branch inspected on 2026-10-06: `main`. Release bases are defined by the project sources, separately from that setting. Build/publish commands mentioned by those sources are context, not authorization.

## Project rules

Before planning, reviewing or changing this project, read [the applicable project rules](rules/README.md).
