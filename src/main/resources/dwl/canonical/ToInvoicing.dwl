%dw 2.0
// Target translator: the canonical order -> the invoicing system's invoice request (JSON).
fun fromCanonical(order: Object) = {
	invoiceFor: order.orderId,
	customer: order.customerId,
	currency: order.currency,
	lines: order.items map ((item) -> { sku: item.sku, qty: item.quantity, amount: item.quantity * item.unitPrice }),
	total: sum(order.items map ($.quantity * $.unitPrice))
}
