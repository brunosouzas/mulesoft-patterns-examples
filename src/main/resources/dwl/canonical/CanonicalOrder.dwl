%dw 2.0
// Canonical data model: the one order shape every translator maps to or from.
// Sources map their format into it (From*.dwl); targets map it into theirs (To*.dwl). No source knows a target.
// CanonicalOrder is a validated order: closed ({| |}), no field may be null. The target translators take it as
// their parameter type, so calling one with an order of another shape fails at the call (tested in
// cdm-target-translator-rejects-an-order-that-is-not-canonical).
type CanonicalItem = {| sku: String, quantity: Number, unitPrice: Number |}
type CanonicalOrder = {|
	orderId: String,
	source: String,
	customerId: String,
	country: String,
	currency: String,
	items: Array<CanonicalItem>
|}

// A decimal string as a Number, or null when it is missing or not a number, so the canonical order can be
// validated in one place instead of failing inside each translator.
fun decimalOrNull(value: Any): Number | Null =
	if ((value is String) and ((value as String) matches /-?[0-9]+(\.[0-9]+)?/)) (value as String) as Number
	else if (value is Number) value as Number
	else null

// What a source translator returns: the canonical shape with every field present, before validation. A field
// the source did not send (or sent in a form that cannot be read, such as a quantity "two") is null here, so
// problems() can name it. The source translators declare it as their return type: it is the same shape as
// CanonicalOrder, with null allowed until the validation has run.
type CanonicalItemDraft = {| sku: String | Null, quantity: Number | Null, unitPrice: Number | Null |}
type CanonicalOrderDraft = {|
	orderId: String | Null,
	source: String,
	customerId: String | Null,
	country: String,
	currency: String | Null,
	items: Array<CanonicalItemDraft>
|}

// The reasons a canonical order is not valid; an empty array when it is. An order with no problems is a
// CanonicalOrder, the type the target translators take.
fun problems(order: Object): Array<String> = [
	("orderId is required") if isEmpty(order.orderId),
	("customerId is required") if isEmpty(order.customerId),
	("country is required") if isEmpty(order.country),
	("currency is required") if isEmpty(order.currency),
	("currency must be one ISO 4217 code for the whole order") if ((not isEmpty(order.currency)) and not ((order.currency as String) matches /[A-Z]{3}/)),
	("at least one item is required") if ((not (order.items is Array)) or isEmpty(order.items)),
	("every item needs a sku, a quantity above zero and a unit price") if ((order.items is Array) and
		not isEmpty((order.items default []) filter (isEmpty($.sku) or ($.quantity == null) or (($.quantity default 0) <= 0) or ($.unitPrice == null))))
]
