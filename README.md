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

MUnit runs on the Mule Enterprise runtime, so Maven needs access to the MuleSoft Enterprise repository (credentials in `~/.m2/settings.xml`, as in any MuleSoft project). The build fails below 80% application coverage; the current suites cover 93 cases at about 99%.

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

In progress. Patterns from Hohpe and Woolf's *Enterprise Integration Patterns*, implemented in Mule 4 around one scenario: an order is routed, charged and paid by a payment provider, its stock is reserved, and it is invoiced. Every runnable example uses HTTP and object stores only (plus the Aggregators module for the aggregator), so it needs no broker and no external system.

**Wave 1, messaging and reliability:**

| Pattern | Scenario | Code | Endpoints |
|---|---|---|---|
| Idempotent receiver | Charge an order once, however many times it is sent. **Before:** `<idempotent-message-validator/>` with no configuration uses the `correlationId` as the message ID, so a retrying client is charged twice and different orders sent from one For Each are rejected as duplicates. **After:** `idExpression="#[payload.orderId]"` with an explicit object store (24-hour TTL) | [`eip/idempotent-receiver/`](src/main/mule/eip/idempotent-receiver) | `POST /eip/payments/before/charges`, `POST /eip/payments/after/charges`, `POST /eip/payments/{before\|after}/charges/batch`, `GET /eip/payments/{orderId}/charges` |
| Correlation identifier | **Book meaning:** after a charge, a payment request goes to a simulated provider carrying its own ID; the provider answers 202 and later calls back with that ID as `correlationId`, which is the only link back to the order. Callbacks can arrive in any order. The callback's `status` decides the outcome: `APPROVED` for the requested amount marks the order `PAID`, `DECLINED` marks it `PAYMENT_DECLINED`, and an `APPROVED` for another amount or any other status marks it `PAYMENT_REVIEW` (with `reviewReason` `AMOUNT_MISMATCH` or `UNKNOWN_STATUS`); all three answer 200. A callback with no pending request (unknown, expired, or a repeat of one already matched) gets 404. **Mule meaning** (kept separate): the HTTP requester sends the event's `correlationId` in `X-CORRELATION-ID`, unless `sendCorrelationId="NEVER"` | [`eip/correlation-identifier/`](src/main/mule/eip/correlation-identifier) | `POST /eip/provider/payments` (provider), `POST /eip/payments/callback`, `GET /eip/payments/{orderId}/status`, `GET /eip/correlation-id/call/{default\|never}`, `GET /eip/correlation-id/echo` |
| Publish-subscribe channel | Documented with Anypoint MQ configuration in the wiki, not runnable here: it needs an Anypoint MQ broker (exchange and bound queues) | — | — |
| Dead letter channel | Documented with Anypoint MQ configuration in the wiki, not runnable here: it needs an Anypoint MQ broker (queue with a dead-letter queue and a maximum delivery count) | — | — |

**Wave 2, routing:**

| Pattern | Scenario | Code | Endpoints |
|---|---|---|---|
| Content-based router | A Choice sends each order to exactly one handler, by content: amount at or above `eip.router.reviewThreshold` (1000) to manual review, a country other than `eip.orders.homeCountry` (BR) to international fulfilment, everything else to domestic fulfilment. The first matching `when` wins, so a high-value international order goes to review; `otherwise` makes the router total | [`eip/content-based-router/`](src/main/mule/eip/content-based-router) | `POST /eip/orders/route` |
| Message filter | Only `PAID` orders may reserve stock. **Before:** the Choice "discards" an unpaid order, but the reservation sits after the Choice, so it still runs: the caller is told `DISCARDED` and the stock is reserved anyway. In the book a Message Filter is a Content-Based Router with a single output; a Mule Choice route ends and the flow continues. Mule 4 replaces Mule 3 filters with the Validation module (`validation:is-true` and the other validators raise `VALIDATION` errors), or a `raise-error` handled by `on-error-continue`. **After:** the reservation is inside the route that lets the order through | [`eip/message-filter/`](src/main/mule/eip/message-filter) | `POST /eip/stock/{before\|after}/reservations`, `GET /eip/stock/{orderId}/reservations` |
| Splitter | An order is split into its items and each item's stock is checked. **For Each:** sequential; after the scope the payload is the original order again, results are collected in a variable, and variables set inside are still visible. **Parallel For Each:** concurrent; after the scope the payload is the list of route messages in input order, and variables set inside the routes are not visible | [`eip/splitter/`](src/main/mule/eip/splitter) | `POST /eip/stock/availability/for-each`, `POST /eip/stock/availability/parallel-for-each` |
| Aggregator | The warehouse confirms an order's items one request at a time; a group-based aggregator (Aggregators module 1.1.5) groups them by `orderId` with `groupSize` from the item's `itemCount`, and the item that completes the group gets the invoice (201; the others 202). An item for a finished group gets 409 (`AGGREGATORS:GROUP_COMPLETED`); a group whose items stop arriving times out after `eip.invoice.groupTimeoutSeconds` (5) and an aggregator listener records the invoice `INCOMPLETE`; its missing item then gets 409 (`AGGREGATORS:GROUP_TIMED_OUT`) | [`eip/aggregator/`](src/main/mule/eip/aggregator) | `POST /eip/invoices/items`, `POST /eip/invoices/orders` (client that splits an order and posts its items), `GET /eip/invoices/{orderId}` |
| Recipient list | The recipients of a new order are computed from it (invoicing always; warehouse for physical items; digital delivery for digital items; customs for physical items shipped abroad), and a For Each sends the order to each one over HTTP, with the path looked up in configuration (`eip.recipientList.paths`). Each delivery is in its own Try, so one failing recipient is recorded `FAILED` and the others are still notified. In the book, Scatter-Gather is a Recipient List plus an Aggregator | [`eip/recipient-list/`](src/main/mule/eip/recipient-list) | `POST /eip/orders/notifications`, `POST /eip/recipients/{recipient}/orders` (simulated downstream systems), `GET /eip/orders/{orderId}/notifications` |
| Scatter-gather | Before an order is accepted, a Scatter-Gather runs three checks in parallel against simulated services (pricing, stock, fraud) and combines them: `REJECTED` when an item is out of stock, `REVIEW` for a high-risk customer, else `ACCEPTED`. When one route fails, the others still finish and Scatter-Gather raises `MULE:COMPOSITE_ROUTING`; its `error.errorMessage.payload` holds the `results` of the successful routes and the `failures` of the failed one, by route key, and the endpoint answers 503 with that partial result (`INCOMPLETE`) | [`eip/scatter-gather/`](src/main/mule/eip/scatter-gather) | `POST /eip/orders/checks`, `POST /eip/services/{pricing\|stock\|fraud}` (simulated services) |

The MUnit suites are in [`src/test/munit/eip/`](src/test/munit/eip), one per pattern. What the wave 1 suites show, observed on Mule 4.9.17 with MUnit 3.7.1:

- With no `objectStore`, the idempotent validator keeps IDs in memory for 5 minutes (the defaults in the 4.9.17 runtime's `IdempotentMessageValidator`). Three different orders posted over HTTP from one For Each give `accepted,duplicate,duplicate`; with `idExpression="#[payload.orderId]"` they give `accepted,accepted,accepted`.
- The validator stores the ID when it accepts the message and does not remove it when the flow fails afterwards: a retry of an order whose charge failed is rejected as a duplicate and never charged (`idempotent-after-failed-charge-keeps-the-id-so-the-retry-is-a-duplicate`).
- The out-of-order test sends the provider callbacks itself (B before A), so the order is deterministic; the end-to-end test lets the simulated provider call back on its own, from an `async` scope.
- The simulated provider always approves. The DECLINED, amount-mismatch, unknown-status and repeated-callback tests send the callback themselves.
- The callback flow removes (claims) the pending request before it updates the order. A repeated or late callback, sent after the first one was matched, finds no pending request and gets 404 (`cid-repeated-callback-returns-404-and-keeps-the-first-outcome`). The flow also turns `OS:KEY_NOT_FOUND` from the remove into 404, so a concurrent copy that read the pending request but loses the claim to another copy gets 404 instead of 500, and is logged as a lost claim (`cid-callback-that-loses-the-claim-returns-404-and-changes-nothing`). This is not a lock. With the in-memory stores used here, outside a Mule cluster each worker has its own store, so a callback that reaches a worker that did not store the request gets 404. When the stores are persistent (Object Store v2 on CloudHub), two copies handled at the same moment by two workers can still both update the order: Object Store v2 has no distributed lock to prevent it.

What the wave 2 suites show, observed on Mule 4.9.17 with MUnit 3.7.1 and Aggregators 1.1.5:

- A Choice does not end the flow. In the message filter "before" version an order with status `PAYMENT_DECLINED` is answered `DISCARDED` and still gets one stock reservation (`filter-before-unpaid-order-is-reported-discarded-but-stock-is-reserved`); in the "after" version it gets none.
- After For Each the payload is the original order and a variable set inside the scope keeps its last value; after Parallel For Each the payload is a list of three messages (`payload[0].payload` is the first item's result), in input order, and a variable set inside a route is `null` after the scope.
- The aggregator answers 202, 202, 201 to the three items of an order sent by the client, and groups interleaved items of two orders by `orderId`. The timeout test waits for the group to time out (5 seconds, checked by the module once a second), so the aggregator suite takes about 9 seconds.
- With the fraud route failing (`HTTP:SERVICE_UNAVAILABLE`), the pricing and stock routes still run once each, and their results are read from the `MULE:COMPOSITE_ROUTING` error (`sg-failed-route-raises-composite-routing-with-the-other-results`).
- In the recipient list, the simulated warehouse answers 503 to an order whose `orderId` starts with `ORD-WAREHOUSE-DOWN`: its delivery is recorded `FAILED` with `HTTP:SERVICE_UNAVAILABLE`, and the recipient after it is still notified (`rl-failed-recipient-does-not-stop-the-others`).

Notes:

- Object stores are in memory so every run starts clean. In production use a persistent, shared store (Object Store v2 on CloudHub): an in-memory store is lost on restart and is not shared between replicas.
- VM queues are not used to stand in for a broker: the VM connector is an in-application queue, not a message broker.
- The aggregator keeps its groups in an object store too. In production, and always in a cluster, use a persistent, shared store, or a group whose items reach different workers never completes.

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
    content-based-router/
      content-based-router.xml     Choice routes an order to review, international or domestic fulfilment
    message-filter/
      message-filter-before.xml    Choice as a filter, with the reservation after it (runs for every order)
      message-filter-after.xml     the reservation inside the route that lets paid orders through
      stock-reservation-common.xml simulated reservation, ledger, validation
    splitter/
      splitter.xml                 For Each and Parallel For Each over an order's items
    aggregator/
      aggregator.xml               group-based aggregator, timed-out group listener, invoice lookup
      aggregator-client.xml        client that splits an order and posts its items over HTTP
    recipient-list/
      recipient-list.xml           computed recipients, For Each with a Try per delivery
      recipient-list-recipients.xml  simulated downstream systems and their inbox
    scatter-gather/
      scatter-gather.xml           parallel order checks, MULE:COMPOSITE_ROUTING handler
      scatter-gather-services.xml  simulated pricing, stock and fraud services
src/main/resources/config/app.yaml   port, OCP payment routing, DIP repository choice, EIP self-call host, callback path and routing settings
src/test/munit/
  solid/<principle>-test-suite.xml
  eip/<pattern>-test-suite.xml
docs/contracts/
  solid/                     RAML types for the LSP and ISP contracts
requests.http                sample requests for every endpoint
```

## Licence

[MIT](LICENSE) © Bruno Pinto de Souza
