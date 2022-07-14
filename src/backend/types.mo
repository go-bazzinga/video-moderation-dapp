import Time "mo:base/Time";
import Principal "mo:base/Principal";
import TrieSet "mo:base/TrieSet";

module {
  public type GCSUri = Text;
  public type OperationName = Text;
  public type PrincipalSet<T> = TrieSet.Set<T>;
  public type Token = {
    balance: Nat;
  };

  public type UploadedVideoStatus = {
    #uploaded;
    #processing: {
      operationName: Text;
    };
    #completed;
    #explicit;
    #reported;
    #rejected;
  };

  public type Votes = {
      setVotes: PrincipalSet<Principal>;
      count: Nat;
  };

  public type UpdateStatusReq = {
    #gcsUri: GCSUri;
    #operation: OperationName;
  };

  public type UploadedVideoOperationStatus = {
    #initialized: Text;
    #notinitialized;
  };

  public type IndexInArray = {
    #valid: Nat;
    #invalid; 
  };

  public type UploadedVideo = {
    status: UploadedVideoStatus;
    gcsUri: Text;
    name: Text;
    description: Text;
    uploadedBy: Principal;
    operationName: UploadedVideoOperationStatus;
    uploadedAt: Time.Time;
    upvotes: Votes;
    reports: Votes;
  };

  public type UserProfile = {
    uploadedVideo: [UploadedVideo];
    token: Token;
  };

  public type UnprocessedVideo = {
    uploadedBy: Principal;
    gcsUri: GCSUri; 
    operationName: OperationName;
  };

  public type PotDetails = {
    userPrincipal: Principal;
    stakedTokens: Nat;
  };

  public type StakePot = {
    totalStakedTokens: Nat;
    stakes: [PotDetails]
  };

  public type Stake = {
    #approve;
    #reject;
  };

  public type ReportedVideo = {
    uploadedBy: Principal;
    gcsUri: GCSUri; 
    approvalPot: StakePot;
    rejectionPot: StakePot;
    votingStarted: Bool;
    votingStartedAt: Time.Time;
  };


  public type ResultPotDetails = {
    userPrincipal: Principal;
    stakedTokens: Nat;
    tokensLost: Nat;
    tokensWon: Nat;
  };

  public type ResultStakePot = {
    totalStakedTokens: Nat;
    details: [ResultPotDetails]
  };

  public type StakeResult = {
    #approved;
    #rejected;
  };

  public type StakeDistribution = {
    user: Principal;
    tokensDistributed: Int;
  };

  public type VotedVideo = {
    uploadedBy: Principal;
    gcsUri: GCSUri; 
    result: StakeResult;
    approvalPot: ResultStakePot;
    rejectionPot: ResultStakePot;
    votingClosedAt: Time.Time;
  };

  public type ResponseWithStatus = {
    success: Bool;
    message: Text;
  };
};
