%dw 2.0
// Canonical data model: the one order shape every translator maps to or from.
// Sources map their format into it (From*.dwl); targets map it into theirs (To*.dwl). No source knows a target.
type CanonicalItem = { sku: String, quantity: Number, unitPrice: Number }
type CanonicalOrder = {
	orderId: String,
	source: String,
	customerId: String,
	country: String,
	currency: String,
	items: Array<CanonicalItem>
}

// A decimal string as a Number, or null when it is missing or not a number, so the canonical order can be
// validated in one place instead of failing inside each translator.
fun decimalOrNull(value: Any): Number | Null =
	if ((value is String) and ((value as String) matches /-?[0-9]+(\.[0-9]+)?/)) (value as String) as Number
	else if (value is Number) value as Number
	else null

// The reasons a canonical order is not valid; an empty array when it is.
fun problems(order: Object): Array<String> = [
	("orderId is required") if isEmpty(order.orderId),
	("customerId is required") if isEmpty(order.customerId),
	("country is required") if isEmpty(order.country),
	("at least one item is required") if ((not (order.items is Array)) or isEmpty(order.items)),
	("every item needs a sku, a quantity above zero and a unit price") if ((order.items is Array) and
		not isEmpty((order.items default []) filter (isEmpty($.sku) or ($.quantity == null) or (($.quantity default 0) <= 0) or ($.unitPrice == null))))
]
