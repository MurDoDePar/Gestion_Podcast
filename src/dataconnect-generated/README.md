# Generated TypeScript README
This README will guide you through the process of using the generated JavaScript SDK package for the connector `example`. It will also provide examples on how to use your generated SDK to call your Data Connect queries and mutations.

***NOTE:** This README is generated alongside the generated SDK. If you make changes to this file, they will be overwritten when the SDK is regenerated.*

# Table of Contents
- [**Overview**](#generated-javascript-readme)
- [**Accessing the connector**](#accessing-the-connector)
  - [*Connecting to the local Emulator*](#connecting-to-the-local-emulator)
- [**Queries**](#queries)
  - [*FindUserByGoogleId*](#finduserbygoogleid)
  - [*GetMySubscriptions*](#getmysubscriptions)
  - [*GetListenHistory*](#getlistenhistory)
  - [*GetRecommendations*](#getrecommendations)
- [**Mutations**](#mutations)
  - [*UpsertUser*](#upsertuser)
  - [*UpsertPodcast*](#upsertpodcast)
  - [*UpsertEpisode*](#upsertepisode)
  - [*SubscribeToPodcast*](#subscribetopodcast)
  - [*UpdateSubscriptionOrder*](#updatesubscriptionorder)
  - [*UnsubscribeFromPodcast*](#unsubscribefrompodcast)
  - [*UpdateListenHistory*](#updatelistenhistory)

# Accessing the connector
A connector is a collection of Queries and Mutations. One SDK is generated for each connector - this SDK is generated for the connector `example`. You can find more information about connectors in the [Data Connect documentation](https://firebase.google.com/docs/data-connect#how-does).

You can use this generated SDK by importing from the package `@dataconnect/generated` as shown below. Both CommonJS and ESM imports are supported.

You can also follow the instructions from the [Data Connect documentation](https://firebase.google.com/docs/data-connect/web-sdk#set-client).

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig } from '@dataconnect/generated';

const dataConnect = getDataConnect(connectorConfig);
```

## Connecting to the local Emulator
By default, the connector will connect to the production service.

To connect to the emulator, you can use the following code.
You can also follow the emulator instructions from the [Data Connect documentation](https://firebase.google.com/docs/data-connect/web-sdk#instrument-clients).

```typescript
import { connectDataConnectEmulator, getDataConnect } from 'firebase/data-connect';
import { connectorConfig } from '@dataconnect/generated';

const dataConnect = getDataConnect(connectorConfig);
connectDataConnectEmulator(dataConnect, 'localhost', 9399);
```

After it's initialized, you can call your Data Connect [queries](#queries) and [mutations](#mutations) from your generated SDK.

# Queries

There are two ways to execute a Data Connect Query using the generated Web SDK:
- Using a Query Reference function, which returns a `QueryRef`
  - The `QueryRef` can be used as an argument to `executeQuery()`, which will execute the Query and return a `QueryPromise`
- Using an action shortcut function, which returns a `QueryPromise`
  - Calling the action shortcut function will execute the Query and return a `QueryPromise`

The following is true for both the action shortcut function and the `QueryRef` function:
- The `QueryPromise` returned will resolve to the result of the Query once it has finished executing
- If the Query accepts arguments, both the action shortcut function and the `QueryRef` function accept a single argument: an object that contains all the required variables (and the optional variables) for the Query
- Both functions can be called with or without passing in a `DataConnect` instance as an argument. If no `DataConnect` argument is passed in, then the generated SDK will call `getDataConnect(connectorConfig)` behind the scenes for you.

Below are examples of how to use the `example` connector's generated functions to execute each query. You can also follow the examples from the [Data Connect documentation](https://firebase.google.com/docs/data-connect/web-sdk#using-queries).

## FindUserByGoogleId
You can execute the `FindUserByGoogleId` query using the following action shortcut function, or by calling `executeQuery()` after calling the following `QueryRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
findUserByGoogleId(vars: FindUserByGoogleIdVariables, options?: ExecuteQueryOptions): QueryPromise<FindUserByGoogleIdData, FindUserByGoogleIdVariables>;

interface FindUserByGoogleIdRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: FindUserByGoogleIdVariables): QueryRef<FindUserByGoogleIdData, FindUserByGoogleIdVariables>;
}
export const findUserByGoogleIdRef: FindUserByGoogleIdRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `QueryRef` function.
```typescript
findUserByGoogleId(dc: DataConnect, vars: FindUserByGoogleIdVariables, options?: ExecuteQueryOptions): QueryPromise<FindUserByGoogleIdData, FindUserByGoogleIdVariables>;

interface FindUserByGoogleIdRef {
  ...
  (dc: DataConnect, vars: FindUserByGoogleIdVariables): QueryRef<FindUserByGoogleIdData, FindUserByGoogleIdVariables>;
}
export const findUserByGoogleIdRef: FindUserByGoogleIdRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the findUserByGoogleIdRef:
```typescript
const name = findUserByGoogleIdRef.operationName;
console.log(name);
```

### Variables
The `FindUserByGoogleId` query requires an argument of type `FindUserByGoogleIdVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface FindUserByGoogleIdVariables {
  googleId: string;
}
```
### Return Type
Recall that executing the `FindUserByGoogleId` query returns a `QueryPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `FindUserByGoogleIdData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface FindUserByGoogleIdData {
  users: ({
    id: UUIDString;
    googleId: string;
    displayName: string;
    email?: string | null;
  } & User_Key)[];
}
```
### Using `FindUserByGoogleId`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, findUserByGoogleId, FindUserByGoogleIdVariables } from '@dataconnect/generated';

// The `FindUserByGoogleId` query requires an argument of type `FindUserByGoogleIdVariables`:
const findUserByGoogleIdVars: FindUserByGoogleIdVariables = {
  googleId: ..., 
};

// Call the `findUserByGoogleId()` function to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await findUserByGoogleId(findUserByGoogleIdVars);
// Variables can be defined inline as well.
const { data } = await findUserByGoogleId({ googleId: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await findUserByGoogleId(dataConnect, findUserByGoogleIdVars);

console.log(data.users);

// Or, you can use the `Promise` API.
findUserByGoogleId(findUserByGoogleIdVars).then((response) => {
  const data = response.data;
  console.log(data.users);
});
```

### Using `FindUserByGoogleId`'s `QueryRef` function

```typescript
import { getDataConnect, executeQuery } from 'firebase/data-connect';
import { connectorConfig, findUserByGoogleIdRef, FindUserByGoogleIdVariables } from '@dataconnect/generated';

// The `FindUserByGoogleId` query requires an argument of type `FindUserByGoogleIdVariables`:
const findUserByGoogleIdVars: FindUserByGoogleIdVariables = {
  googleId: ..., 
};

// Call the `findUserByGoogleIdRef()` function to get a reference to the query.
const ref = findUserByGoogleIdRef(findUserByGoogleIdVars);
// Variables can be defined inline as well.
const ref = findUserByGoogleIdRef({ googleId: ..., });

// You can also pass in a `DataConnect` instance to the `QueryRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = findUserByGoogleIdRef(dataConnect, findUserByGoogleIdVars);

// Call `executeQuery()` on the reference to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeQuery(ref);

console.log(data.users);

// Or, you can use the `Promise` API.
executeQuery(ref).then((response) => {
  const data = response.data;
  console.log(data.users);
});
```

## GetMySubscriptions
You can execute the `GetMySubscriptions` query using the following action shortcut function, or by calling `executeQuery()` after calling the following `QueryRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
getMySubscriptions(vars: GetMySubscriptionsVariables, options?: ExecuteQueryOptions): QueryPromise<GetMySubscriptionsData, GetMySubscriptionsVariables>;

interface GetMySubscriptionsRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: GetMySubscriptionsVariables): QueryRef<GetMySubscriptionsData, GetMySubscriptionsVariables>;
}
export const getMySubscriptionsRef: GetMySubscriptionsRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `QueryRef` function.
```typescript
getMySubscriptions(dc: DataConnect, vars: GetMySubscriptionsVariables, options?: ExecuteQueryOptions): QueryPromise<GetMySubscriptionsData, GetMySubscriptionsVariables>;

interface GetMySubscriptionsRef {
  ...
  (dc: DataConnect, vars: GetMySubscriptionsVariables): QueryRef<GetMySubscriptionsData, GetMySubscriptionsVariables>;
}
export const getMySubscriptionsRef: GetMySubscriptionsRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the getMySubscriptionsRef:
```typescript
const name = getMySubscriptionsRef.operationName;
console.log(name);
```

### Variables
The `GetMySubscriptions` query requires an argument of type `GetMySubscriptionsVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface GetMySubscriptionsVariables {
  userId: UUIDString;
}
```
### Return Type
Recall that executing the `GetMySubscriptions` query returns a `QueryPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `GetMySubscriptionsData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface GetMySubscriptionsData {
  subscriptionTypes: ({
    listOrder?: number | null;
    podcast: {
      id: UUIDString;
      title: string;
      feedUrl: string;
      imageUrl?: string | null;
      author?: string | null;
      categories?: string[] | null;
    } & Podcast_Key;
  })[];
}
```
### Using `GetMySubscriptions`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, getMySubscriptions, GetMySubscriptionsVariables } from '@dataconnect/generated';

// The `GetMySubscriptions` query requires an argument of type `GetMySubscriptionsVariables`:
const getMySubscriptionsVars: GetMySubscriptionsVariables = {
  userId: ..., 
};

// Call the `getMySubscriptions()` function to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await getMySubscriptions(getMySubscriptionsVars);
// Variables can be defined inline as well.
const { data } = await getMySubscriptions({ userId: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await getMySubscriptions(dataConnect, getMySubscriptionsVars);

console.log(data.subscriptionTypes);

// Or, you can use the `Promise` API.
getMySubscriptions(getMySubscriptionsVars).then((response) => {
  const data = response.data;
  console.log(data.subscriptionTypes);
});
```

### Using `GetMySubscriptions`'s `QueryRef` function

```typescript
import { getDataConnect, executeQuery } from 'firebase/data-connect';
import { connectorConfig, getMySubscriptionsRef, GetMySubscriptionsVariables } from '@dataconnect/generated';

// The `GetMySubscriptions` query requires an argument of type `GetMySubscriptionsVariables`:
const getMySubscriptionsVars: GetMySubscriptionsVariables = {
  userId: ..., 
};

// Call the `getMySubscriptionsRef()` function to get a reference to the query.
const ref = getMySubscriptionsRef(getMySubscriptionsVars);
// Variables can be defined inline as well.
const ref = getMySubscriptionsRef({ userId: ..., });

// You can also pass in a `DataConnect` instance to the `QueryRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = getMySubscriptionsRef(dataConnect, getMySubscriptionsVars);

// Call `executeQuery()` on the reference to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeQuery(ref);

console.log(data.subscriptionTypes);

// Or, you can use the `Promise` API.
executeQuery(ref).then((response) => {
  const data = response.data;
  console.log(data.subscriptionTypes);
});
```

## GetListenHistory
You can execute the `GetListenHistory` query using the following action shortcut function, or by calling `executeQuery()` after calling the following `QueryRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
getListenHistory(vars: GetListenHistoryVariables, options?: ExecuteQueryOptions): QueryPromise<GetListenHistoryData, GetListenHistoryVariables>;

interface GetListenHistoryRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: GetListenHistoryVariables): QueryRef<GetListenHistoryData, GetListenHistoryVariables>;
}
export const getListenHistoryRef: GetListenHistoryRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `QueryRef` function.
```typescript
getListenHistory(dc: DataConnect, vars: GetListenHistoryVariables, options?: ExecuteQueryOptions): QueryPromise<GetListenHistoryData, GetListenHistoryVariables>;

interface GetListenHistoryRef {
  ...
  (dc: DataConnect, vars: GetListenHistoryVariables): QueryRef<GetListenHistoryData, GetListenHistoryVariables>;
}
export const getListenHistoryRef: GetListenHistoryRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the getListenHistoryRef:
```typescript
const name = getListenHistoryRef.operationName;
console.log(name);
```

### Variables
The `GetListenHistory` query requires an argument of type `GetListenHistoryVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface GetListenHistoryVariables {
  userId: UUIDString;
}
```
### Return Type
Recall that executing the `GetListenHistory` query returns a `QueryPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `GetListenHistoryData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface GetListenHistoryData {
  listenHistories: ({
    episode: {
      id: UUIDString;
      audioUrl: string;
    } & Episode_Key;
      progressSeconds: Int64String;
      finishedListening?: boolean | null;
  })[];
}
```
### Using `GetListenHistory`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, getListenHistory, GetListenHistoryVariables } from '@dataconnect/generated';

// The `GetListenHistory` query requires an argument of type `GetListenHistoryVariables`:
const getListenHistoryVars: GetListenHistoryVariables = {
  userId: ..., 
};

// Call the `getListenHistory()` function to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await getListenHistory(getListenHistoryVars);
// Variables can be defined inline as well.
const { data } = await getListenHistory({ userId: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await getListenHistory(dataConnect, getListenHistoryVars);

console.log(data.listenHistories);

// Or, you can use the `Promise` API.
getListenHistory(getListenHistoryVars).then((response) => {
  const data = response.data;
  console.log(data.listenHistories);
});
```

### Using `GetListenHistory`'s `QueryRef` function

```typescript
import { getDataConnect, executeQuery } from 'firebase/data-connect';
import { connectorConfig, getListenHistoryRef, GetListenHistoryVariables } from '@dataconnect/generated';

// The `GetListenHistory` query requires an argument of type `GetListenHistoryVariables`:
const getListenHistoryVars: GetListenHistoryVariables = {
  userId: ..., 
};

// Call the `getListenHistoryRef()` function to get a reference to the query.
const ref = getListenHistoryRef(getListenHistoryVars);
// Variables can be defined inline as well.
const ref = getListenHistoryRef({ userId: ..., });

// You can also pass in a `DataConnect` instance to the `QueryRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = getListenHistoryRef(dataConnect, getListenHistoryVars);

// Call `executeQuery()` on the reference to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeQuery(ref);

console.log(data.listenHistories);

// Or, you can use the `Promise` API.
executeQuery(ref).then((response) => {
  const data = response.data;
  console.log(data.listenHistories);
});
```

## GetRecommendations
You can execute the `GetRecommendations` query using the following action shortcut function, or by calling `executeQuery()` after calling the following `QueryRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
getRecommendations(vars: GetRecommendationsVariables, options?: ExecuteQueryOptions): QueryPromise<GetRecommendationsData, GetRecommendationsVariables>;

interface GetRecommendationsRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: GetRecommendationsVariables): QueryRef<GetRecommendationsData, GetRecommendationsVariables>;
}
export const getRecommendationsRef: GetRecommendationsRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `QueryRef` function.
```typescript
getRecommendations(dc: DataConnect, vars: GetRecommendationsVariables, options?: ExecuteQueryOptions): QueryPromise<GetRecommendationsData, GetRecommendationsVariables>;

interface GetRecommendationsRef {
  ...
  (dc: DataConnect, vars: GetRecommendationsVariables): QueryRef<GetRecommendationsData, GetRecommendationsVariables>;
}
export const getRecommendationsRef: GetRecommendationsRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the getRecommendationsRef:
```typescript
const name = getRecommendationsRef.operationName;
console.log(name);
```

### Variables
The `GetRecommendations` query requires an argument of type `GetRecommendationsVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface GetRecommendationsVariables {
  podcastId: UUIDString;
}
```
### Return Type
Recall that executing the `GetRecommendations` query returns a `QueryPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `GetRecommendationsData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface GetRecommendationsData {
  subscriptionTypes: ({
    user: {
      subscriptionTypes_on_user: ({
        podcast: {
          id: UUIDString;
          title: string;
          imageUrl?: string | null;
          feedUrl: string;
          author?: string | null;
          categories?: string[] | null;
        } & Podcast_Key;
      })[];
    };
  })[];
}
```
### Using `GetRecommendations`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, getRecommendations, GetRecommendationsVariables } from '@dataconnect/generated';

// The `GetRecommendations` query requires an argument of type `GetRecommendationsVariables`:
const getRecommendationsVars: GetRecommendationsVariables = {
  podcastId: ..., 
};

// Call the `getRecommendations()` function to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await getRecommendations(getRecommendationsVars);
// Variables can be defined inline as well.
const { data } = await getRecommendations({ podcastId: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await getRecommendations(dataConnect, getRecommendationsVars);

console.log(data.subscriptionTypes);

// Or, you can use the `Promise` API.
getRecommendations(getRecommendationsVars).then((response) => {
  const data = response.data;
  console.log(data.subscriptionTypes);
});
```

### Using `GetRecommendations`'s `QueryRef` function

```typescript
import { getDataConnect, executeQuery } from 'firebase/data-connect';
import { connectorConfig, getRecommendationsRef, GetRecommendationsVariables } from '@dataconnect/generated';

// The `GetRecommendations` query requires an argument of type `GetRecommendationsVariables`:
const getRecommendationsVars: GetRecommendationsVariables = {
  podcastId: ..., 
};

// Call the `getRecommendationsRef()` function to get a reference to the query.
const ref = getRecommendationsRef(getRecommendationsVars);
// Variables can be defined inline as well.
const ref = getRecommendationsRef({ podcastId: ..., });

// You can also pass in a `DataConnect` instance to the `QueryRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = getRecommendationsRef(dataConnect, getRecommendationsVars);

// Call `executeQuery()` on the reference to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeQuery(ref);

console.log(data.subscriptionTypes);

// Or, you can use the `Promise` API.
executeQuery(ref).then((response) => {
  const data = response.data;
  console.log(data.subscriptionTypes);
});
```

# Mutations

There are two ways to execute a Data Connect Mutation using the generated Web SDK:
- Using a Mutation Reference function, which returns a `MutationRef`
  - The `MutationRef` can be used as an argument to `executeMutation()`, which will execute the Mutation and return a `MutationPromise`
- Using an action shortcut function, which returns a `MutationPromise`
  - Calling the action shortcut function will execute the Mutation and return a `MutationPromise`

The following is true for both the action shortcut function and the `MutationRef` function:
- The `MutationPromise` returned will resolve to the result of the Mutation once it has finished executing
- If the Mutation accepts arguments, both the action shortcut function and the `MutationRef` function accept a single argument: an object that contains all the required variables (and the optional variables) for the Mutation
- Both functions can be called with or without passing in a `DataConnect` instance as an argument. If no `DataConnect` argument is passed in, then the generated SDK will call `getDataConnect(connectorConfig)` behind the scenes for you.

Below are examples of how to use the `example` connector's generated functions to execute each mutation. You can also follow the examples from the [Data Connect documentation](https://firebase.google.com/docs/data-connect/web-sdk#using-mutations).

## UpsertUser
You can execute the `UpsertUser` mutation using the following action shortcut function, or by calling `executeMutation()` after calling the following `MutationRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
upsertUser(vars: UpsertUserVariables): MutationPromise<UpsertUserData, UpsertUserVariables>;

interface UpsertUserRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: UpsertUserVariables): MutationRef<UpsertUserData, UpsertUserVariables>;
}
export const upsertUserRef: UpsertUserRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `MutationRef` function.
```typescript
upsertUser(dc: DataConnect, vars: UpsertUserVariables): MutationPromise<UpsertUserData, UpsertUserVariables>;

interface UpsertUserRef {
  ...
  (dc: DataConnect, vars: UpsertUserVariables): MutationRef<UpsertUserData, UpsertUserVariables>;
}
export const upsertUserRef: UpsertUserRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the upsertUserRef:
```typescript
const name = upsertUserRef.operationName;
console.log(name);
```

### Variables
The `UpsertUser` mutation requires an argument of type `UpsertUserVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface UpsertUserVariables {
  id?: UUIDString | null;
  googleId: string;
  displayName: string;
  email?: string | null;
  photoUrl?: string | null;
  createdAt: TimestampString;
}
```
### Return Type
Recall that executing the `UpsertUser` mutation returns a `MutationPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `UpsertUserData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface UpsertUserData {
  user_upsert: User_Key;
}
```
### Using `UpsertUser`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, upsertUser, UpsertUserVariables } from '@dataconnect/generated';

// The `UpsertUser` mutation requires an argument of type `UpsertUserVariables`:
const upsertUserVars: UpsertUserVariables = {
  id: ..., // optional
  googleId: ..., 
  displayName: ..., 
  email: ..., // optional
  photoUrl: ..., // optional
  createdAt: ..., 
};

// Call the `upsertUser()` function to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await upsertUser(upsertUserVars);
// Variables can be defined inline as well.
const { data } = await upsertUser({ id: ..., googleId: ..., displayName: ..., email: ..., photoUrl: ..., createdAt: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await upsertUser(dataConnect, upsertUserVars);

console.log(data.user_upsert);

// Or, you can use the `Promise` API.
upsertUser(upsertUserVars).then((response) => {
  const data = response.data;
  console.log(data.user_upsert);
});
```

### Using `UpsertUser`'s `MutationRef` function

```typescript
import { getDataConnect, executeMutation } from 'firebase/data-connect';
import { connectorConfig, upsertUserRef, UpsertUserVariables } from '@dataconnect/generated';

// The `UpsertUser` mutation requires an argument of type `UpsertUserVariables`:
const upsertUserVars: UpsertUserVariables = {
  id: ..., // optional
  googleId: ..., 
  displayName: ..., 
  email: ..., // optional
  photoUrl: ..., // optional
  createdAt: ..., 
};

// Call the `upsertUserRef()` function to get a reference to the mutation.
const ref = upsertUserRef(upsertUserVars);
// Variables can be defined inline as well.
const ref = upsertUserRef({ id: ..., googleId: ..., displayName: ..., email: ..., photoUrl: ..., createdAt: ..., });

// You can also pass in a `DataConnect` instance to the `MutationRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = upsertUserRef(dataConnect, upsertUserVars);

// Call `executeMutation()` on the reference to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeMutation(ref);

console.log(data.user_upsert);

// Or, you can use the `Promise` API.
executeMutation(ref).then((response) => {
  const data = response.data;
  console.log(data.user_upsert);
});
```

## UpsertPodcast
You can execute the `UpsertPodcast` mutation using the following action shortcut function, or by calling `executeMutation()` after calling the following `MutationRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
upsertPodcast(vars: UpsertPodcastVariables): MutationPromise<UpsertPodcastData, UpsertPodcastVariables>;

interface UpsertPodcastRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: UpsertPodcastVariables): MutationRef<UpsertPodcastData, UpsertPodcastVariables>;
}
export const upsertPodcastRef: UpsertPodcastRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `MutationRef` function.
```typescript
upsertPodcast(dc: DataConnect, vars: UpsertPodcastVariables): MutationPromise<UpsertPodcastData, UpsertPodcastVariables>;

interface UpsertPodcastRef {
  ...
  (dc: DataConnect, vars: UpsertPodcastVariables): MutationRef<UpsertPodcastData, UpsertPodcastVariables>;
}
export const upsertPodcastRef: UpsertPodcastRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the upsertPodcastRef:
```typescript
const name = upsertPodcastRef.operationName;
console.log(name);
```

### Variables
The `UpsertPodcast` mutation requires an argument of type `UpsertPodcastVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface UpsertPodcastVariables {
  id?: UUIDString | null;
  title: string;
  feedUrl: string;
  description?: string | null;
  imageUrl?: string | null;
  author?: string | null;
  categories?: string[] | null;
  createdAt: TimestampString;
}
```
### Return Type
Recall that executing the `UpsertPodcast` mutation returns a `MutationPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `UpsertPodcastData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface UpsertPodcastData {
  podcast_upsert: Podcast_Key;
}
```
### Using `UpsertPodcast`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, upsertPodcast, UpsertPodcastVariables } from '@dataconnect/generated';

// The `UpsertPodcast` mutation requires an argument of type `UpsertPodcastVariables`:
const upsertPodcastVars: UpsertPodcastVariables = {
  id: ..., // optional
  title: ..., 
  feedUrl: ..., 
  description: ..., // optional
  imageUrl: ..., // optional
  author: ..., // optional
  categories: ..., // optional
  createdAt: ..., 
};

// Call the `upsertPodcast()` function to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await upsertPodcast(upsertPodcastVars);
// Variables can be defined inline as well.
const { data } = await upsertPodcast({ id: ..., title: ..., feedUrl: ..., description: ..., imageUrl: ..., author: ..., categories: ..., createdAt: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await upsertPodcast(dataConnect, upsertPodcastVars);

console.log(data.podcast_upsert);

// Or, you can use the `Promise` API.
upsertPodcast(upsertPodcastVars).then((response) => {
  const data = response.data;
  console.log(data.podcast_upsert);
});
```

### Using `UpsertPodcast`'s `MutationRef` function

```typescript
import { getDataConnect, executeMutation } from 'firebase/data-connect';
import { connectorConfig, upsertPodcastRef, UpsertPodcastVariables } from '@dataconnect/generated';

// The `UpsertPodcast` mutation requires an argument of type `UpsertPodcastVariables`:
const upsertPodcastVars: UpsertPodcastVariables = {
  id: ..., // optional
  title: ..., 
  feedUrl: ..., 
  description: ..., // optional
  imageUrl: ..., // optional
  author: ..., // optional
  categories: ..., // optional
  createdAt: ..., 
};

// Call the `upsertPodcastRef()` function to get a reference to the mutation.
const ref = upsertPodcastRef(upsertPodcastVars);
// Variables can be defined inline as well.
const ref = upsertPodcastRef({ id: ..., title: ..., feedUrl: ..., description: ..., imageUrl: ..., author: ..., categories: ..., createdAt: ..., });

// You can also pass in a `DataConnect` instance to the `MutationRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = upsertPodcastRef(dataConnect, upsertPodcastVars);

// Call `executeMutation()` on the reference to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeMutation(ref);

console.log(data.podcast_upsert);

// Or, you can use the `Promise` API.
executeMutation(ref).then((response) => {
  const data = response.data;
  console.log(data.podcast_upsert);
});
```

## UpsertEpisode
You can execute the `UpsertEpisode` mutation using the following action shortcut function, or by calling `executeMutation()` after calling the following `MutationRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
upsertEpisode(vars: UpsertEpisodeVariables): MutationPromise<UpsertEpisodeData, UpsertEpisodeVariables>;

interface UpsertEpisodeRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: UpsertEpisodeVariables): MutationRef<UpsertEpisodeData, UpsertEpisodeVariables>;
}
export const upsertEpisodeRef: UpsertEpisodeRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `MutationRef` function.
```typescript
upsertEpisode(dc: DataConnect, vars: UpsertEpisodeVariables): MutationPromise<UpsertEpisodeData, UpsertEpisodeVariables>;

interface UpsertEpisodeRef {
  ...
  (dc: DataConnect, vars: UpsertEpisodeVariables): MutationRef<UpsertEpisodeData, UpsertEpisodeVariables>;
}
export const upsertEpisodeRef: UpsertEpisodeRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the upsertEpisodeRef:
```typescript
const name = upsertEpisodeRef.operationName;
console.log(name);
```

### Variables
The `UpsertEpisode` mutation requires an argument of type `UpsertEpisodeVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface UpsertEpisodeVariables {
  id?: UUIDString | null;
  podcastId: UUIDString;
  title: string;
  audioUrl: string;
  duration: Int64String;
  description?: string | null;
  imageUrl?: string | null;
  publishedAt: TimestampString;
}
```
### Return Type
Recall that executing the `UpsertEpisode` mutation returns a `MutationPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `UpsertEpisodeData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface UpsertEpisodeData {
  episode_upsert: Episode_Key;
}
```
### Using `UpsertEpisode`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, upsertEpisode, UpsertEpisodeVariables } from '@dataconnect/generated';

// The `UpsertEpisode` mutation requires an argument of type `UpsertEpisodeVariables`:
const upsertEpisodeVars: UpsertEpisodeVariables = {
  id: ..., // optional
  podcastId: ..., 
  title: ..., 
  audioUrl: ..., 
  duration: ..., 
  description: ..., // optional
  imageUrl: ..., // optional
  publishedAt: ..., 
};

// Call the `upsertEpisode()` function to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await upsertEpisode(upsertEpisodeVars);
// Variables can be defined inline as well.
const { data } = await upsertEpisode({ id: ..., podcastId: ..., title: ..., audioUrl: ..., duration: ..., description: ..., imageUrl: ..., publishedAt: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await upsertEpisode(dataConnect, upsertEpisodeVars);

console.log(data.episode_upsert);

// Or, you can use the `Promise` API.
upsertEpisode(upsertEpisodeVars).then((response) => {
  const data = response.data;
  console.log(data.episode_upsert);
});
```

### Using `UpsertEpisode`'s `MutationRef` function

```typescript
import { getDataConnect, executeMutation } from 'firebase/data-connect';
import { connectorConfig, upsertEpisodeRef, UpsertEpisodeVariables } from '@dataconnect/generated';

// The `UpsertEpisode` mutation requires an argument of type `UpsertEpisodeVariables`:
const upsertEpisodeVars: UpsertEpisodeVariables = {
  id: ..., // optional
  podcastId: ..., 
  title: ..., 
  audioUrl: ..., 
  duration: ..., 
  description: ..., // optional
  imageUrl: ..., // optional
  publishedAt: ..., 
};

// Call the `upsertEpisodeRef()` function to get a reference to the mutation.
const ref = upsertEpisodeRef(upsertEpisodeVars);
// Variables can be defined inline as well.
const ref = upsertEpisodeRef({ id: ..., podcastId: ..., title: ..., audioUrl: ..., duration: ..., description: ..., imageUrl: ..., publishedAt: ..., });

// You can also pass in a `DataConnect` instance to the `MutationRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = upsertEpisodeRef(dataConnect, upsertEpisodeVars);

// Call `executeMutation()` on the reference to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeMutation(ref);

console.log(data.episode_upsert);

// Or, you can use the `Promise` API.
executeMutation(ref).then((response) => {
  const data = response.data;
  console.log(data.episode_upsert);
});
```

## SubscribeToPodcast
You can execute the `SubscribeToPodcast` mutation using the following action shortcut function, or by calling `executeMutation()` after calling the following `MutationRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
subscribeToPodcast(vars: SubscribeToPodcastVariables): MutationPromise<SubscribeToPodcastData, SubscribeToPodcastVariables>;

interface SubscribeToPodcastRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: SubscribeToPodcastVariables): MutationRef<SubscribeToPodcastData, SubscribeToPodcastVariables>;
}
export const subscribeToPodcastRef: SubscribeToPodcastRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `MutationRef` function.
```typescript
subscribeToPodcast(dc: DataConnect, vars: SubscribeToPodcastVariables): MutationPromise<SubscribeToPodcastData, SubscribeToPodcastVariables>;

interface SubscribeToPodcastRef {
  ...
  (dc: DataConnect, vars: SubscribeToPodcastVariables): MutationRef<SubscribeToPodcastData, SubscribeToPodcastVariables>;
}
export const subscribeToPodcastRef: SubscribeToPodcastRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the subscribeToPodcastRef:
```typescript
const name = subscribeToPodcastRef.operationName;
console.log(name);
```

### Variables
The `SubscribeToPodcast` mutation requires an argument of type `SubscribeToPodcastVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface SubscribeToPodcastVariables {
  userId: UUIDString;
  podcastId: UUIDString;
  subscribedAt: TimestampString;
  listOrder?: number | null;
}
```
### Return Type
Recall that executing the `SubscribeToPodcast` mutation returns a `MutationPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `SubscribeToPodcastData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface SubscribeToPodcastData {
  subscriptionType_upsert: SubscriptionType_Key;
}
```
### Using `SubscribeToPodcast`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, subscribeToPodcast, SubscribeToPodcastVariables } from '@dataconnect/generated';

// The `SubscribeToPodcast` mutation requires an argument of type `SubscribeToPodcastVariables`:
const subscribeToPodcastVars: SubscribeToPodcastVariables = {
  userId: ..., 
  podcastId: ..., 
  subscribedAt: ..., 
  listOrder: ..., // optional
};

// Call the `subscribeToPodcast()` function to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await subscribeToPodcast(subscribeToPodcastVars);
// Variables can be defined inline as well.
const { data } = await subscribeToPodcast({ userId: ..., podcastId: ..., subscribedAt: ..., listOrder: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await subscribeToPodcast(dataConnect, subscribeToPodcastVars);

console.log(data.subscriptionType_upsert);

// Or, you can use the `Promise` API.
subscribeToPodcast(subscribeToPodcastVars).then((response) => {
  const data = response.data;
  console.log(data.subscriptionType_upsert);
});
```

### Using `SubscribeToPodcast`'s `MutationRef` function

```typescript
import { getDataConnect, executeMutation } from 'firebase/data-connect';
import { connectorConfig, subscribeToPodcastRef, SubscribeToPodcastVariables } from '@dataconnect/generated';

// The `SubscribeToPodcast` mutation requires an argument of type `SubscribeToPodcastVariables`:
const subscribeToPodcastVars: SubscribeToPodcastVariables = {
  userId: ..., 
  podcastId: ..., 
  subscribedAt: ..., 
  listOrder: ..., // optional
};

// Call the `subscribeToPodcastRef()` function to get a reference to the mutation.
const ref = subscribeToPodcastRef(subscribeToPodcastVars);
// Variables can be defined inline as well.
const ref = subscribeToPodcastRef({ userId: ..., podcastId: ..., subscribedAt: ..., listOrder: ..., });

// You can also pass in a `DataConnect` instance to the `MutationRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = subscribeToPodcastRef(dataConnect, subscribeToPodcastVars);

// Call `executeMutation()` on the reference to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeMutation(ref);

console.log(data.subscriptionType_upsert);

// Or, you can use the `Promise` API.
executeMutation(ref).then((response) => {
  const data = response.data;
  console.log(data.subscriptionType_upsert);
});
```

## UpdateSubscriptionOrder
You can execute the `UpdateSubscriptionOrder` mutation using the following action shortcut function, or by calling `executeMutation()` after calling the following `MutationRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
updateSubscriptionOrder(vars: UpdateSubscriptionOrderVariables): MutationPromise<UpdateSubscriptionOrderData, UpdateSubscriptionOrderVariables>;

interface UpdateSubscriptionOrderRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: UpdateSubscriptionOrderVariables): MutationRef<UpdateSubscriptionOrderData, UpdateSubscriptionOrderVariables>;
}
export const updateSubscriptionOrderRef: UpdateSubscriptionOrderRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `MutationRef` function.
```typescript
updateSubscriptionOrder(dc: DataConnect, vars: UpdateSubscriptionOrderVariables): MutationPromise<UpdateSubscriptionOrderData, UpdateSubscriptionOrderVariables>;

interface UpdateSubscriptionOrderRef {
  ...
  (dc: DataConnect, vars: UpdateSubscriptionOrderVariables): MutationRef<UpdateSubscriptionOrderData, UpdateSubscriptionOrderVariables>;
}
export const updateSubscriptionOrderRef: UpdateSubscriptionOrderRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the updateSubscriptionOrderRef:
```typescript
const name = updateSubscriptionOrderRef.operationName;
console.log(name);
```

### Variables
The `UpdateSubscriptionOrder` mutation requires an argument of type `UpdateSubscriptionOrderVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface UpdateSubscriptionOrderVariables {
  userId: UUIDString;
  podcastId: UUIDString;
  listOrder: number;
}
```
### Return Type
Recall that executing the `UpdateSubscriptionOrder` mutation returns a `MutationPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `UpdateSubscriptionOrderData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface UpdateSubscriptionOrderData {
  subscriptionType_update?: SubscriptionType_Key | null;
}
```
### Using `UpdateSubscriptionOrder`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, updateSubscriptionOrder, UpdateSubscriptionOrderVariables } from '@dataconnect/generated';

// The `UpdateSubscriptionOrder` mutation requires an argument of type `UpdateSubscriptionOrderVariables`:
const updateSubscriptionOrderVars: UpdateSubscriptionOrderVariables = {
  userId: ..., 
  podcastId: ..., 
  listOrder: ..., 
};

// Call the `updateSubscriptionOrder()` function to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await updateSubscriptionOrder(updateSubscriptionOrderVars);
// Variables can be defined inline as well.
const { data } = await updateSubscriptionOrder({ userId: ..., podcastId: ..., listOrder: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await updateSubscriptionOrder(dataConnect, updateSubscriptionOrderVars);

console.log(data.subscriptionType_update);

// Or, you can use the `Promise` API.
updateSubscriptionOrder(updateSubscriptionOrderVars).then((response) => {
  const data = response.data;
  console.log(data.subscriptionType_update);
});
```

### Using `UpdateSubscriptionOrder`'s `MutationRef` function

```typescript
import { getDataConnect, executeMutation } from 'firebase/data-connect';
import { connectorConfig, updateSubscriptionOrderRef, UpdateSubscriptionOrderVariables } from '@dataconnect/generated';

// The `UpdateSubscriptionOrder` mutation requires an argument of type `UpdateSubscriptionOrderVariables`:
const updateSubscriptionOrderVars: UpdateSubscriptionOrderVariables = {
  userId: ..., 
  podcastId: ..., 
  listOrder: ..., 
};

// Call the `updateSubscriptionOrderRef()` function to get a reference to the mutation.
const ref = updateSubscriptionOrderRef(updateSubscriptionOrderVars);
// Variables can be defined inline as well.
const ref = updateSubscriptionOrderRef({ userId: ..., podcastId: ..., listOrder: ..., });

// You can also pass in a `DataConnect` instance to the `MutationRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = updateSubscriptionOrderRef(dataConnect, updateSubscriptionOrderVars);

// Call `executeMutation()` on the reference to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeMutation(ref);

console.log(data.subscriptionType_update);

// Or, you can use the `Promise` API.
executeMutation(ref).then((response) => {
  const data = response.data;
  console.log(data.subscriptionType_update);
});
```

## UnsubscribeFromPodcast
You can execute the `UnsubscribeFromPodcast` mutation using the following action shortcut function, or by calling `executeMutation()` after calling the following `MutationRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
unsubscribeFromPodcast(vars: UnsubscribeFromPodcastVariables): MutationPromise<UnsubscribeFromPodcastData, UnsubscribeFromPodcastVariables>;

interface UnsubscribeFromPodcastRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: UnsubscribeFromPodcastVariables): MutationRef<UnsubscribeFromPodcastData, UnsubscribeFromPodcastVariables>;
}
export const unsubscribeFromPodcastRef: UnsubscribeFromPodcastRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `MutationRef` function.
```typescript
unsubscribeFromPodcast(dc: DataConnect, vars: UnsubscribeFromPodcastVariables): MutationPromise<UnsubscribeFromPodcastData, UnsubscribeFromPodcastVariables>;

interface UnsubscribeFromPodcastRef {
  ...
  (dc: DataConnect, vars: UnsubscribeFromPodcastVariables): MutationRef<UnsubscribeFromPodcastData, UnsubscribeFromPodcastVariables>;
}
export const unsubscribeFromPodcastRef: UnsubscribeFromPodcastRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the unsubscribeFromPodcastRef:
```typescript
const name = unsubscribeFromPodcastRef.operationName;
console.log(name);
```

### Variables
The `UnsubscribeFromPodcast` mutation requires an argument of type `UnsubscribeFromPodcastVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface UnsubscribeFromPodcastVariables {
  userId: UUIDString;
  podcastId: UUIDString;
}
```
### Return Type
Recall that executing the `UnsubscribeFromPodcast` mutation returns a `MutationPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `UnsubscribeFromPodcastData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface UnsubscribeFromPodcastData {
  subscriptionType_delete?: SubscriptionType_Key | null;
}
```
### Using `UnsubscribeFromPodcast`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, unsubscribeFromPodcast, UnsubscribeFromPodcastVariables } from '@dataconnect/generated';

// The `UnsubscribeFromPodcast` mutation requires an argument of type `UnsubscribeFromPodcastVariables`:
const unsubscribeFromPodcastVars: UnsubscribeFromPodcastVariables = {
  userId: ..., 
  podcastId: ..., 
};

// Call the `unsubscribeFromPodcast()` function to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await unsubscribeFromPodcast(unsubscribeFromPodcastVars);
// Variables can be defined inline as well.
const { data } = await unsubscribeFromPodcast({ userId: ..., podcastId: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await unsubscribeFromPodcast(dataConnect, unsubscribeFromPodcastVars);

console.log(data.subscriptionType_delete);

// Or, you can use the `Promise` API.
unsubscribeFromPodcast(unsubscribeFromPodcastVars).then((response) => {
  const data = response.data;
  console.log(data.subscriptionType_delete);
});
```

### Using `UnsubscribeFromPodcast`'s `MutationRef` function

```typescript
import { getDataConnect, executeMutation } from 'firebase/data-connect';
import { connectorConfig, unsubscribeFromPodcastRef, UnsubscribeFromPodcastVariables } from '@dataconnect/generated';

// The `UnsubscribeFromPodcast` mutation requires an argument of type `UnsubscribeFromPodcastVariables`:
const unsubscribeFromPodcastVars: UnsubscribeFromPodcastVariables = {
  userId: ..., 
  podcastId: ..., 
};

// Call the `unsubscribeFromPodcastRef()` function to get a reference to the mutation.
const ref = unsubscribeFromPodcastRef(unsubscribeFromPodcastVars);
// Variables can be defined inline as well.
const ref = unsubscribeFromPodcastRef({ userId: ..., podcastId: ..., });

// You can also pass in a `DataConnect` instance to the `MutationRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = unsubscribeFromPodcastRef(dataConnect, unsubscribeFromPodcastVars);

// Call `executeMutation()` on the reference to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeMutation(ref);

console.log(data.subscriptionType_delete);

// Or, you can use the `Promise` API.
executeMutation(ref).then((response) => {
  const data = response.data;
  console.log(data.subscriptionType_delete);
});
```

## UpdateListenHistory
You can execute the `UpdateListenHistory` mutation using the following action shortcut function, or by calling `executeMutation()` after calling the following `MutationRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
updateListenHistory(vars: UpdateListenHistoryVariables): MutationPromise<UpdateListenHistoryData, UpdateListenHistoryVariables>;

interface UpdateListenHistoryRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: UpdateListenHistoryVariables): MutationRef<UpdateListenHistoryData, UpdateListenHistoryVariables>;
}
export const updateListenHistoryRef: UpdateListenHistoryRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `MutationRef` function.
```typescript
updateListenHistory(dc: DataConnect, vars: UpdateListenHistoryVariables): MutationPromise<UpdateListenHistoryData, UpdateListenHistoryVariables>;

interface UpdateListenHistoryRef {
  ...
  (dc: DataConnect, vars: UpdateListenHistoryVariables): MutationRef<UpdateListenHistoryData, UpdateListenHistoryVariables>;
}
export const updateListenHistoryRef: UpdateListenHistoryRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the updateListenHistoryRef:
```typescript
const name = updateListenHistoryRef.operationName;
console.log(name);
```

### Variables
The `UpdateListenHistory` mutation requires an argument of type `UpdateListenHistoryVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface UpdateListenHistoryVariables {
  userId: UUIDString;
  episodeId: UUIDString;
  progressSeconds: Int64String;
  finishedListening: boolean;
  listenedAt: TimestampString;
}
```
### Return Type
Recall that executing the `UpdateListenHistory` mutation returns a `MutationPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `UpdateListenHistoryData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface UpdateListenHistoryData {
  listenHistory_upsert: ListenHistory_Key;
}
```
### Using `UpdateListenHistory`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, updateListenHistory, UpdateListenHistoryVariables } from '@dataconnect/generated';

// The `UpdateListenHistory` mutation requires an argument of type `UpdateListenHistoryVariables`:
const updateListenHistoryVars: UpdateListenHistoryVariables = {
  userId: ..., 
  episodeId: ..., 
  progressSeconds: ..., 
  finishedListening: ..., 
  listenedAt: ..., 
};

// Call the `updateListenHistory()` function to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await updateListenHistory(updateListenHistoryVars);
// Variables can be defined inline as well.
const { data } = await updateListenHistory({ userId: ..., episodeId: ..., progressSeconds: ..., finishedListening: ..., listenedAt: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await updateListenHistory(dataConnect, updateListenHistoryVars);

console.log(data.listenHistory_upsert);

// Or, you can use the `Promise` API.
updateListenHistory(updateListenHistoryVars).then((response) => {
  const data = response.data;
  console.log(data.listenHistory_upsert);
});
```

### Using `UpdateListenHistory`'s `MutationRef` function

```typescript
import { getDataConnect, executeMutation } from 'firebase/data-connect';
import { connectorConfig, updateListenHistoryRef, UpdateListenHistoryVariables } from '@dataconnect/generated';

// The `UpdateListenHistory` mutation requires an argument of type `UpdateListenHistoryVariables`:
const updateListenHistoryVars: UpdateListenHistoryVariables = {
  userId: ..., 
  episodeId: ..., 
  progressSeconds: ..., 
  finishedListening: ..., 
  listenedAt: ..., 
};

// Call the `updateListenHistoryRef()` function to get a reference to the mutation.
const ref = updateListenHistoryRef(updateListenHistoryVars);
// Variables can be defined inline as well.
const ref = updateListenHistoryRef({ userId: ..., episodeId: ..., progressSeconds: ..., finishedListening: ..., listenedAt: ..., });

// You can also pass in a `DataConnect` instance to the `MutationRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = updateListenHistoryRef(dataConnect, updateListenHistoryVars);

// Call `executeMutation()` on the reference to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeMutation(ref);

console.log(data.listenHistory_upsert);

// Or, you can use the `Promise` API.
executeMutation(ref).then((response) => {
  const data = response.data;
  console.log(data.listenHistory_upsert);
});
```

