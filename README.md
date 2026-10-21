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

MUnit runs on the Mule Enterprise runtime, so Maven needs access to the MuleSoft Enterprise repository (credentials in `~/.m2/settings.xml`, as in any MuleSoft project). The build fails below 80% application coverage; the current suites cover 143 cases at about 99.8%.

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

In progress. Patterns from Hohpe and Woolf's *Enterprise Integration Patterns*, implemented in Mule 4 around one scenario: an order is routed, charged and paid by a payment provider, its stock is reserved, and it is invoiced. Every runnable example uses HTTP, DataWeave and object stores only (plus the Aggregators module for the aggregator), so it needs no broker and no external system.

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
| Recipient list | The recipients of a new order are computed from it (invoicing always; warehouse for physical items; digital delivery for digital items; customs for physical items shipped abroad), and a For Each sends the order to each one over HTTP, with the path looked up in configuration (`eip.recipientList.paths`). Each delivery is in its own Try, so one failing recipient is recorded `FAILED` and the others are still notified. A partial failure still answers 200, with `allDelivered: false`: each notification stands on its own, the ones delivered are done and the failed ones are reported for a retry. Scatter-gather answers 503 instead, because its decision cannot be made without every reply. In the book, Scatter-Gather is a Recipient List plus an Aggregator | [`eip/recipient-list/`](src/main/mule/eip/recipient-list) | `POST /eip/orders/notifications`, `POST /eip/recipients/{recipient}/orders` (simulated downstream systems), `GET /eip/orders/{orderId}/notifications` |
| Scatter-gather | Before an order is accepted, a Scatter-Gather runs three checks in parallel against simulated services (pricing, stock, fraud) and combines them: `REJECTED` when an item is out of stock, `REVIEW` for a high-risk customer, else `ACCEPTED`. When one route fails, the others still finish and Scatter-Gather raises `MULE:COMPOSITE_ROUTING`; its `error.errorMessage.payload` holds the `results` of the successful routes and the `failures` of the failed one, by route key, and the endpoint answers 503 with that partial result (`INCOMPLETE`) | [`eip/scatter-gather/`](src/main/mule/eip/scatter-gather) | `POST /eip/orders/checks`, `POST /eip/services/{pricing\|stock\|fraud}` (simulated services) |

**Wave 3, transformation:**

| Pattern | Scenario | Code | Endpoints |
|---|---|---|---|
| Message translator | A partner sends an order as CSV, one row per line; a Transform Message (DataWeave) turns it into this app's JSON order. The translation changes the structure (rows become one order with an items array), the types (CSV strings become numbers, cents become units) and the codes (partner product codes become SKUs through a lookup module). A row whose product code has no SKU, or rows of two orders, make the request 400 instead of producing an order that looks valid and is wrong | [`eip/message-translator/`](src/main/mule/eip/message-translator) | `POST /eip/orders/translate` (`application/csv`) |
| Canonical data model | Orders arrive from the marketplace (JSON) and from a partner (XML purchase order) and go to invoicing (JSON) and the warehouse (CSV pick list). Every source translates into one canonical order and every target from it: N + M translators, as DataWeave modules in [`src/main/resources/dwl/canonical/`](src/main/resources/dwl/canonical), instead of N × M. With two and two both are 4; the gain is the next one, since a third source needs one translator, not one per target. The canonical order is validated once, whatever the source | [`eip/canonical-data-model/`](src/main/mule/eip/canonical-data-model) | `POST /eip/canonical/orders/marketplace`, `POST /eip/canonical/orders/partner` (`application/xml`) |
| Content filter | A paid order carries the card, contact details, item costs, suppliers and internal notes. Before it goes to the (simulated) invoicing system, a Transform keeps only what invoicing needs, flattened (`customerId`, `customerName`, `taxId`, `billingCountry`, `paymentReference`, `lines`). It selects and flattens and computes nothing: no total, which is invoicing's job. The filter is an allow list: a field the order gains later does not reach invoicing until someone adds it to the transform | [`eip/content-filter/`](src/main/mule/eip/content-filter) | `POST /eip/billing/invoice-requests`, `POST /eip/invoicing/invoices` and `GET /eip/invoicing/invoices/{orderId}` (simulated invoicing) |
| Claim check | An order's document (base64) is checked in to an object store under a claim key; only `{ orderId, claimKey, fileName }` is sent to the (simulated) archive, which checks the document out with the key. Checking out does not remove it: the claim is valid until the store's `entryTtl` (`eip.claimCheck.ttlSeconds`, 3 seconds here) ends, and then the key gets 404 (`OS:KEY_NOT_FOUND` turned into `APP:NOT_FOUND`) | [`eip/claim-check/`](src/main/mule/eip/claim-check) | `POST /eip/orders/documents`, `GET /eip/orders/documents/{claimKey}`, `POST /eip/archive/documents` (simulated archive) |
| Content enricher | An order with only a `customerId` gets the customer's name, tier and shipping address from a (simulated) CRM. Mule 4 has no enricher scope: the HTTP request stores the answer in a target variable (`target="vCustomer"`, `targetValue="#[payload.customer]"`), so the order is still the payload after the call and a Transform merges the two. When the CRM is down (503, unreachable or timed out) the target variable is not set and the order is not passed on: 503 with `enrichment: FAILED`. An unknown customer is 400 | [`eip/content-enricher/`](src/main/mule/eip/content-enricher) | `POST /eip/orders/enrich`, `GET /eip/services/customers/{customerId}` (simulated CRM; `CUS-DOWN...` answers 503) |

**Wave 4, endpoints:**

| Pattern | Scenario | Code | Endpoints |
|---|---|---|---|
| Request-reply | A stock reservation asked of the simulated warehouse two ways. **Synchronous:** the requestor's HTTP request waits for the reply, which is the HTTP response; the requestor's caller waits too (at least the warehouse's 300 ms, `waitedMillis`). **Asynchronous:** the requestor answers 202 `PENDING`; the warehouse answers 202 and later, from an Async scope, posts the reservation to a reply channel fixed in configuration (`eip.requestReply.replyChannelPath`). Matching uses the `orderId`; the full matching problem is the wave-1 correlation identifier, not duplicated here | [`eip/request-reply/`](src/main/mule/eip/request-reply) | `POST /eip/stock/reservations/{sync\|async}`, `POST /eip/warehouse/reservations`, `POST /eip/warehouse/reservation-requests` (simulated warehouse), `POST /eip/stock/reservation-replies` (reply channel), `GET /eip/stock/reservation-replies/{orderId}` |
| Return address | The invoice request carries the requestor's reply channel in `X-Reply-To`; invoicing answers 202 and posts the invoice to that address, so two requestors (checkout, backoffice) each get their own invoice. Only a path of the form `/eip/requestors/{requestor}/invoice-replies` is accepted (400 otherwise, an absolute URL included), so the return address cannot make the replier call anywhere else | [`eip/return-address/`](src/main/mule/eip/return-address) | `POST /eip/invoice-requests`, `POST\|GET /eip/requestors/{requestor}/invoice-replies` |
| Event-driven consumer | The HTTP Listener is the trigger: each payment event runs the flow when it arrives, and the order is `PAID` by the time the sender has its 200. VM Listener and Anypoint MQ Subscriber are the messaging equivalents (no broker simulated) | [`eip/event-driven-consumer/`](src/main/mule/eip/event-driven-consumer) | `POST /eip/payment-events`, `GET /eip/payment-events/{orderId}` |
| Polling consumer | A Scheduler (`fixed-frequency` 1000 ms, `disallowConcurrentExecution`) polls a pending-orders list in an object store. The list is never emptied; a watermark (highest sequence processed) in another object store makes each order allocated once, however many polls run. The watermark is stored after processing, so a failed poll is read again (at least once) | [`eip/polling-consumer/`](src/main/mule/eip/polling-consumer) | `POST /eip/stock/pending-orders`, `GET /eip/stock/polled-orders` |
| Competing consumers | Several consumers (Parallel For Each; consumer flow `maxConcurrency` = `eip.competingConsumers.consumers`, 3) walk one shared invoice work list; each item is claimed with `os:store failIfPresent="true"`, so the first consumer owns it and the others get `OS:KEY_ALREADY_EXISTS` and skip it. With a queue the broker does this | [`eip/competing-consumers/`](src/main/mule/eip/competing-consumers) | `POST /eip/invoice-work/items`, `POST /eip/invoice-work/runs`, `POST /eip/invoice-work/consumers/{consumerId}/runs`, `GET /eip/invoice-work/items/{orderId}` |
| Channel adapter | The HTTP Request connector reads an order from a simulated legacy ERP that answers `;`-separated CSV with cents and one-letter status codes, and DataWeave turns it into the order message (`amount`, `status` `PAID`/`PAYMENT_DECLINED`/`REFUNDED`, else `UNKNOWN` with `legacyStatusCode`). The legacy plain-text 404 becomes the app's JSON 404. Every connector plays this role | [`eip/channel-adapter/`](src/main/mule/eip/channel-adapter) | `GET /eip/adapters/legacy-orders/{orderId}`, `GET /eip/legacy/orders/{orderId}` (simulated legacy ERP) |

The MUnit suites are in [`src/test/munit/eip/`](src/test/munit/eip), one per pattern. What the wave 1 suites show, observed on Mule 4.9.17 with MUnit 3.7.1:

- With no `objectStore`, the idempotent validator keeps IDs in memory for 5 minutes (the defaults in the 4.9.17 runtime's `IdempotentMessageValidator`). Three different orders posted over HTTP from one For Each give `accepted,duplicate,duplicate`; with `idExpression="#[payload.orderId]"` they give `accepted,accepted,accepted`.
- The validator stores the ID when it accepts the message and does not remove it when the flow fails afterwards: a retry of an order whose charge failed is rejected as a duplicate and never charged (`idempotent-after-failed-charge-keeps-the-id-so-the-retry-is-a-duplicate`).
- The out-of-order test sends the provider callbacks itself (B before A), so the order is deterministic; the end-to-end test lets the simulated provider call back on its own, from an `async` scope.
- The simulated provider always approves. The DECLINED, amount-mismatch, unknown-status and repeated-callback tests send the callback themselves.
- The callback flow removes (claims) the pending request before it updates the order. A repeated or late callback, sent after the first one was matched, finds no pending request and gets 404 (`cid-repeated-callback-returns-404-and-keeps-the-first-outcome`). The flow also turns `OS:KEY_NOT_FOUND` from the remove into 404, so a concurrent copy that read the pending request but loses the claim to another copy gets 404 instead of 500, and is logged as a lost claim (`cid-callback-that-loses-the-claim-returns-404-and-changes-nothing`). This is not a lock. With the in-memory stores used here, outside a Mule cluster each worker has its own store, so a callback that reaches a worker that did not store the request gets 404. When the stores are persistent (Object Store v2 on CloudHub), two copies handled at the same moment by two workers can still both update the order: Object Store v2 has no distributed lock to prevent it.

What the wave 2 suites show, observed on Mule 4.9.17 with MUnit 3.7.1 and Aggregators 1.1.5:

- A Choice does not end the flow. In the message filter "before" version an order with status `PAYMENT_DECLINED` is answered `DISCARDED` and still gets one stock reservation (`filter-before-unpaid-order-is-reported-discarded-but-stock-is-reserved`); in the "after" version it gets none.
- After For Each the payload is the original order and a variable set inside the scope keeps its last value; after Parallel For Each the payload is a list of three messages (`payload[0].payload` is the first item's result), in input order even though the `SKU-BOOK` check (300 ms) finishes after the `SKU-MUG` one (their `checkedAt`), and a variable set inside a route is `null` after the scope.
- The aggregator answers 202, 202, 201 to the three items of an order sent by the client, and groups interleaved items of two orders by `orderId`. The timeout test waits for the group to time out (5 seconds, checked by the module once a second), so the aggregator suite takes about 9 seconds.
- With the fraud route failing (`HTTP:SERVICE_UNAVAILABLE`), the pricing and stock routes still run once each, and their results are read from the `MULE:COMPOSITE_ROUTING` error (`sg-failed-route-raises-composite-routing-with-the-other-results`). The 503 body names each failed check by error type only; the error description is logged, not returned.
- In the recipient list, the simulated warehouse answers 503 to an order whose `orderId` starts with `ORD-WAREHOUSE-DOWN`: its delivery is recorded `FAILED` with `HTTP:SERVICE_UNAVAILABLE`, and the recipient after it is still notified (`rl-failed-recipient-does-not-stop-the-others`).

What the wave 3 suites show, observed on Mule 4.9.17 with MUnit 3.7.1:

- The message translator turns two CSV rows into one order with numeric quantities (`2`, not `"2"`) and prices in units (`1250` cents become `12.5`); an unknown product code is rejected by name (`unknown product code: LAMP-99`).
- The same order sent by the marketplace as JSON and by a partner as XML gives the same canonical items and the same invoicing lines, total and warehouse rows; only the ids and `source` differ (`cdm-partner-xml-gives-the-same-target-documents`). The target translators are called with a canonical order alone, without any source, and they take the `CanonicalOrder` type, so an order without a currency fails at the call (`cdm-module-target-translator-rejects-an-order-that-is-not-canonical`). An order without a currency, or with lines in two currencies, gets 400; no currency is assumed.
- What the simulated invoicing system received has exactly the seven allowed fields; the card number and the email do not appear anywhere in it, and neither does a `loyaltyCardNumber` added to the order (`cf-field-added-to-the-order-later-does-not-leak`).
- For a 200,000-byte document the archive receives a message with three fields (`orderId`, `claimKey`, `fileName`) and still archives 200,000 bytes, fetched with the key. The same key works again after the archive has used it, and 5 seconds after check-in it gets 404 (`cc-claim-expires-after-its-time-to-live`), so the claim check suite takes about 6 seconds. Over real HTTP, check-in answers 202 and check-out answers 200 with the document as `application/json` (`cc-check-out-does-not-remove-the-document`).
- In the content enricher, a spy before the merge sees the order as payload after the CRM call, and `vars.vCustomer` holds only the customer part of the answer (no `meta`), while the payload still has only the order's keys (`orderId`, `customerId`, `items`). When the CRM answers 503, a value that `vCustomer` held before the call is still there afterwards (`ce-crm-down-sets-no-target-variable-and-returns-503`), the merge does not run and the endpoint answers 503; `HTTP:CONNECTIVITY` and `HTTP:TIMEOUT` give the same 503 (`ce-crm-unreachable-returns-503`, `ce-crm-timeout-returns-503`).

What the wave 4 suites show, observed on Mule 4.9.17 with MUnit 3.7.1 (every call goes over HTTP to the app, and the tests assert status codes and content types):

- Request-reply: the synchronous response already holds the reservation and `waitedMillis` is at least 300; the asynchronous one is 202 `PENDING`, a GET right after it is still `PENDING`, and the reply arrives later, sent once to the reply channel. A reply nobody asked for gets 404.
- Return address: invoices requested with `X-Reply-To` `/eip/requestors/checkout/...` and `/eip/requestors/backoffice/...` land each in its own inbox only, one reply per request. No header, an absolute URL or another path of the app (`/eip/payments/callback`) get 400 and no reply is sent.
- Event-driven consumer: the GET made right after the event's 200 already shows the new state; two events run the flow twice, in arrival order.
- Polling consumer: an order added between polls is not allocated until the next poll; three polls over orders A, B (poll 1, 2) and C (poll 3) store three allocations and the watermark twice, each order `timesAllocated` 1. With the Scheduler source enabled, an order is allocated with no request to the poller.
- Competing consumers: three consumers over nine items process all nine, none twice, nine invoices issued, each claimed by the consumer that reports it. An item already claimed in the claims store is skipped (`OS:KEY_ALREADY_EXISTS`) and not invoiced. The claim is atomic per key on one worker; across workers only in a Mule cluster (Object Store connector reference).
- Channel adapter: the legacy endpoint answers `application/csv` (`ORD-LEGACY-1001;4250;BRL;P`), the adapter answers `application/json` `{ orderId, amount: 42.5, currency, status: PAID, source }`.

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
    message-translator/
      message-translator.xml       partner CSV order lines translated into the app's order
    canonical-data-model/
      canonical-data-model.xml     two source flows, one canonical order, two target documents
    content-filter/
      content-filter.xml           paid order filtered down to an invoice request
      content-filter-invoicing.xml simulated invoicing system that keeps what it received
    claim-check/
      claim-check.xml              check in, claim message, check out, store with a time to live
      claim-check-archive.xml      simulated archive that checks the document out with the key
    content-enricher/
      content-enricher.xml         HTTP request with a target variable, merge, CRM-down handling
      content-enricher-crm.xml     simulated customer service (CRM)
    request-reply/
      request-reply.xml            synchronous and asynchronous requestor, reply channel, reply lookup
      request-reply-warehouse.xml  simulated warehouse: synchronous and asynchronous replier
    return-address/
      return-address.xml           replier that uses X-Reply-To, requestor reply channels and inboxes
    event-driven-consumer/
      event-driven-consumer.xml    HTTP Listener-triggered payment event consumer
    polling-consumer/
      polling-consumer.xml         Scheduler poller with an object store watermark, pending list producer
    competing-consumers/
      competing-consumers.xml      shared work list, consumers with an atomic claim, Parallel For Each runner
    channel-adapter/
      channel-adapter.xml          HTTP Request + DataWeave adapter from legacy CSV to the order message
      legacy-erp.xml               simulated legacy ERP answering CSV
src/main/resources/config/app.yaml   port, OCP payment routing, DIP repository choice, EIP self-call host, callback path, routing, claim check, request-reply, polling and competing consumers settings
src/main/resources/dwl/
  translator/PartnerProducts.dwl     partner product codes -> SKUs (message translator)
  canonical/                         CanonicalOrder (type, validation), FromMarketplace, FromPartnerXml, ToInvoicing, ToWarehouse
src/test/munit/
  solid/<principle>-test-suite.xml
  eip/<pattern>-test-suite.xml
docs/contracts/
  solid/                     RAML types for the LSP and ISP contracts
requests.http                sample requests for every endpoint
```

## Licence

[MIT](LICENSE) © Bruno Pinto de Souza
