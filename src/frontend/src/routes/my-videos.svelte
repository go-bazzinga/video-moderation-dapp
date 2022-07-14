<script lang="ts">
	import type { UploadedVideo } from '$canisters/backend/backend.did';
	import Video from '$lib/components/Video.svelte';
	import { listMyVideos } from '$lib/helpers/server';
	import { onMount } from 'svelte';

	let listOfVideos: UploadedVideo[] = [];
	let loading = true;

	onMount(async () => {
		listOfVideos = await listMyVideos();
		loading = false;
	});
</script>

<div class="flex flex-col items-center justify-center space-y-8 overflow-hidden overflow-y-auto">
	<div class="text-lg">Your videos</div>
	{#if loading}
		Loading ...
	{:else if listOfVideos.length}
		{#each listOfVideos as video}
			{@const isProcessing = 'processing' in video.status || 'uploaded' in video.status}
			<Video
				bind:videoUri={video.gcsUri}
				bind:name={video.name}
				bind:description={video.description}
				bind:uploadedAt={video.uploadedAt}
				bind:uploadedBy={video.uploadedBy}
				{isProcessing}
				isReported={'reported' in video.status}
				isRejected={'rejected' in video.status}
				viewMode
				upvotes={Number(video.upvotes.count)}
			/>
		{/each}
	{:else}
		<div>You have no videos.</div>
		<a class="underline" href="/upload">Click here to upload a video</a>
	{/if}
</div>
