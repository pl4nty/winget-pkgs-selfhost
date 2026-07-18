import { defineConfig } from 'oxfmt';

export default defineConfig({
	useTabs: true,
	singleQuote: true,
	sortImports: {},
	ignorePatterns: [
		'manifests/**',
		'fonts/**',
		'index/**',
		'.github/workflows/analyses.json',
	],
});
