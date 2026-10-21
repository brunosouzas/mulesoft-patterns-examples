%dw 2.0
// Message translator: the partner's product codes and this application's SKUs.
var skuByProductCode = {
	"BOOK-01": "SKU-BOOK",
	"MUG-02": "SKU-MUG",
	"EBOOK-03": "SKU-EBOOK",
	"POSTER-04": "SKU-POSTER"
}

// The SKU of a partner product code, or null when the code is unknown.
fun skuFor(productCode: String | Null): String | Null = if (productCode == null) null else skuByProductCode[productCode]
