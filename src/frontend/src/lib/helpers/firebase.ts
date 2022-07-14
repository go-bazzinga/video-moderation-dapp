import type { FirebaseApp } from 'firebase/app';
import { initializeApp } from 'firebase/app';
import { getDownloadURL, getStorage, ref, uploadBytes } from 'firebase/storage';

interface UploadResponseSuccess {
	status: 'success';
	gcsUri: string;
	downloadUrl: string;
}

interface UploadResponseError {
	status: 'error';
	error: string;
}

type UploadResponse = UploadResponseError | UploadResponseSuccess;

let app: FirebaseApp;

const config = {
	apiKey: 'xxxxxxxxxxxxxxx',
	authDomain: 'xxxxxxxxxxxx',
	projectId: 'xxxxxxxxxxxxx',
	storageBucket: 'xxxxxxxxxxxx',
	messagingSenderId: 'xxxxxxxxxxxxxxx',
	appId: 'xxxxxxxxxxxxxxx'
};

const gcsBucket = import.meta.env.VITE_GCS_BUCKET_NAME;

function getFirebaseApp(): FirebaseApp {
	if (!app) {
		app = initializeApp(config);
		return app;
	} else {
		return app;
	}
}

export async function analyzeText(text: string) {
	const result = await fetch(`${import.meta.env.VITE_FUNCTIONS_HOST}/analyzeText`, {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json'
		},
		body: JSON.stringify({ text })
	});
	return await result.json();
}

export async function uploadToBucket(file: File): Promise<UploadResponse> {
	try {
		const fileExt = file.name.split('.').pop();
		const fileName = Date.now().toString() + '.' + fileExt;
		const storage = getStorage(getFirebaseApp(), gcsBucket);
		const storageRef = ref(storage, fileName);

		await uploadBytes(storageRef, file);
		const gcsUri = gcsBucket + '/' + fileName;
		const pathReference = ref(storage, gcsUri);
		const downloadUrl = await getDownloadURL(pathReference);
		return { status: 'success', gcsUri, downloadUrl };
	} catch (e) {
		return { status: 'error', error: JSON.stringify(e) };
	}
}

export async function generateSignedUrl(gcsUri: string): Promise<string> {
	const storage = getStorage(getFirebaseApp(), gcsBucket);
	const pathReference = ref(storage, gcsUri);
	return await getDownloadURL(pathReference);
}
