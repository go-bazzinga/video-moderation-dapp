<script lang="ts">
	import '../css/main.css';
	import { browser } from '$app/env';
	import { initializeAuthClient } from '$lib/helpers/auth';
	import { Buffer } from 'buffer'; // @dfinity/agent requires this. Can be removed once it's fixed
	import Navbar from '$lib/components/Navbar.svelte';
	import { onMount } from 'svelte';

	onMount(async () => {
		if (browser) {
			window.Buffer = Buffer;
			await initializeAuthClient();
		}
	});
</script>

<svelte:head>
	<title>Video Moderation dApp</title>
</svelte:head>

<div class="relative overflow-hidden text-white bg-slate-900 w-full h-full pt-20">
	<Navbar />
	<slot />
</div>
