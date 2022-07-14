import adapter from '@sveltejs/adapter-static';
import preprocess from 'svelte-preprocess';
import path from 'path';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const dfxJson = require('./../../dfx.json');

const isDev = process.env.NODE_ENV === 'development';
// Gets the port dfx is running on from dfx.json
const DFX_PORT = dfxJson.networks.local.bind.split(':')[1];

let canisterIds;
try {
	canisterIds = isDev
		? require('./../../.dfx/local/canister_ids.json')
		: require('./../../canister_ids.json');
} catch (e) {
	console.error('Error finding canisters info', e);
	throw '⚠ Before starting the dev server you need to run: `dfx deploy`';
}

// Generate canister ids, required by the generated canister code in .dfx/local/canisters/*
// This strange way of JSON.stringifying the value is required by vite
const canisterDefinitions = Object.entries(canisterIds).reduce(
	(acc, [key, val]) => ({
		...acc,
		[`process.env.${key.toUpperCase()}_CANISTER_ID`]: isDev
			? JSON.stringify(val.local)
			: JSON.stringify(val.ic)
	}),
	{}
);

/** @type {import('@sveltejs/kit').Config} */
const config = {
	preprocess: preprocess({
		postcss: true
	}),

	kit: {
		vite: {
			resolve: {
				alias: {
					$canisters: path.resolve('./src/declarations')
				}
			},
			define: {
				// Here we can define global constants
				// This is required for now because the code generated by dfx relies on process.env being set
				...canisterDefinitions,
				'process.env.NODE_ENV': JSON.stringify(isDev ? 'development' : 'production')
			},
			server: {
				proxy: {
					// This proxies all http requests made to /api to our running dfx instance
					'/api': {
						target: `http://localhost:${DFX_PORT}`
					}
				}
			}
		},
		adapter: adapter()
	}
};

export default config;