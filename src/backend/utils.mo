import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Types "./types";
import Debug "mo:base/Debug";
import TrieSet "mo:base/TrieSet";
import Time "mo:base/Time";
import HashMap "mo:base/HashMap";
import Float "mo:base/Float";
import Int "mo:base/Int";

module {
  public func isAnonUser(caller:Principal): Bool {
    return Principal.toText(caller) == "2vxsx-fae"
  };

  public func appendArr<A>(arr1 : [A], arr2: [A]) : [A] {
    let bufferArr : Buffer.Buffer<A> = Buffer.Buffer(arr1.size() + arr2.size());
    for (x in arr1.vals()) {
        bufferArr.add(x);
    };
    for (x in arr2.vals()) {
        bufferArr.add(x);
    };
    bufferArr.toArray();
  };

  public func isAdmin(caller:Principal):Bool {
    return false
  };

  public func getCaller<A>(data: Types.UpdateStatusReq, listOfUnprocessedVideos:[Types.UnprocessedVideo]) : ?Principal {
     switch(data) {
        case (#gcsUri uri) {
          for(x in listOfUnprocessedVideos.vals()) {
            if(x.gcsUri == uri) {
              return ?x.uploadedBy;
            };
          }
        };
        case (#operation operationName) {
          for(x in listOfUnprocessedVideos.vals()) {
            if(x.operationName == operationName) {
              return ?x.uploadedBy;
            };
          };
        };
     };
    return null;
  };

  public func getReportedVideoIndex<A>(gcsUri: Types.GCSUri, reportedVideos:[Types.ReportedVideo]) : Types.IndexInArray {
    var count = 0;
    let length = reportedVideos.size();
    while(count < length) {  
      if(reportedVideos[count].gcsUri == gcsUri) {
        return #valid count;
      };
    count := count+1; 
    };
    return #invalid;
  };

  func getStakeDistribution(approvalPot:Types.StakePot, rejectionPot: Types.StakePot):[Types.StakeDistribution] {
    var stakeDistribution: [Types.StakeDistribution] = [];
    let totalStakedTokens = approvalPot.stakes.size() + rejectionPot.stakes.size(); 
    let totalApprovalTokens = approvalPot.stakes.size();
    let totalRejectionTokens = rejectionPot.stakes.size();
    let isResultApproved = approvalPot.stakes.size() > rejectionPot.stakes.size();
    if(isResultApproved) {
      for(stake in approvalPot.stakes.vals()) {
        let tokensDistributed = Float.floor((Float.fromInt(stake.stakedTokens)*Float.fromInt(totalStakedTokens))/Float.fromInt(totalApprovalTokens));
        stakeDistribution := appendArr(stakeDistribution, [{
          user = stake.userPrincipal;
          tokensDistributed = Float.toInt(tokensDistributed);
        }])
      }; 
    } else {
      for(stake in rejectionPot.stakes.vals()) {
        let tokensDistributed = Float.floor((Float.fromInt(stake.stakedTokens)*Float.fromInt(totalStakedTokens))/Float.fromInt(totalRejectionTokens));
        stakeDistribution := appendArr(stakeDistribution, [{
          user = stake.userPrincipal;
          tokensDistributed = Float.toInt(tokensDistributed);
        }])
      }; 
    };
    stakeDistribution;
  };

  public func distributeTokensAndUpdateVideo(isResultApproved: Bool, reportedVideo: Types.ReportedVideo, listOfUsers:HashMap.HashMap<Principal, Types.UserProfile>):HashMap.HashMap<Principal, Types.UserProfile> {

    // Distribute tokens
    let stakeDistribution = getStakeDistribution(reportedVideo.approvalPot, reportedVideo.rejectionPot);
    for(stakeDetails in stakeDistribution.vals()) {
      let findUser = listOfUsers.get(stakeDetails.user);
      switch(findUser) {
        case(?userProfile) {
          listOfUsers.put(stakeDetails.user, {
            uploadedVideo = userProfile.uploadedVideo;
            token = {
              balance = userProfile.token.balance + Int.abs(stakeDetails.tokensDistributed);
            }
          });   
        };
        case null {
          // do nothing
        };
      };   
    };

    // Update reported video status
    let findUser = listOfUsers.get(reportedVideo.uploadedBy);
    switch(findUser) {
      case(?userProfile) {
        let findIndex = getIndexByField(#gcsUri (reportedVideo.gcsUri), userProfile.uploadedVideo);
        switch(findIndex) {
          case(#valid index) {
            var uploadedVideos: [var Types.UploadedVideo] = Array.thaw(userProfile.uploadedVideo);
            let newStatus: Types.UploadedVideoStatus = if(isResultApproved) {#completed} else {#rejected};
            uploadedVideos[index] := updateUploadedVideoStatus(newStatus, uploadedVideos[index]);
            listOfUsers.put(reportedVideo.uploadedBy, {
              uploadedVideo = Array.freeze(uploadedVideos);
              token = userProfile.token;
            });
          };
          case(#invalid) {
            // do nothing
          };
        };   
      };
      case null {
        // do nothing
      };
    };  
    listOfUsers;
  };

  func generateApprovalResultPotDetails(approvalPot:Types.StakePot, rejectionPot: Types.StakePot):Types.ResultStakePot {
    var potDetails: [Types.ResultPotDetails] = [];
    let totalStakedTokens = approvalPot.stakes.size() + rejectionPot.stakes.size(); 
    let totalApprovalTokens = approvalPot.stakes.size();
    let totalRejectionTokens = rejectionPot.stakes.size();
    let isResultApproved = approvalPot.stakes.size() > rejectionPot.stakes.size();
    for(stake in approvalPot.stakes.vals()) {
      potDetails := appendArr(potDetails, [{
        userPrincipal = stake.userPrincipal;
        stakedTokens = stake.stakedTokens;
        tokensLost = if(isResultApproved) {0} else {stake.stakedTokens;};
        tokensWon = if(isResultApproved) {((stake.stakedTokens*totalStakedTokens)/totalApprovalTokens);} else {0};
        tokensDistributed = (stake.stakedTokens*totalStakedTokens)/totalApprovalTokens;
      }])
    }; 

    return {
      totalStakedTokens = totalStakedTokens;
      details = potDetails;
    }
  };

  func generateRejectionResultPotDetails(approvalPot:Types.StakePot, rejectionPot: Types.StakePot):Types.ResultStakePot {
    var potDetails: [Types.ResultPotDetails] = [];
    let totalStakedTokens = approvalPot.stakes.size() + rejectionPot.stakes.size(); 
    let totalApprovalTokens = approvalPot.stakes.size();
    let totalRejectionTokens = rejectionPot.stakes.size();
    let isResultRejected = rejectionPot.stakes.size() > approvalPot.stakes.size();
    for(stake in rejectionPot.stakes.vals()) {
      potDetails := appendArr(potDetails, [{
        userPrincipal = stake.userPrincipal;
        stakedTokens = stake.stakedTokens;
        tokensLost = if(isResultRejected) {0} else {stake.stakedTokens;};
        tokensWon = if(isResultRejected) {((stake.stakedTokens*totalStakedTokens)/totalRejectionTokens);} else {0};
        tokensDistributed = (stake.stakedTokens*totalStakedTokens)/totalRejectionTokens;
      }])
    }; 

    return {
      totalStakedTokens = totalStakedTokens;
      details = potDetails;
    }
  };

  // func generateResultStakePot(reportedVideo: Types.ReportedVideo):Types.ResultStakePot {
  //   let stakeDistribution = getStakeDistribution(reportedVideo.approvalPot, reportedVideo.rejectionPot);
  //   return {
  //     totalStakedTokens = reportedVideo.approvalPot.stakes.size() + reportedVideo.rejectionPot.stakes.size();
  //     details = 
  //   }
  // };

  public func generateResultVotedVideo(isResultApproved: Bool, reportedVideo:Types.ReportedVideo): Types.VotedVideo {
    let result: Types.StakeResult = if(isResultApproved) {#approved} else {#rejected};
    return {
      uploadedBy = reportedVideo.uploadedBy;
      gcsUri = reportedVideo.gcsUri; 
      result = result;
      approvalPot = generateApprovalResultPotDetails(reportedVideo.approvalPot, reportedVideo.rejectionPot);
      rejectionPot = generateRejectionResultPotDetails(reportedVideo.approvalPot, reportedVideo.rejectionPot);
      votingClosedAt = Time.now();
    };
  };

  public func updateReportedVideosWithStake(stake:Types.Stake, tokenAmount:Nat, stakedBy:Principal, index: Nat, list: [Types.ReportedVideo]): [Types.ReportedVideo]  {
    let votingStartedAt = if(list[index].votingStarted) {list[index].votingStartedAt} else {Time.now()};
    let appendPot:[Types.PotDetails] = [{userPrincipal = stakedBy; stakedTokens = tokenAmount}];
    var updatedList: [var Types.ReportedVideo]= Array.thaw(list);
    switch(stake) {
      case(#approve) {    
        let newPot:[Types.PotDetails] = appendArr(list[index].approvalPot.stakes, appendPot);
        let approvalPot = {
          totalStakedTokens = list[index].approvalPot.totalStakedTokens + tokenAmount;
          stakes = newPot;
        };
        updatedList[index] := {
          uploadedBy = list[index].uploadedBy;
          gcsUri = list[index].gcsUri; 
          approvalPot = approvalPot;
          rejectionPot = list[index].rejectionPot;
          votingStarted = true;
          votingStartedAt = votingStartedAt;
        };
        Array.freeze(updatedList);
      };
      case(#reject) {
        let newPot:[Types.PotDetails] = appendArr(list[index].rejectionPot.stakes, appendPot);
        let rejectionPot = {
          totalStakedTokens = list[index].rejectionPot.totalStakedTokens + tokenAmount;
          stakes = newPot;
        };
        updatedList[index] := {
          uploadedBy = list[index].uploadedBy;
          gcsUri = list[index].gcsUri; 
          approvalPot = list[index].approvalPot;
          rejectionPot = rejectionPot;
          votingStarted = true;
          votingStartedAt = votingStartedAt;
        };
        Array.freeze(updatedList);
      };
    };
  };

  public func getIndexByField(data: Types.UpdateStatusReq, uploadedVideos:[Types.UploadedVideo]): Types.IndexInArray {
    var count = 0;
    let length = uploadedVideos.size();
    while(count < length) {  
      switch(data) {
        case (#gcsUri uri) {
          if(uploadedVideos[count].gcsUri == uri) {
            return #valid count;
          }
        };
        case (#operation operationName) {
          switch(uploadedVideos[count].operationName) {
            case(#initialized name) {
              if(name == operationName) {
                return #valid count;
              };
            };
            case (#notinitialized) {
              //do nothing
            }
          };
          
        };
      };
      count := count+1; 
    };
    return #invalid;
  };

  public func getIndexByFieldUnprocessedVideos(gcsUri: Types.GCSUri, list:[Types.UnprocessedVideo]): Types.IndexInArray {
    var count = 0;
    let length = list.size();
    while(count < length) {  
      if(list[count].gcsUri == gcsUri) {
        return #valid(count);
      };
      count := count+1; 
    };
    return #invalid;
  };

  public func updateOperationNameInUnprocessedVideosList( gcsUri:Types.GCSUri, opName: Text, list:[Types.UnprocessedVideo]): [Types.UnprocessedVideo]  {
    let index = getIndexByFieldUnprocessedVideos(gcsUri, list);
    var updatedList: [var Types.UnprocessedVideo]= Array.thaw(list);

    switch(index) {
      case(#valid ind) {
        updatedList[ind] :=  {
          uploadedBy = list[ind].uploadedBy;
          gcsUri = list[ind].gcsUri; 
          operationName = opName;
        };
        Array.freeze(updatedList);
      };
      case (#invalid) {
        // (); 
        list;
      };
    };
  };

  public func updateUploadedVideoStatus(status:Types.UploadedVideoStatus, originalObject: Types.UploadedVideo): Types.UploadedVideo {    
    {
      status=status;
      name=originalObject.name;
      description=originalObject.description;
      gcsUri=originalObject.gcsUri;
      operationName=originalObject.operationName;
      uploadedBy=originalObject.uploadedBy;
      uploadedAt=originalObject.uploadedAt;
      upvotes=originalObject.upvotes;
      reports=originalObject.reports;
    }
  };

   public func updateUpvotesVideo(upvotes: Types.PrincipalSet<Principal>, originalObject: Types.UploadedVideo): Types.UploadedVideo {    
    {
      upvotes={
        setVotes = upvotes;
        count= TrieSet.size(upvotes);
      };
      name=originalObject.name;
      description=originalObject.description;
      gcsUri=originalObject.gcsUri;
      operationName=originalObject.operationName;
      status=originalObject.status;
      uploadedBy=originalObject.uploadedBy;
      uploadedAt=originalObject.uploadedAt;   
      reports=originalObject.reports;
    }
  };

  public func updateReportsVideo(reports: Types.PrincipalSet<Principal>, originalObject: Types.UploadedVideo): Types.UploadedVideo {    
    {
      reports={
        setVotes = reports;
        count = TrieSet.size(reports);
      };
      name=originalObject.name;
      description=originalObject.description;
      gcsUri=originalObject.gcsUri;
      operationName=originalObject.operationName;
      status=originalObject.status;
      uploadedBy=originalObject.uploadedBy;
      uploadedAt=originalObject.uploadedAt;   
      upvotes=originalObject.upvotes;
    }
  };

  public func updateUploadedVideoOperationName(operationName:Types.UploadedVideoOperationStatus, originalObject: Types.UploadedVideo): Types.UploadedVideo {    
    {
      operationName=operationName;
      name=originalObject.name;
      description=originalObject.description;
      status=originalObject.status;
      gcsUri=originalObject.gcsUri;
      uploadedAt=originalObject.uploadedAt;
      uploadedBy=originalObject.uploadedBy;
      upvotes=originalObject.upvotes;
      reports=originalObject.reports;
    }
  };
};
