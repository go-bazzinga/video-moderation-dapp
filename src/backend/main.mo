import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Types "./types";
import Utils "utils";
import TrieSet "mo:base/TrieSet";
import Time "mo:base/Time";
import Float "mo:base/Float";

actor Main {

  let IC = actor "aaaaa-aa" : actor {
    canister_status : { canister_id : Principal } -> 
      async {
        settings : { controllers : [Principal] }
      };
    };


  public func get_controllers() : async [Principal] {
    let principal = Principal.fromActor(Main);
    let status = await IC.canister_status({ canister_id = principal });
    return status.settings.controllers;
  };

  var listOfUsers: HashMap.HashMap<Principal, Types.UserProfile> = HashMap.HashMap(32, Principal.equal, Principal.hash);
  stable var listOfUnprocessedVideos: [Types.UnprocessedVideo] = [];
  stable var entries : [(Principal, Types.UserProfile)] = [];
  stable var listOfAdmins: [Principal] = [];
  stable var listOfReportedVideos: [Types.ReportedVideo] = [];
  stable var listOfVotedVideos: [Types.VotedVideo] = [];

  public shared ({caller}) func upsertUser(caller: Principal): async Types.UserProfile {
    let findUser = listOfUsers.get(caller);
    let newUser: Types.UserProfile = {uploadedVideo = []; token = { balance = 100 }};
    
    if(Utils.isAnonUser(caller)) {
      newUser;
    } else {
      switch(findUser) {
        case(?user) {
          user;
        };
        case null {
          listOfUsers.put(caller, newUser);
          newUser;
        }
      }
    }
  };
  
  public shared ({caller}) func addVideo(gcsUri:Text, name:Text, description:Text): async Types.ResponseWithStatus {
    if(Utils.isAnonUser(caller)) {
      {
        success = false;
        message = "You are not authtorized to upload video. Please login first";
      };
    } else {
      let user = await upsertUser(caller);
      let newVideo: [Types.UploadedVideo] = [{
        name = name;
        description = description;
        status = #uploaded;
        gcsUri = gcsUri;
        operationName = #notinitialized;
        upvotes = {
          setVotes = TrieSet.fromArray([], Principal.hash, Principal.equal);
          count = 0;
        };
        reports = {
          setVotes = TrieSet.fromArray([], Principal.hash, Principal.equal);
          count = 0;
        };
        uploadedBy = caller;
        uploadedAt = Time.now();
      }];
      
      listOfUsers.put(caller, {
        uploadedVideo = Utils.appendArr(user.uploadedVideo, newVideo);
        token= user.token;
      });

      listOfUnprocessedVideos := Utils.appendArr(listOfUnprocessedVideos,
      [
        {
          uploadedBy = caller; 
          gcsUri = gcsUri; 
          operationName = "";
        }
      ]);

      {
        success = true;
        message = "Successfully added video for processing";
      }; 
    }
  };

  public shared ({caller}) func updateVideoStatus(data: Types.UpdateStatusReq, status: Types.UploadedVideoStatus): async () {
    if(not(Utils.isAnonUser(caller))) {
      let findUserId = Utils.getCaller(data, listOfUnprocessedVideos);
      switch(findUserId) {
        case(?userId) {
          let findUserProfile = listOfUsers.get(userId);
          switch(findUserProfile) {
            case(?userProfile) {
                let findIndex = Utils.getIndexByField(data, userProfile.uploadedVideo);
                switch(findIndex) {
                  case(#valid index) {
                    var uploadedVideos: [var Types.UploadedVideo]= Array.thaw(userProfile.uploadedVideo);
                    uploadedVideos[index] := Utils.updateUploadedVideoStatus(status, uploadedVideos[index]);
                    switch(status) {
                      case (#processing op) {
                        let opName: Text = op.operationName;
                        switch(data) {
                          case(#gcsUri uri) {
                            listOfUnprocessedVideos := Utils.updateOperationNameInUnprocessedVideosList(uri, opName, listOfUnprocessedVideos);
                          };
                          case _ {
                            // do nothing
                          }
                        };
                        uploadedVideos[index] := Utils.updateUploadedVideoOperationName(#initialized opName,uploadedVideos[index]);
                      };
                      case (#completed) {
                        let gcsUri = uploadedVideos[index].gcsUri;
                        listOfUnprocessedVideos := Array.filter(listOfUnprocessedVideos, func(video:Types.UnprocessedVideo):Bool {video.gcsUri != gcsUri});
                      };
                      case (#rejected) {
                        let gcsUri = uploadedVideos[index].gcsUri;
                        listOfUnprocessedVideos := Array.filter(listOfUnprocessedVideos, func(video:Types.UnprocessedVideo):Bool {video.gcsUri != gcsUri});
                      };
                      case _ {};
                    };
                    listOfUsers.put(userId, {
                      uploadedVideo = Array.freeze(uploadedVideos);
                      token = userProfile.token;
                    });
                    
                  };
                  case (#invalid) {
                   (); 
                  };
                }
            };
             case(null) {
               ()
            };
          };
        };
        case null {
          return ();
        };
      };
      
    } else {
      ();
    };
  };

  public shared ({caller}) func upvote(upvote:Bool, gcsUri:Types.GCSUri, uploadedBy: Principal): async Bool {
    if(Utils.isAnonUser(caller)) {
      return false;
    } else {
      let findUserProfile = listOfUsers.get(uploadedBy);
      switch(findUserProfile) {
        case(?userProfile) {
          let data: Types.UpdateStatusReq = #gcsUri gcsUri;
          let findIndex = Utils.getIndexByField(data, userProfile.uploadedVideo);
          switch(findIndex) {
            case(#valid index) {
              var uploadedVideos: [var Types.UploadedVideo]= Array.thaw(userProfile.uploadedVideo);
              var upvotesToUpdate = uploadedVideos[index].upvotes.setVotes;
              if(upvote) {
                upvotesToUpdate := TrieSet.put(upvotesToUpdate, caller, Principal.hash(caller), Principal.equal);
              } else {
                upvotesToUpdate := TrieSet.delete(upvotesToUpdate, caller, Principal.hash(caller), Principal.equal);
              };
              uploadedVideos[index] := Utils.updateUpvotesVideo(upvotesToUpdate, uploadedVideos[index]);
              listOfUsers.put(uploadedBy, {
                uploadedVideo = Array.freeze(uploadedVideos);
                token = userProfile.token;
              });
              true;
            };
            case (#invalid) {
              false;
            }
          };
        };
        case null {
          false;
        }
      };
    }
  };

  public shared ({caller}) func report(gcsUri:Types.GCSUri, uploadedBy: Principal): async Bool {
    if(Utils.isAnonUser(caller)) {
      return false;
    } else {
      let findUserProfile = listOfUsers.get(uploadedBy);
      switch(findUserProfile) {
        case(?userProfile) {
          let data: Types.UpdateStatusReq = #gcsUri gcsUri;
          let findIndex = Utils.getIndexByField(data, userProfile.uploadedVideo);
          switch(findIndex) {
            case(#valid index) {
              var uploadedVideos: [var Types.UploadedVideo]= Array.thaw(userProfile.uploadedVideo);
              var reports = uploadedVideos[index].reports.setVotes;
              reports := TrieSet.put(reports, caller, Principal.hash(caller), Principal.equal);
              uploadedVideos[index] := Utils.updateReportsVideo(reports, uploadedVideos[index]);
              
              // if upvotes < 10 and reports are more than 1, update status
              // if upvotes > 10 and reports are more than 30%, update status
              // if upvotes > 40 and reports are more than 20%, update status
              let reportsNum = TrieSet.size(reports);
              let upvotesNum = TrieSet.size(uploadedVideos[index].upvotes.setVotes);

              let reportVideo = ((upvotesNum < 10) and (reportsNum > 1)) or (upvotesNum > 10 and upvotesNum > 40 and Float.fromInt(reportsNum) > (Float.fromInt(upvotesNum)*0.30)) or (upvotesNum > 40 and Float.fromInt(reportsNum) > (Float.fromInt(upvotesNum)*0.20));
              if(reportVideo) {
                let reportedStatus: Types.UploadedVideoStatus = #reported (); 
                uploadedVideos[index] := Utils.updateUploadedVideoStatus(reportedStatus, uploadedVideos[index]);
                listOfReportedVideos := Utils.appendArr(listOfReportedVideos,
                [
                 {
                    uploadedBy = uploadedBy;
                    gcsUri =  gcsUri; 
                    approvalPot = {
                      totalStakedTokens = 0;
                      stakes = [];
                    };
                    rejectionPot = {
                      totalStakedTokens = 0;
                      stakes = [];
                    };
                    votingStarted = false;
                    votingStartedAt = Time.now();
                  }
                ]);

                // reset reports to 0
                reports := TrieSet.fromArray([], Principal.hash, Principal.equal);
                uploadedVideos[index] := Utils.updateReportsVideo(reports, uploadedVideos[index]);
              };
              listOfUsers.put(uploadedBy, {
                uploadedVideo = Array.freeze(uploadedVideos);
                token = userProfile.token;
              });
              true;
            };
            case (#invalid) {
              false;
            }
          };
        };
        case null {
          false;
        }
      };
    }
  };

  public shared ({caller}) func stake(gcsUri:Types.GCSUri, stake: Types.Stake, tokensAmount:Nat): async Types.ResponseWithStatus {
    if(Utils.isAnonUser(caller)) {
      return {
        success = false;
        message = "You need to log-in to stake";
      };
    } else {
      let findVideoIndex = Utils.getReportedVideoIndex(gcsUri, listOfReportedVideos);
      let findUserProfile = listOfUsers.get(caller);
      switch(findVideoIndex) {
        case(#valid index) {
          switch(findUserProfile) {
            case(?userProfile) {
              let token = userProfile.token;
              if(tokensAmount > token.balance) {
                return {
                  success = false;
                  message = "You do not have enough tokens to stake";
                };
              } else {
                listOfReportedVideos := Utils.updateReportedVideosWithStake(stake, tokensAmount, caller, index, listOfReportedVideos);

                let updatedUser: Types.UserProfile = {
                  uploadedVideo = userProfile.uploadedVideo;
                  token = {
                    balance = token.balance - tokensAmount;
                  };
                };
                listOfUsers.put(caller, updatedUser);
                return {
                  success = true;
                  message = "Staked tokens successfully";
                };
              }
            };
            case null {
              return {
                success = false;
                message = "Something went wrong. Err code 01";
              };
            };
          };
        };
        case (#invalid) {
          return {
            success = false;
            message = "No such video found";
          };
        }
      };
    };
  };

  public query ({caller}) func getPendingVideos(): async [Types.UnprocessedVideo] {
    if(Utils.isAnonUser(caller)) {
      [];
    } else {
      return listOfUnprocessedVideos;
    };
  };

  public shared ({caller}) func getMyVideos(): async [Types.UploadedVideo] {
    if(Utils.isAnonUser(caller)) {
      [];
    } else {
      let user = await upsertUser(caller);
      user.uploadedVideo;
    }
  };

  public query func getAllVideos():async [Types.UploadedVideo] {
    let listBuffer : Buffer.Buffer<Types.UploadedVideo> = Buffer.Buffer(2);
    var listArr = Iter.toArray(listOfUsers.entries());
    for (user in listArr.vals()) {
      for (video in user.1.uploadedVideo.vals()) {
        if(video.status == #completed) {
          listBuffer.add(video);
        };
      };
    };
    return listBuffer.toArray();
  };

  public query func getReportedVideos(): async [Types.ReportedVideo] {
    listOfReportedVideos;
  };

  public query func getReportedVideosDetails(): async [Types.UploadedVideo] {
    let listBuffer : Buffer.Buffer<Types.UploadedVideo> = Buffer.Buffer(2);
    var listArr = Iter.toArray(listOfUsers.entries());
    for (user in listArr.vals()) {
      for (video in user.1.uploadedVideo.vals()) {
        if(video.status == #reported) {
          listBuffer.add(video);
        };
      };
    };
    return listBuffer.toArray();
  };

  public query ({caller}) func myTokens() : async Nat {
    if(Utils.isAnonUser(caller)) {
      0;
    } else {
      let findUser = listOfUsers.get(caller);
      switch(findUser) {
        case(?userProfile) {
          userProfile.token.balance;
        };
        case null {
          0;
        }
      };
    }
  };

  public query ({caller}) func whoami() : async Principal {
    return caller;
  };

  system func heartbeat() : async () {
    var i = 0;
    let length = listOfReportedVideos.size();
    while(i < length) {  
      if(listOfReportedVideos[i].votingStarted) {
        let oneHourNs = 2 * 60 *1_000_000_000;
        let time = listOfReportedVideos[i].votingStartedAt + oneHourNs;
        let now = Time.now();
        if(now > time) {
          //calculate result
          let isResultApproved = listOfReportedVideos[i].approvalPot.stakes.size() > listOfReportedVideos[i].rejectionPot.stakes.size();

          // get updated list of users with updated token balances and approved/rejected video
          listOfUsers := Utils.distributeTokensAndUpdateVideo(isResultApproved, listOfReportedVideos[i], listOfUsers);

          // save result
          listOfVotedVideos := Utils.appendArr(listOfVotedVideos, [Utils.generateResultVotedVideo(isResultApproved, listOfReportedVideos[i])]);

          // remove video from moderation queue
          listOfReportedVideos := Array.filter(listOfReportedVideos, func(video:Types.ReportedVideo):Bool {video.gcsUri != listOfReportedVideos[i].gcsUri});

          return ();
        };
      };
      i := i+1; 
    };
    return ();
  };

  system func preupgrade() {
    entries := Iter.toArray(listOfUsers.entries());
  };

  system func postupgrade() {
    listOfUsers := HashMap.fromIter<Principal, Types.UserProfile>(entries.vals(), 1, Principal.equal, Principal.hash);
    entries := [];
  };
  
};
