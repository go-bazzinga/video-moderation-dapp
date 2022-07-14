<script lang="ts">
	export let disabled = false;
</script>

<button
	class="px-4 py-2 bg-orange-500 hover:bg-orange-600 rounded-md disabled:bg-orange-900"
	{disabled}
	on:click
>
	<slot />
</button>
