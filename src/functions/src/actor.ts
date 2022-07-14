import { Actor, ActorSubclass, HttpAgent, HttpAgentOptions } from "@dfinity/agent";
import { IDL } from "@dfinity/candid";
import { Principal } from "@dfinity/principal";
import fetch from "node-fetch";

export function createActor<T>(
	canisterId: string | Principal,
	idlFactory: IDL.InterfaceFactory,
	options: HttpAgentOptions
): ActorSubclass<T> {
	const agent = new HttpAgent({
		fetch: fetch,
		host: "https://ic0.app",
		...options,
	});

	return Actor.createActor(idlFactory, {
		agent,
		canisterId,
	});
}
