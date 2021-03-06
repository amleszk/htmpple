htmpple
=======

Lightweight translation layer from HTML to iOS6 NSAttributedString built ontop of hpple XML parser: https://github.com/topfunky/hpple
There is **no** CoreText code in this project

If you still support pre iOS6 (or want more features) you may want [DTCoreText](https://github.com/Cocoanetics/DTCoreText).

The supported html tags are those you would find in a rich text editor. e.g.
a p i em b strong pre u ins del h1 h2 h3 h4 h5 h6 blockquote

![screenshot](screenshot.png)


iOS7
--------
New TextKit framework adds convenience method that does this exact translation, This project gives more control over how links are translated and allows you to switch between using UILabel for faster rendering.

The existing method of translation is:
```
NSDictionary * htmlAtt = @{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType};
NSAttributedString * htmlString = [[NSAttributedString alloc] initWithData:htmlData options:nil documentAttributes:&htmlAtt error:&error];
```

Performance
--------

There's considerable performance hit when using a UITextView over UILabel. Results of performanceTest method on iPhone4s device after 200 iterations

* ALLinkTextView: 19.02sec
* UITextView:  18.95sec
* UILabel : 11.56sec (40% faster)

UITextView actual converts attributed strings to HTML for display in a webview (see http://www.cocoanetics.com/2012/12/uitextview-caught-with-trousers-down/)
The only reason to use a UITextView is to detect the location of link text attributes without resorting to CoreText.

