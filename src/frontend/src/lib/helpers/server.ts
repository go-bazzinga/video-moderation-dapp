import { canisterId, createActor } from '$canisters/backend';
import type { Stake, UploadedVideoStatus } from '$canisters/backend/backend.did';
import { auth } from '$lib/stores/auth';
import type { Principal } from '@dfinity/principal';
import { get } from 'svelte/store';

export async function listAllVideos() {
	const authStore = get(auth);
	const backend = createActor(canisterId as string, {
		agentOptions: { identity: authStore?.identity }
	});
	return await backend.getAllVideos();
}

export async function listMyVideos() {
	const authStore = get(auth);
	const backend = createActor(canisterId as string, {
		agentOptions: { identity: authStore?.identity }
	});
	return await backend.getMyVideos();
}

export async function listReportedVideos() {
	const authStore = get(auth);
	const backend = createActor(canisterId as string, {
		agentOptions: { identity: authStore?.identity }
	});
	return await backend.getReportedVideos();
}

export async function listReportedVideosDetails() {
	const authStore = get(auth);
	const backend = createActor(canisterId as string, {
		agentOptions: { identity: authStore?.identity }
	});
	return await backend.getReportedVideosDetails();
}

export async function addVideo(gcsUri: string, name: string, description: string) {
	const authStore = get(auth);
	const backend = createActor(canisterId as string, {
		agentOptions: { identity: authStore?.identity }
	});
	return await backend.addVideo(gcsUri, name, description);
}

export async function upvote(upvote: boolean, gcsUri: string, uploadedBy: Principal) {
	const authStore = get(auth);
	const backend = createActor(canisterId as string, {
		agentOptions: { identity: authStore?.identity }
	});
	return await backend.upvote(upvote, gcsUri, uploadedBy);
}

export async function report(gcsUri: string, uploadedBy: Principal) {
	const authStore = get(auth);
	const backend = createActor(canisterId as string, {
		agentOptions: { identity: authStore?.identity }
	});
	return await backend.report(gcsUri, uploadedBy);
}

export async function getTokenBalance() {
	const authStore = get(auth);
	const backend = createActor(canisterId as string, {
		agentOptions: { identity: authStore?.identity }
	});
	return await backend.myTokens();
}

export async function vote(gcsUri: string, stake: Stake, tokens: number) {
	const authStore = get(auth);
	const backend = createActor(canisterId as string, {
		agentOptions: { identity: authStore?.identity }
	});
	return await backend.stake(gcsUri, stake, BigInt(tokens));
}

export async function updateStatus(gcsUri: string, status: UploadedVideoStatus) {
	const authStore = get(auth);
	const backend = createActor(canisterId as string, {
		agentOptions: { identity: authStore?.identity }
	});
	return await backend.updateVideoStatus({ gcsUri: gcsUri }, status);
}
