<script lang="ts">
	import type { ReportedVideo, Stake, UploadedVideo } from '$canisters/backend/backend.did';
	import Button from '$lib/components/Button.svelte';
	import Video from '$lib/components/Video.svelte';
	import {
		getTokenBalance,
		listReportedVideos,
		listReportedVideosDetails,
		vote
	} from '$lib/helpers/server';
	import { auth } from '$lib/stores/auth';
	import { onMount } from 'svelte';

	let listOfReportedVideos: ReportedVideo[] = [];
	let listOfVideos: UploadedVideo[] = [];
	let loading = true;
	let disableButton = false;
	let tokensStaked = 0;
	let stakeSelected: string = 'approve';
	let doneVoting = false;

	$: tokensStaked > $auth.tokens && (tokensStaked = $auth.tokens);
	$: tokensStaked < 0 && (tokensStaked = 0);

	function checkIfVideoIsStaked(gcsUri: string) {
		const reportedVideo = listOfReportedVideos.find((o) => o.gcsUri == gcsUri);
		if (reportedVideo) {
			const approvalStake = reportedVideo.approvalPot.stakes.find(
				(o) => o.userPrincipal.toText() == $auth.principal?.toText()
			);
			const rejectionStake = reportedVideo.rejectionPot.stakes.find(
				(o) => o.userPrincipal.toText() == $auth.principal?.toText()
			);
			const stake = approvalStake || rejectionStake;
			const closingDate = new Date(Number(reportedVideo.votingStartedAt) / 1000000);
			closingDate.setHours(closingDate.getHours() + 1);
			if (stake)
				return {
					votingWillCloseAt: closingDate,
					stakeType: approvalStake ? 'approval' : 'rejection',
					stakeDetails: stake,
					staked: approvalStake ? true : rejectionStake ? true : false
				};
			else
				return {
					stakeDetails: undefined,
					staked: false
				};
		} else {
			return {
				stakeDetails: undefined,
				staked: false
			};
		}
	}

	async function putVote(gcsUri: string) {
		disableButton = true;
		let stakeType: Stake = stakeSelected === 'approve' ? { approve: null } : { reject: null };
		const res = await vote(gcsUri, stakeType, tokensStaked);
		if (res) {
			doneVoting = true;
			const token = await getTokenBalance();
			$auth.tokens = Number(token);
		} else {
		}
		disableButton = false;
	}

	onMount(async () => {
		listOfVideos = await listReportedVideosDetails();
		listOfReportedVideos = await listReportedVideos();
		loading = false;
	});
</script>

<div class="flex flex-col items-center justify-center space-y-8 overflow-hidden overflow-y-auto">
	<div class="text-lg">Moderation videos</div>
	{#if loading}
		Loading ...
	{:else if listOfVideos.length}
		{#each listOfVideos as video}
			{@const stake = checkIfVideoIsStaked(video.gcsUri)}
			<div class="border-[1px] border-white/10 flex flex-col spacey-y-2 p-2">
				<Video
					bind:videoUri={video.gcsUri}
					bind:name={video.name}
					bind:description={video.description}
					bind:uploadedAt={video.uploadedAt}
					bind:uploadedBy={video.uploadedBy}
					viewMode
					upvotes={Number(video.upvotes.count)}
				/>
				{#if doneVoting}
					<div>Vote successfull. Your stake details:</div>
					<div>You voted for: <span class="font-bold">{stakeSelected}</span></div>
					<div>You staked {tokensStaked} tokens</div>
				{:else if stake.staked}
					<div>You have already voted. Your stake details</div>
					<div>You voted for: <span class="font-bold">{stake.stakeType}</span></div>
					<div>You staked {stake.stakeDetails?.stakedTokens} tokens</div>
					<div>Voting will close at {stake.votingWillCloseAt?.toLocaleString()}</div>
				{:else}
					<div class="text-lg font-bold">Approve or reject this video</div>
					<div>Stake tokens:</div>
					<div class="flex space-x-2">
						<div class="flex flex-col space-y-1">
							<div>Vote</div>
							<select bind:value={stakeSelected} class="bg-slate-600 p-1 text-white">
								<option value="approve">Approve</option>
								<option value="reject">Reject</option>
							</select>
						</div>
						<div class="flex flex-col space-y-1">
							<div>Tokens: <span class="text-xs">(Max: {$auth.tokens})</span></div>
							<input
								bind:value={tokensStaked}
								class="bg-slate-600 p-1"
								type="number"
								max={$auth.tokens}
								min={0}
							/>
						</div>
						<div class="flex items-end justify-end flex-1">
							<Button
								disabled={tokensStaked < 1 || disableButton}
								on:click={() => putVote(video.gcsUri)}
							>
								Vote
							</Button>
						</div>
					</div>
				{/if}
			</div>
		{/each}
	{:else}
		<div>No reported videos as of now. Please check back later</div>
	{/if}
</div>
