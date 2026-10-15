# MuleSoft patterns — runnable examples

A catalogue of design and integration patterns applied to Mule 4, one series at a time. Each series is a set of small, runnable flows with MUnit tests, and accompanies an article series on [brunosouzas.com](https://brunosouzas.com).

| Series | Status | Code |
|---|---|---|
| [SOLID in MuleSoft](#solid-in-mulesoft) | Complete | [`src/main/mule/solid/`](src/main/mule/solid) |
| [Enterprise Integration Patterns](#enterprise-integration-patterns) | In progress | [`src/main/mule/eip/`](src/main/mule/eip) |

Everything runs in one Mule application and needs no external systems: ERPs, databases and payment providers are simulated with synthetic data, so it runs anywhere.

## Run

Requirements: Java 17, Maven 3.9+, Mule runtime 4.9 (Anypoint Studio or a standalone runtime).

- **Anypoint Studio:** import the project (File → Import → Anypoint Studio project from file system) and run it. The app listens on port `8081`.
- **Try it:** open `requests.http` in VS Code (REST Client) or IntelliJ and send the requests, or use curl:

```bash
curl -s 'localhost:8081/lsp/before/orders/ORD-1001?provider=new'
```

## Test

```bash
mvn clean test
```

MUnit runs on the Mule Enterprise runtime, so Maven needs access to the MuleSoft Enterprise repository (credentials in `~/.m2/settings.xml`, as in any MuleSoft project). The build fails below 80% application coverage; the current suites cover 55 cases at about 99%.

## SOLID in MuleSoft

Before-and-after examples of the five SOLID principles applied to Mule 4 flows. Each principle has a **before** endpoint that breaks the principle and an **after** endpoint that follows it, and MUnit tests show where the two behave the same and where the "before" version causes problems.

Articles: [SOLID in MuleSoft](https://brunosouzas.com/blog/solid-in-mulesoft-the-art-of-designing-evolutionary-integrations) (also available [in Portuguese](https://brunosouzas.com/pt/blog/solid-em-mulesoft)).

| Principle | Scenario | Before | After | Code | Article |
|---|---|---|---|---|---|
| **S**ingle Responsibility | Process an order | One flow validates, prices and calls the ERP | The flow orchestrates; each step is a focused sub-flow | [`solid/srp/`](src/main/mule/solid/srp) | [SRP](https://brunosouzas.com/blog/single-responsibility-principle-srp-in-mulesoft-structuring-flows-with-focused-responsibilities) |
| **O**pen/Closed | Take a payment | A choice router that must be edited for every new method | The router looks up the implementation in config; `pix` was added without touching it | [`solid/ocp/`](src/main/mule/solid/ocp) | [OCP](https://brunosouzas.com/blog/openclosed-principle-ocp-in-mulesoft-apis-and-flows-that-evolve-without-breaking) |
| **L**iskov Substitution | Read an order from the legacy or the new ERP | The new ERP adapter looks compatible but changes values and error behaviour, so the consumer silently takes wrong decisions | Both adapters honour the whole contract (shape, values, errors) and can replace each other | [`solid/lsp/`](src/main/mule/solid/lsp) | [LSP](https://brunosouzas.com/blog/liskov-substitution-principle-lsp-in-mulesoft-ensuring-consistency-and-substitutability) |
| **I**nterface Segregation | Read an order | One endpoint returns everything to everyone, including internal cost data | Mobile and finance each get an interface shaped for their need | [`solid/isp/`](src/main/mule/solid/isp) | [ISP](https://brunosouzas.com/blog/interface-segregation-principle-isp-in-mulesoft-specific-interfaces-for-specific-needs) |
| **D**ependency Inversion | Read an order and decide if it can be cancelled | The business rule knows the legacy ERP's field names and codes | The rule depends on an "order repository"; in-memory and ERP adapters are swapped in config | [`solid/dip/`](src/main/mule/solid/dip) | [DIP](https://brunosouzas.com/blog/dependency-inversion-principle-dip-in-mulesoft-rely-on-abstractions-not-implementations) |

The MUnit suites are in [`src/test/munit/solid/`](src/test/munit/solid) and the RAML contracts for LSP and ISP in [`docs/contracts/solid/`](docs/contracts/solid). The HTTP endpoints keep their paths (`/srp/...`, `/ocp/...`, `/lsp/...`, `/isp/...`, `/dip/...`), so the calls shown in the articles still work.

Notes:

- The OCP router uses a dynamic `flow-ref`. MUnit only loads flows that are referenced statically, so the OCP suite references the payment implementations in a `before-suite`. Real applications do not need this.
- Everything here is intentionally small. The point is the shape of the flows, not the business logic.

## Enterprise Integration Patterns

In progress. Patterns from Hohpe and Woolf's *Enterprise Integration Patterns*, implemented in Mule 4 around one scenario: an order is charged and then paid by a payment provider. Every runnable example uses HTTP and object stores only, so it needs no broker and no external system.

| Pattern | Scenario | Code | Endpoints |
|---|---|---|---|
| Idempotent receiver | Charge an order once, however many times it is sent. **Before:** `<idempotent-message-validator/>` with no configuration uses the `correlationId` as the message ID, so a retrying client is charged twice and different orders sent from one For Each are rejected as duplicates. **After:** `idExpression="#[payload.orderId]"` with an explicit object store (24-hour TTL) | [`eip/idempotent-receiver/`](src/main/mule/eip/idempotent-receiver) | `POST /eip/payments/before/charges`, `POST /eip/payments/after/charges`, `POST /eip/payments/{before\|after}/charges/batch`, `GET /eip/payments/{orderId}/charges` |
| Correlation identifier | **Book meaning:** after a charge, a payment request goes to a simulated provider carrying its own ID; the provider answers 202 and later calls back with that ID as `correlationId`, which is the only link back to the order. Callbacks can arrive in any order. **Mule meaning** (kept separate): the HTTP requester sends the event's `correlationId` in `X-CORRELATION-ID`, unless `sendCorrelationId="NEVER"` | [`eip/correlation-identifier/`](src/main/mule/eip/correlation-identifier) | `POST /eip/provider/payments` (provider), `POST /eip/payments/callback`, `GET /eip/payments/{orderId}/status`, `GET /eip/correlation-id/call/{default\|never}`, `GET /eip/correlation-id/echo` |
| Publish-subscribe channel | Documented with Anypoint MQ configuration in the wiki, not runnable here: it needs an Anypoint MQ broker (exchange and bound queues) | — | — |
| Dead letter channel | Documented with Anypoint MQ configuration in the wiki, not runnable here: it needs an Anypoint MQ broker (queue with a dead-letter queue and a maximum delivery count) | — | — |

The MUnit suites are in [`src/test/munit/eip/`](src/test/munit/eip). What they show, observed on Mule 4.9.17 with MUnit 3.7.1:

- With no `objectStore`, the idempotent validator keeps IDs in memory for 5 minutes (the defaults in the 4.9.17 runtime's `IdempotentMessageValidator`). Three different orders posted over HTTP from one For Each give `accepted,duplicate,duplicate`; with `idExpression="#[payload.orderId]"` they give `accepted,accepted,accepted`.
- The validator stores the ID when it accepts the message and does not remove it when the flow fails afterwards: a retry of an order whose charge failed is rejected as a duplicate and never charged (`idempotent-after-failed-charge-keeps-the-id-so-the-retry-is-a-duplicate`).
- The out-of-order test sends the provider callbacks itself (B before A), so the order is deterministic; the end-to-end test lets the simulated provider call back on its own, from an `async` scope.

Notes:

- Object stores are in memory so every run starts clean. In production use a persistent, shared store (Object Store v2 on CloudHub): an in-memory store is lost on restart and is not shared between replicas.
- VM queues are not used to stand in for a broker: the VM connector is an in-application queue, not a message broker.

## Layout

```
src/main/mule/
  global.xml                 shared: HTTP listener, properties, error handler (400/404 as JSON)
  solid/                     SOLID in MuleSoft
    srp/ ocp/ lsp/ isp/ dip/
      <principle>-before.xml
      <principle>-after.xml
  eip/                       Enterprise Integration Patterns
    eip-global.xml           HTTP requester the examples use to call this same app
    idempotent-receiver/
      idempotent-receiver-before.xml
      idempotent-receiver-after.xml
      payment-common.xml     simulated charge, ledger, batch client
    correlation-identifier/
      correlation-identifier.xml   book meaning: provider request, callback, status
      mule-correlation-id.xml      Mule meaning: X-CORRELATION-ID propagation
src/main/resources/config/app.yaml   port, OCP payment routing, DIP repository choice, EIP self-call host and callback path
src/test/munit/
  solid/<principle>-test-suite.xml
  eip/<pattern>-test-suite.xml
docs/contracts/
  solid/                     RAML types for the LSP and ISP contracts
requests.http                sample requests for every endpoint
```

## Licence

[MIT](LICENSE) © Bruno Pinto de Souza
