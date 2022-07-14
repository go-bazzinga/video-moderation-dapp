import type { Identity } from '@dfinity/agent';
import type { AuthClient } from '@dfinity/auth-client';
import type { Principal } from '@dfinity/principal';
import { writable } from 'svelte/store';

export const auth = writable<{
	client?: AuthClient;
	isLoggedIn: boolean;
	identity?: Identity;
	principal?: Principal;
	tokens: number;
}>({
	client: undefined,
	isLoggedIn: false,
	tokens: 0
});
