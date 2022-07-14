export const idlFactory = ({ IDL }) => {
	const Branch = IDL.Rec();
	const List = IDL.Rec();
	const ResponseWithStatus = IDL.Record({
		message: IDL.Text,
		success: IDL.Bool,
	});
	const Hash = IDL.Nat32;
	const Key = IDL.Record({ key: IDL.Principal, hash: Hash });
	List.fill(IDL.Opt(IDL.Tuple(IDL.Tuple(Key, IDL.Null), List)));
	const AssocList = IDL.Opt(IDL.Tuple(IDL.Tuple(Key, IDL.Null), List));
	const Leaf = IDL.Record({ size: IDL.Nat, keyvals: AssocList });
	const Trie = IDL.Variant({
		branch: Branch,
		leaf: Leaf,
		empty: IDL.Null,
	});
	Branch.fill(IDL.Record({ left: Trie, size: IDL.Nat, right: Trie }));
	const PrincipalSet = IDL.Variant({
		branch: Branch,
		leaf: Leaf,
		empty: IDL.Null,
	});
	const Votes = IDL.Record({ setVotes: PrincipalSet, count: IDL.Nat });
	const UploadedVideoStatus = IDL.Variant({
		explicit: IDL.Null,
		completed: IDL.Null,
		rejected: IDL.Null,
		uploaded: IDL.Null,
		processing: IDL.Record({ operationName: IDL.Text }),
		reported: IDL.Null,
	});
	const UploadedVideoOperationStatus = IDL.Variant({
		initialized: IDL.Text,
		notinitialized: IDL.Null,
	});
	const Time = IDL.Int;
	const UploadedVideo = IDL.Record({
		upvotes: Votes,
		status: UploadedVideoStatus,
		name: IDL.Text,
		operationName: UploadedVideoOperationStatus,
		description: IDL.Text,
		gcsUri: IDL.Text,
		reports: Votes,
		uploadedAt: Time,
		uploadedBy: IDL.Principal,
	});
	const OperationName = IDL.Text;
	const GCSUri = IDL.Text;
	const UnprocessedVideo = IDL.Record({
		operationName: OperationName,
		gcsUri: GCSUri,
		uploadedBy: IDL.Principal,
	});
	const PotDetails = IDL.Record({
		stakedTokens: IDL.Nat,
		userPrincipal: IDL.Principal,
	});
	const StakePot = IDL.Record({
		stakes: IDL.Vec(PotDetails),
		totalStakedTokens: IDL.Nat,
	});
	const ReportedVideo = IDL.Record({
		approvalPot: StakePot,
		votingStartedAt: Time,
		rejectionPot: StakePot,
		gcsUri: GCSUri,
		votingStarted: IDL.Bool,
		uploadedBy: IDL.Principal,
	});
	const Stake = IDL.Variant({ reject: IDL.Null, approve: IDL.Null });
	const UpdateStatusReq = IDL.Variant({
		gcsUri: GCSUri,
		operation: OperationName,
	});
	const Token = IDL.Record({ balance: IDL.Nat });
	const UserProfile = IDL.Record({
		token: Token,
		uploadedVideo: IDL.Vec(UploadedVideo),
	});
	return IDL.Service({
		addVideo: IDL.Func([IDL.Text, IDL.Text, IDL.Text], [ResponseWithStatus], []),
		getAllVideos: IDL.Func([], [IDL.Vec(UploadedVideo)], ["query"]),
		getMyVideos: IDL.Func([], [IDL.Vec(UploadedVideo)], []),
		getPendingVideos: IDL.Func([], [IDL.Vec(UnprocessedVideo)], ["query"]),
		getReportedVideos: IDL.Func([], [IDL.Vec(ReportedVideo)], ["query"]),
		getReportedVideosDetails: IDL.Func([], [IDL.Vec(UploadedVideo)], ["query"]),
		get_controllers: IDL.Func([], [IDL.Vec(IDL.Principal)], []),
		myTokens: IDL.Func([], [IDL.Nat], ["query"]),
		report: IDL.Func([GCSUri, IDL.Principal], [IDL.Bool], []),
		stake: IDL.Func([GCSUri, Stake, IDL.Nat], [ResponseWithStatus], []),
		updateVideoStatus: IDL.Func([UpdateStatusReq, UploadedVideoStatus], [], []),
		upsertUser: IDL.Func([IDL.Principal], [UserProfile], []),
		upvote: IDL.Func([IDL.Bool, GCSUri, IDL.Principal], [IDL.Bool], []),
		whoami: IDL.Func([], [IDL.Principal], ["query"]),
	});
};
export const init = ({ IDL }) => {
	return [];
};
