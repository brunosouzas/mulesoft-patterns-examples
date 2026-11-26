%dw 2.0
import decimalOrNull, CanonicalOrderDraft from dwl::canonical::CanonicalOrder
// Source translator: the marketplace's JSON order -> the canonical order (not yet validated).
//   { id, buyer: { accountId }, shipping: { country }, lines: [ { listing: { sku }, units, price: { amount, currency } } ] }
// The marketplace gives a currency per line and the canonical order has one: the lines' currencies joined, so
// lines in two currencies give "BRL,USD", which the canonical validation rejects, and no currency gives null.
fun toCanonical(order: Any): CanonicalOrderDraft = {
	orderId: if (isEmpty(order.id)) null else "ORD-" ++ order.id,
	source: "MARKETPLACE",
	customerId: if (isEmpty(order.buyer.accountId)) null else "CUS-" ++ order.buyer.accountId,
	country: upper(order.shipping.country default ""),
	currency: do {
		var currencies = ((order.lines default []) map ($.price.currency default "")) filter (not isEmpty($)) distinctBy $
		---
		if (isEmpty(currencies)) null else (currencies joinBy ",")
	},
	items: (order.lines default []) map ((line) -> {
		sku: line.listing.sku,
		quantity: decimalOrNull(line.units),
		unitPrice: decimalOrNull(line.price.amount)
	})
}
