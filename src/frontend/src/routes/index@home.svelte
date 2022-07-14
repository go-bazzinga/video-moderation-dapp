<script lang="ts">
	import type { PrincipalSet, UploadedVideo } from '$canisters/backend/backend.did';
	import Video from '$lib/components/Video.svelte';
	import { listAllVideos } from '$lib/helpers/server';
	import { auth } from '$lib/stores/auth';
	import type { Principal } from '@dfinity/principal';
	import { onMount } from 'svelte';

	let listOfVideos: UploadedVideo[] = [];
	let loading = true;

	onMount(async () => {
		listOfVideos = await listAllVideos();
		loading = false;
	});

	function sanitizeKeyvals(keyvals: any[]) {
		while (keyvals.filter((o) => Array.isArray(o)).length) {
			keyvals = keyvals.flat();
		}
		return keyvals.filter((o) => o != null);
	}

	function principalInSet(setVotes: PrincipalSet, principal: Principal | undefined) {
		if ('leaf' in setVotes && 'keyvals' in setVotes.leaf && principal) {
			let keyvals = sanitizeKeyvals(setVotes.leaf.keyvals);
			return keyvals.filter((o) => o.key.toText() == principal?.toText()).length > 0;
		} else {
			return false;
		}
	}
</script>

<div
	class="flex flex-col w-full h-full items-center justify-center space-y-8 overflow-hidden overflow-y-auto py-16"
>
	{#if loading}
		Loading ...
	{:else if listOfVideos.length}
		{#each listOfVideos as video}
			<Video
				videoUri={video.gcsUri}
				name={video.name}
				description={video.description}
				uploadedAt={video.uploadedAt}
				uploadedBy={video.uploadedBy}
				viewMode={!$auth.isLoggedIn}
				upvoted={principalInSet(video.upvotes.setVotes, $auth.principal)}
				reported={principalInSet(video.reports.setVotes, $auth.principal)}
				upvotes={Number(video.upvotes.count)}
			/>
		{/each}
	{:else}
		No videos uploaded yet. :(
	{/if}
</div>
