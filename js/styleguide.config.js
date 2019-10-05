const path = require('path');

module.exports = {
	// set your styleguidist configuration here
	title: 'Mobilizon Style Guide',
	components: 'src/components/**/[A-Z]*.vue',
	exampleMode: 'expand',
	usageMode: 'expand',
	require: [
		path.join(__dirname, 'config/global.requires.js'),
	],
	pagePerSection: true,
	minimize: true,
	verbose: false,
	renderRootJsx: path.join(__dirname, 'config/styleguide.root.js'),
	sections: [
		{
			name: 'Introduction',
			content: 'docs/index.md',
			exampleMode: 'hide',
			usageMode: 'hide'
		},
		{
			name: 'Directives',
			content: 'docs/directives.md'
		},
		{
			name: 'Components',
			content: 'docs/components.md',
			components: 'src/components/*/*.vue',
		}
	],
	template: {
		head: {
		  links: [
			{
			  rel: 'stylesheet',
			  href:
				'https://cdn.materialdesignicons.com/4.4.95/css/materialdesignicons.min.css',
			  crossorigin: 'anonymous'
			}
		  ]
		}
	  }
}
