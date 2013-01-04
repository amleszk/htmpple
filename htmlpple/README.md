htmpple
=======

Lightweight translation layer from HTML to iOS6 NSAttributedString built ontop of hpple XML parser: https://github.com/topfunky/hpple

Similar to [DTCoreText](https://github.com/Cocoanetics/DTCoreText) with

NOT DONE
--------

* Feature: Support for non iOS6 string attributes
* Feature: Unit Tests
* Bug: Nested indentation for ul/blockquote (NSParagraphStyle)
* Bug: NSParagraphStyle loses its indent when using a <br/>
* Feature: Bold font attributes versus new fonts
* Performance: replace regex with string matching for tags
--
* Feature: Additional HTML tag support
** ordered lists are treated as unordered (ol)
** horizontal rule (hr)
