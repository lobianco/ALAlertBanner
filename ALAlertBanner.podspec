Pod::Spec.new do |s|
	s.name			= 'ALAlertBanner'
	s.version		= '0.3.1'
	s.summary		= 'A clean and simple alert banner for iPhone and iPad'
	s.homepage		= 'https://github.com/alobi/ALAlertBanner'
	s.author		= { 'Anthony Lobianco' => 'anthony@lobian.co' }
	s.license 		= 'MIT'
	s.platform		= :ios, '5.0'
	s.requires_arc	= true
	s.screenshots	= [ 'http://alobi.github.io/ALAlertBanner/screenshots/screenshot3.png',
						'http://alobi.github.io/ALAlertBanner/screenshots/screenshot2.png' ]
	s.source		= { :git => '.', :branch => 'ios8' }
	s.source_files	= 'ALAlertBanner/*.{h,m}'
	s.resources		= 'ALAlertBanner/Images/*.{png}'
	s.frameworks	= 'QuartzCore'
end