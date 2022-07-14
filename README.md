# video-moderation-dapp

Built for Dfinity Supernova Hackathon.
Finalist in Social-Fi category.

# Demo

-   Frontend: [https://itl5d-oyaaa-aaaan-qahra-cai.ic0.app/](https://itl5d-oyaaa-aaaan-qahra-cai.ic0.app/)

-   Backend Candid UI: [https://a4gq6-oaaaa-aaaab-qaa4q-cai.raw.ic0.app/?id=i2iw7-yqaaa-aaaan-qahqq-cai](https://a4gq6-oaaaa-aaaab-qaa4q-cai.raw.ic0.app/?id=i2iw7-yqaaa-aaaan-qahqq-cai)

# How to setup:

-   Run `npm i` to install dependencies

-   Backend:

    -   Install [dfx SDK](https://internetcomputer.org/docs/current/developer-docs/build/install-upgrade-remove/)
    -   Run `dfx start`

-   Frontend:

    -   Rename `.env.sample` to `.env` and update the variables inside
    -   Update `src/frontend/lib/helpers/firebase.ts` with firebase project config

-   Functions:
    -   Install firebase-cli
    -   Run firebase init to generate `.firebaserc` in the root
    -   Update `src/functions/src/index.ts:L32` with correct backend canister Id.
    -   Run firebase deploy functions to deploy functions

# Architecture

![](architecture.png)

# Voting mechanism (example scenario):

-   A reported video gets 3 approval votes with following weight/tokens:

    -   User 1: 10 Tokens
    -   User 2: 20 Tokens
    -   User 3: 10 Tokens
    -   Total: 40 Tokens

-   Same video gets 2 rejection votes with following tokens:

    -   User 5: 30 Tokens
    -   User 6: 30 Tokens
    -   Total: 60 Tokens

-   Voting is caculated purely on the basis of votes, so in this example 3 approval votes > 2 approval votes

-   When the voting is concluded, the tokens will be distributed amongst winning users like so:
    -   Total Tokens = 100 Tokens
    -   User 1 will get 25 tokens (10/40\*100)
    -   User 2 will get 50 tokens (20/40\*100)
    -   User 3 will get 25 tokens (10/40\*100)
