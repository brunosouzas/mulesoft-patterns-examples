%dw 2.0
// Target translator: the canonical order -> the warehouse's pick list rows (written as CSV by the caller).
fun fromCanonical(order: Object): Array<Object> =
	order.items map ((item) -> { orderId: order.orderId, sku: item.sku, quantity: item.quantity, shipTo: order.country })
