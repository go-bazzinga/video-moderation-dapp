<script lang="ts">
	import { generateSignedUrl } from '$lib/helpers/firebase';
	import Alert from '$lib/assets/Alert.svelte';
	import ThumbsUp from '$lib/assets/ThumbsUp.svelte';
	import type { Principal } from '@dfinity/principal';
	import { report, upvote } from '$lib/helpers/server';
	import PlayIcon from '$lib/assets/PlayIcon.svelte';

	export let videoUri = '';
	export let name = '';
	export let description = '';
	export let upvoted = false;
	export let upvotes = 0;
	export let reported = false;
	export let uploadedBy: Principal;
	export let uploadedAt: BigInt;
	export let viewMode = false;
	export let isProcessing = false;
	export let isReported = false;
	export let isRejected = false;

	let reportedLocal = false;
	let paused: boolean = true;
	let disableButton = false;
	let dateObj = new Date(Number(uploadedAt) / 1000000);
	let date = dateObj.toLocaleDateString() + ' ' + dateObj.toLocaleTimeString();

	async function handleUpvote() {
		disableButton = true;
		upvoted ? upvotes-- : upvotes++;
		upvoted = !upvoted;
		await upvote(upvoted, videoUri, uploadedBy);
		disableButton = false;
	}

	async function handleReport() {
		disableButton = true;
		reportedLocal = true;
		await report(videoUri, uploadedBy);
		disableButton = false;
	}
</script>

{#await generateSignedUrl(videoUri) then videoUrl}
	<custom-video
		class="flex flex-col min-w-sm max-w-sm w-full space-y-2 p-2 border-[1px] border-white/10"
	>
		<!-- svelte-ignore a11y-media-has-caption -->
		<div class="flex flex-col space-y-2 relative">
			<video src={videoUrl} bind:paused />
			<div
				on:click={() => (paused = !paused)}
				class="absolute inset-0 p-2 w-full h-full text-xs opacity-80 flex items-center justify-center"
			>
				<button
					class="absolute flex z-[4] w-24 h-24 items-center p-2 justify-center transition-opacity duration-200 {paused
						? 'opacity-100'
						: 'opacity-0'}"
				>
					<PlayIcon />
				</button>
				<div class="absolute left-0 bottom-0 p-4 flex flex-col text-md font-bold items-center">
					<button
						class={isProcessing || viewMode || disableButton ? 'pointer-events-none' : ''}
						disabled={isProcessing || viewMode || disableButton}
						on:click={handleUpvote}
					>
						<ThumbsUp filled={upvoted} />
					</button>
					<span>{upvotes}</span>
				</div>
				{#if !(isProcessing || viewMode)}
					<div
						class="absolute right-0 bottom-0 px-4 py-8 flex flex-col text-md font-bold items-center"
					>
						<button
							class={reported || disableButton ? 'pointer-events-none' : ''}
							disabled={reported || disableButton}
							on:click={handleReport}
						>
							<Alert filled={reported || reportedLocal} />
						</button>
					</div>
				{/if}
			</div>
			{#if isProcessing || isRejected || isReported}
				<div
					class="absolute scale-x-[100.1%] inset-0 z-5 -translate-y-2 pointer-events-none w-full h-full bg-black/60 flex items-center p-2 justify-center"
				>
					{#if isProcessing}
						Your video is processing
					{:else if isRejected}
						This video has been removed by voting in moderation.
					{:else if isReported}
						This video has been reported by users and is in moderation.
					{/if}
				</div>
			{/if}
		</div>
		<div class="w-full">{name}</div>
		<div class="w-full text-sm opacity-80">
			{description}
		</div>
		<div class="flex w-full text-xs opacity-80 justify-end">
			{date}
		</div>
	</custom-video>
{/await}
