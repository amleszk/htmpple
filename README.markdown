htmpple
=======

Lightweight translation layer from HTML to iOS6 NSAttributedString built ontop of hpple XML parser: https://github.com/topfunky/hpple
There is **no** CoreText code in this project

If you still support pre iOS6 you may want [DTCoreText](https://github.com/Cocoanetics/DTCoreText)

Invoke parser with `[ALHtmlToAttributedStringParser attributedStringWithHTMLData:htmlData];`

Todo 
--------

* Bug: Blue link highlight persists when cycling 
* Bug: Nested indentation for ul/blockquote (NSParagraphStyle)
* Bug: NSParagraphStyle loses its indent when using a \<br\/\>
* Bug: Adding \n and multiple spaces should not be allowed in any tag except 'pre' and 'code'

* Feature: Bold font attributes versus using new fonts
* Feature: HTML tag support for ordered list 'ol' - currently treated as 'ul'
* Feature: HTML tag support for 'table' - currently messy
* Feature: HTML tag support for horizontal rule 'hr'
* Feature: Unit Tests
* Feature: Support for link tapping inside UILabel

* Performance: replace regex with string matching for tags

Performance
--------
There's considerable performance hit when using a UITextView over UILabel. Results of performanceTest method on iPhone4s device after 200 iterations

ALLinkTextView: 19.02sec

UITextView:  18.95sec

UILabel : 11.56sec (40% faster)


the only reason to use a UITextView is to detect the location of link attributes. If anyone
knows a way to do the same thing in UILabel without using CoreText I would be interested to hear.

