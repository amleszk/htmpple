Pod::Spec.new do |s|
  s.name      = "htmpple"
  s.version   = "0.1.0"
  s.platform  = :ios
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.summary     = "HTML to NSAttributedString built ontop of hpple XML parser"
  s.homepage    = "https://github.com/amleszk/htmpple"
  s.authors   = {'A M Leszkiewicz' => 'amleszk@gmail.com'}
  s.source   = { :git => 'https://github.com/amleszk/htmpple.git', :tag => '0.1.0'}  
  s.source_files = ['htmpple/Classes/*.{h,m}']
  s.requires_arc = true
  s.library      = 'xml2'
  s.xcconfig     = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }  
  s.ios.deployment_target = '6.0'
end
