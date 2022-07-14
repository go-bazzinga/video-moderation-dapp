import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as videoIntelligence from "@google-cloud/video-intelligence";
import * as language from "@google-cloud/language";
import { idlFactory } from "./declarations/backend/backend.did";
import { _SERVICE } from "./declarations/backend/backend.did.d";
import { createActor } from "./actor";
import { Ed25519KeyIdentity } from "@dfinity/identity";
import { Identity } from "@dfinity/agent";
import * as cors from "cors";
import "isomorphic-fetch";

admin.initializeApp();

exports.requestAIToProcessVideo = functions.storage
	.bucket("moderation-dapp")
	.object()
	.onFinalize(async (object) => {
		const client = new videoIntelligence.VideoIntelligenceServiceClient();

		if (object.name && object.bucket) {
			const gcsUri = `gs://${object.bucket}/${object.name}`;

			try {
				const [operation] = await client.annotateVideo({
					inputUri: gcsUri,
					features: [3], //EXPLICIT_CONTENT_DETECTION
				});

				const key: Identity = Ed25519KeyIdentity.generate();
				// This is hardcoded. This should be imported from env
				const backend = createActor<_SERVICE>("i2iw7-yqaaa-aaaan-qahqq-cai", idlFactory, { identity: key });

				if (operation.name) {
					await backend.updateVideoStatus(
						{ gcsUri: gcsUri },
						{
							processing: {
								operationName: operation.name,
							},
						}
					);
				}

				return null;
			} catch (e) {
				console.error("Error:", JSON.stringify(e), "Uploaded object:", JSON.stringify(object.name));
				return null;
			}
		} else {
			console.warn("No uploaded file");
			return null;
		}
	});

exports.analyzeText = functions.https.onRequest(async (req, res) => {
	return cors({ origin: true })(req, res, async () => {
		if (req.body.text) {
			const client = new language.LanguageServiceClient();

			try {
				const [result] = await client.analyzeSentiment({
					document: {
						content: req.body.text,
						type: "PLAIN_TEXT",
					},
				});

				let pass = result.documentSentiment?.score && result.documentSentiment?.score > -0.3;

				res.status(200).send({ pass });
			} catch (e) {
				console.error("Error:", JSON.stringify(e), "Incoming text:", req.body.text);
				res.status(500).send({ error: "Oh no something went wrong!" });
			}
		} else {
			res.status(400).send({ error: "No text found" });
		}
	});
});

exports.scheduledFunction = functions.pubsub.schedule("every 1 minutes").onRun(async (ctx) => {
	// fetch all the isProcessing videos from the motoko backend

	const key: Identity = Ed25519KeyIdentity.generate();
	const backend = createActor<_SERVICE>("i2iw7-yqaaa-aaaan-qahqq-cai", idlFactory, { identity: key });
	const pendingRes = await backend.getPendingVideos();
	const pendingList = pendingRes.filter((o) => o.operationName);

	const client = new videoIntelligence.VideoIntelligenceServiceClient();
	const operationResults = await Promise.all(
		pendingList.map(async (operation) => client.checkAnnotateVideoProgress(operation.operationName))
	);

	operationResults.forEach(async (operationResult: any) => {
		if (operationResult.done) {
			const frames = operationResult?.result?.annotationResults[0]?.explicitAnnotation?.frames;
			if (frames) {
				const isLikelyExplicit = frames.filter((o) => o.pornographyLikelihood === "VERY_LIKELY").length;
				await backend.updateVideoStatus(
					{ operation: operationResult.name },
					isLikelyExplicit
						? {
								explicit: null,
						  }
						: {
								completed: null,
						  }
				);
			}
		}
	});
	return null;
});
