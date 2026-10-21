%dw 2.0
import decimalOrNull, CanonicalOrderDraft from dwl::canonical::CanonicalOrder
// Source translator: the partner's XML purchase order -> the canonical order (not yet validated).
//   <PurchaseOrder number="..." currency="..."><Customer code="..."/><ShipTo country="..."/>
//     <Lines><Line sku="..." quantity="..." unitPrice="..."/>...</Lines></PurchaseOrder>
fun toCanonical(document: Any): CanonicalOrderDraft = do {
	var po = document.PurchaseOrder
	---
	{
		orderId: if (isEmpty(po.@number)) null else "ORD-" ++ po.@number,
		source: "PARTNER",
		customerId: if (isEmpty(po.Customer.@code)) null else "CUS-" ++ po.Customer.@code,
		country: upper(po.ShipTo.@country default ""),
		currency: if (isEmpty(po.@currency)) null else po.@currency,
		items: (po.Lines.*Line default []) map ((line) -> {
			sku: line.@sku,
			quantity: decimalOrNull(line.@quantity),
			unitPrice: decimalOrNull(line.@unitPrice)
		})
	}
}
