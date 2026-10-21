%dw 2.0
import CanonicalOrder from dwl::canonical::CanonicalOrder
// Target translator: the canonical order -> the invoicing system's invoice request (JSON).
// Takes a CanonicalOrder (validated: no null fields), so an order of another shape fails at the call.
type InvoiceRequest = {| invoiceFor: String, customer: String, currency: String, lines: Array<{| sku: String, qty: Number, amount: Number |}>, total: Number |}
fun fromCanonical(order: CanonicalOrder): InvoiceRequest = {
	invoiceFor: order.orderId,
	customer: order.customerId,
	currency: order.currency,
	lines: order.items map ((item) -> { sku: item.sku, qty: item.quantity, amount: item.quantity * item.unitPrice }),
	total: sum(order.items map ($.quantity * $.unitPrice))
}
