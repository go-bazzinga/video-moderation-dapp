<script lang="ts">
	import '../css/main.css';
	import { browser } from '$app/env';
	import { initializeAuthClient } from '$lib/helpers/auth';
	import { Buffer } from 'buffer'; // @dfinity/agent requires this
	import Navbar from '$lib/components/Navbar.svelte';
	import { onMount } from 'svelte';
	import { auth } from '$lib/stores/auth';
	import Button from '$lib/components/Button.svelte';
	import { afterNavigate } from '$app/navigation';

	onMount(async () => {
		if (browser) {
			window.Buffer = Buffer;
			await initializeAuthClient();
		}
	});

	let loading = true;
	let navbar: Navbar;

	afterNavigate(() => {
		loading = false;
	});
</script>

<svelte:head>
	<title>Video Moderation dApp</title>
</svelte:head>

<div class="relative overflow-hidden text-white bg-slate-900 w-full h-full pt-20">
	<Navbar bind:this={navbar} />
	{#if !loading}
		{#if $auth.isLoggedIn}
			<slot />
		{:else}
			<div class="flex flex-col space-y-4 items-center">
				<div>You're not logged in to see this page</div>
				<Button on:click={() => navbar.handleLogin()}>Login</Button>
			</div>
		{/if}
	{/if}
</div>
