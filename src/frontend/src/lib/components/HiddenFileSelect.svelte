<script lang="ts">
	import { createEventDispatcher } from 'svelte';

	export function select() {
		inputEl.click();
	}
	export let sizeLimitMb = 5;
	export let accept: string;

	const dispatch = createEventDispatcher<{ upload: File; error: 'file-size' }>();

	let inputEl: HTMLInputElement;

	function handleFileChange(files: FileList | null) {
		if (files && files[0]) {
			const size = files[0].size / (1024 * 1024);
			if (size > sizeLimitMb) {
				dispatch('error', 'file-size');

				inputEl.value = '';
			} else {
				dispatch('upload', files[0]);
			}
		}
	}
</script>

<input
	class="hidden"
	bind:this={inputEl}
	type="file"
	{accept}
	on:change={(e) => handleFileChange(e.currentTarget.files)}
/>
