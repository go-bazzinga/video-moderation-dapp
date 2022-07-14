<script lang="ts">
	import Button from './Button.svelte';
	import { auth } from '$lib/stores/auth';
	import { browser } from '$app/env';
	import { initializeAuthClient } from '$lib/helpers/auth';
	import { getTokenBalance } from '$lib/helpers/server';

	async function handleAuthenticated() {
		if (browser) {
			initializeAuthClient();
		}
	}

	async function handleError(e: any) {
		console.error('Error while logging in', e);
	}

	export async function handleLogin() {
		await $auth.client?.login({
			onSuccess: handleAuthenticated,
			onError: handleError,
			identityProvider:
				process.env.NODE_ENV === 'development'
					? `http://${process.env.INTERNET_IDENTITY_CANISTER_ID}.localhost:8000`
					: 'https://identity.ic0.app/#authorize'
		});
	}

	async function handleLogout() {
		await $auth.client?.logout();
		$auth.isLoggedIn = false;
	}

	let identity = $auth.identity;

	$: identity && updateTokens();

	async function updateTokens() {
		const token = await getTokenBalance();
		$auth.tokens = Number(token);
	}
</script>

<div
	class="fixed z-50 top-0 bg-slate-800 text-sm shadow-xl text-white py-3 w-full flex items-center justify-between"
>
	<a href="/" class="font-bold ml-8 px-4 py-1 text-orange-500"> Moderation dApp </a>
	<div class="flex items-center space-x-2 pr-8">
		{#if $auth.isLoggedIn}
			<div class="flex flex-col space-y-1">
				<div class="flex text-right flex-wrap items-center space-x-4 justify-end">
					<a class="underline" href="/">Home</a>
					<a class="underline" href="/my-videos">My Videos</a>
					<a class="underline" href="/upload">Upload new video</a>
					<a class="underline" href="/moderation">Moderation</a>
					<span>Tokens: {$auth.tokens}</span>
					<span class="underline cursor-pointer" on:click={handleLogout}>Logout</span>
				</div>
				<div class="text-xs opacity-50">Logged in as: {$auth.principal?.toText()}</div>
			</div>
		{:else}
			<Button on:click={handleLogin}>Login</Button>
		{/if}
	</div>
</div>
