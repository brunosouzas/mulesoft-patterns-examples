%dw 2.0
import decimalOrNull from dwl::canonical::CanonicalOrder
// Source translator: the marketplace's JSON order -> the canonical order.
//   { id, buyer: { accountId }, shipping: { country }, lines: [ { listing: { sku }, units, price: { amount, currency } } ] }
fun toCanonical(order: Any) = {
	orderId: if (isEmpty(order.id)) null else "ORD-" ++ order.id,
	source: "MARKETPLACE",
	customerId: if (isEmpty(order.buyer.accountId)) null else "CUS-" ++ order.buyer.accountId,
	country: upper(order.shipping.country default ""),
	currency: order.lines[0].price.currency default "BRL",
	items: (order.lines default []) map ((line) -> {
		sku: line.listing.sku,
		quantity: decimalOrNull(line.units),
		unitPrice: decimalOrNull(line.price.amount)
	})
}
