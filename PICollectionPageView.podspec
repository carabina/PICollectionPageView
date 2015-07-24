Pod::Spec.new do |s|

  s.name         = "PICollectionPageView"
  s.version      = "0.0.1"
  s.summary      = "A UICollectionView base page view"

  s.description  = <<-DESC
                   A UICollectionView base page view

                   - Can be use as drop in for `UICollectionView`, 
                   - Reuse most of `UICollectionView` delegate methods
                   - Simple interface and very easy to use.
                   
                   DESC

  s.homepage     = "https://github.com/phamquy/PICollectionPageView"
  s.license      = { :type => "MIT", :file => "LICENSE" }



  s.author       = { "Pham Quy" => "phamsyquybk@gmail.com" }
  s.platform     = :ios, "6.0"
  s.source       = { :git => "https://github.com/phamquy/PICollectionPageView.git" :tag => s.version}
  s.source_files = "PICollectionPageView/**/*.{h,m}"

  s.framework    = 'UIKit'
  s.requires_arc = true
  s.public_header_files = 'PICollectionPageView/*.h'

end
