%dw 2.0
import CanonicalOrder from dwl::canonical::CanonicalOrder
// Target translator: the canonical order -> the warehouse's pick list rows (written as CSV by the caller).
// Takes a CanonicalOrder (validated: no null fields), so an order of another shape fails at the call.
type PickListRow = {| orderId: String, sku: String, quantity: Number, shipTo: String |}
fun fromCanonical(order: CanonicalOrder): Array<PickListRow> =
	order.items map ((item) -> { orderId: order.orderId, sku: item.sku, quantity: item.quantity, shipTo: order.country })
