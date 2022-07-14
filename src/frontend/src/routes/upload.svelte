<script lang="ts">
	import Button from '$lib/components/Button.svelte';
	import { uploadToBucket, analyzeText } from '$lib/helpers/firebase';
	import HiddenFileSelect from '$lib/components/HiddenFileSelect.svelte';
	import { addVideo } from '$lib/helpers/server';

	let fileSelect: HiddenFileSelect;
	let uploadInfo: {
		uploading: boolean;
		selected: File | undefined;
		error: string;
	} = {
		uploading: false,
		selected: undefined,
		error: ''
	};

	let uploaded = false;

	async function uploadFile() {
		uploadInfo.error = '';
		if (uploadInfo.selected) {
			uploadInfo.uploading = true;
			const analysisResult: any = await analyzeText(`${name}. ${description}`);
			if (analysisResult.pass) {
				const resFile = await uploadToBucket(uploadInfo.selected);
				if (resFile.status === 'success') {
					await addVideo(resFile.gcsUri, name, description);
					uploadInfo.uploading = false;
					uploaded = true;
				} else {
					uploadInfo.error = resFile.error;
					uploadInfo.uploading = false;
				}
			} else {
				uploadInfo.uploading = false;
				uploadInfo.error =
					'This description and/or title violates our community guidelines. Please update the description and/or title';
			}
		}
	}

	let name = '';
	let description = '';
</script>

<div class="w-screen h-screen text-white bg-slate-900">
	<div class="flex flex-col items-center justify-center w-full h-full space-y-4">
		{#if uploaded}
			<!-- svelte-ignore a11y-media-has-caption -->
			<div>Upload successfull</div>
			<a href="/my-videos" class="underline">Go to your uploaded videos</a>
		{:else}
			<div class="text-3xl font-bold">Select a video to upload</div>

			<HiddenFileSelect
				bind:this={fileSelect}
				accept={'video/*'}
				sizeLimitMb={5}
				on:error={(_) => {
					uploadInfo = {
						error: 'File size is greater than 5 MB',
						selected: undefined,
						uploading: false
					};
				}}
				on:upload={(e) =>
					(uploadInfo = {
						error: '',
						selected: e.detail,
						uploading: false
					})}
			/>

			{#if !uploadInfo.uploading}
				<Button disabled={uploadInfo.uploading} on:click={() => fileSelect.select()}>
					{#if uploadInfo.error || uploadInfo.selected}
						Select another video
					{:else}
						Select a video
					{/if}
				</Button>
				{#if uploadInfo.selected}
					<div class="text-xs opacity-50">
						Video Selected: "{uploadInfo.selected.name}". Add name & description to upload
					</div>
				{:else}
					<div class="text-xs opacity-50">Video size is limited to 5 MB</div>
				{/if}
			{/if}

			<div class="text-md underline">Video name</div>
			<input class="bg-black" bind:value={name} cols="50" rows="5" />

			<div class="text-md underline">Video description</div>
			<textarea class="bg-black" bind:value={description} cols="50" rows="5" />

			<Button
				disabled={!name || !description || uploadInfo.uploading || !uploadInfo.selected}
				on:click={uploadFile}
			>
				{#if uploadInfo.uploading}
					...
				{:else}
					Upload Video
				{/if}
			</Button>

			{#if uploadInfo.error}
				<div class="text-red-500 text-sm font-bold">{uploadInfo.error}</div>
			{/if}
		{/if}
	</div>
</div>
