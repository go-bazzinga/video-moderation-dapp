import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export type AssocList = [] | [[[Key, null], List]];
export interface Branch { 'left' : Trie, 'size' : bigint, 'right' : Trie }
export type GCSUri = string;
export type Hash = number;
export interface Key { 'key' : Principal, 'hash' : Hash }
export interface Leaf { 'size' : bigint, 'keyvals' : AssocList }
export type List = [] | [[[Key, null], List]];
export type OperationName = string;
export interface PotDetails {
  'stakedTokens' : bigint,
  'userPrincipal' : Principal,
}
export type PrincipalSet = { 'branch' : Branch } |
  { 'leaf' : Leaf } |
  { 'empty' : null };
export interface ReportedVideo {
  'approvalPot' : StakePot,
  'votingStartedAt' : Time,
  'rejectionPot' : StakePot,
  'gcsUri' : GCSUri,
  'votingStarted' : boolean,
  'uploadedBy' : Principal,
}
export interface ResponseWithStatus { 'message' : string, 'success' : boolean }
export type Stake = { 'reject' : null } |
  { 'approve' : null };
export interface StakePot {
  'stakes' : Array<PotDetails>,
  'totalStakedTokens' : bigint,
}
export type Time = bigint;
export interface Token { 'balance' : bigint }
export type Trie = { 'branch' : Branch } |
  { 'leaf' : Leaf } |
  { 'empty' : null };
export interface UnprocessedVideo {
  'operationName' : OperationName,
  'gcsUri' : GCSUri,
  'uploadedBy' : Principal,
}
export type UpdateStatusReq = { 'gcsUri' : GCSUri } |
  { 'operation' : OperationName };
export interface UploadedVideo {
  'upvotes' : Votes,
  'status' : UploadedVideoStatus,
  'name' : string,
  'operationName' : UploadedVideoOperationStatus,
  'description' : string,
  'gcsUri' : string,
  'reports' : Votes,
  'uploadedAt' : Time,
  'uploadedBy' : Principal,
}
export type UploadedVideoOperationStatus = { 'initialized' : string } |
  { 'notinitialized' : null };
export type UploadedVideoStatus = { 'explicit' : null } |
  { 'completed' : null } |
  { 'rejected' : null } |
  { 'uploaded' : null } |
  { 'processing' : { 'operationName' : string } } |
  { 'reported' : null };
export interface UserProfile {
  'token' : Token,
  'uploadedVideo' : Array<UploadedVideo>,
}
export interface Votes { 'setVotes' : PrincipalSet, 'count' : bigint }
export interface _SERVICE {
  'addVideo' : ActorMethod<[string, string, string], ResponseWithStatus>,
  'getAllVideos' : ActorMethod<[], Array<UploadedVideo>>,
  'getMyVideos' : ActorMethod<[], Array<UploadedVideo>>,
  'getPendingVideos' : ActorMethod<[], Array<UnprocessedVideo>>,
  'getReportedVideos' : ActorMethod<[], Array<ReportedVideo>>,
  'getReportedVideosDetails' : ActorMethod<[], Array<UploadedVideo>>,
  'get_controllers' : ActorMethod<[], Array<Principal>>,
  'myTokens' : ActorMethod<[], bigint>,
  'report' : ActorMethod<[GCSUri, Principal], boolean>,
  'stake' : ActorMethod<[GCSUri, Stake, bigint], ResponseWithStatus>,
  'updateVideoStatus' : ActorMethod<
    [UpdateStatusReq, UploadedVideoStatus],
    undefined,
  >,
  'upsertUser' : ActorMethod<[Principal], UserProfile>,
  'upvote' : ActorMethod<[boolean, GCSUri, Principal], boolean>,
  'whoami' : ActorMethod<[], Principal>,
}
