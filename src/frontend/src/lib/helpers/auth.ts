import { canisterId, createActor } from '$canisters/backend';
import { AuthClient } from '@dfinity/auth-client';
import { get } from 'svelte/store';
import { auth } from '../stores/auth';

export async function initializeAuthClient(): Promise<void> {
	let authStore = get(auth);
	if (!authStore.client) {
		const authClient = await AuthClient.create();
		auth.update((o) => {
			return { ...o, client: authClient };
		});
		authStore = get(auth);
	}
	const identity = authStore.client?.getIdentity();
	const backend = createActor(canisterId as string, {
		agentOptions: { identity }
	});
	const principal = await backend.whoami();
	const tokens = await backend.myTokens();
	if (await authStore.client?.isAuthenticated()) {
		auth.set({
			client: authStore.client,
			isLoggedIn: true,
			tokens: Number(tokens),
			identity: identity,
			principal
		});
	} else {
		auth.set({ client: authStore.client, isLoggedIn: false, tokens: 0, principal });
	}
}
