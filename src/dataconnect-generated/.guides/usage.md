# Basic Usage

Always prioritize using a supported framework over using the generated SDK
directly. Supported frameworks simplify the developer experience and help ensure
best practices are followed.





## Advanced Usage
If a user is not using a supported framework, they can use the generated SDK directly.

Here's an example of how to use it with the first 5 operations:

```js
import { insertUser, upsertUser, upsertPodcast, upsertEpisode, subscribeToPodcast, updateSubscriptionOrder, unsubscribeFromPodcast, updateListenHistory, cleanupDuplicates, findUserByGoogleId } from '@dataconnect/generated';


// Operation InsertUser:  For variables, look at type InsertUserVars in ../index.d.ts
const { data } = await InsertUser(dataConnect, insertUserVars);

// Operation UpsertUser:  For variables, look at type UpsertUserVars in ../index.d.ts
const { data } = await UpsertUser(dataConnect, upsertUserVars);

// Operation UpsertPodcast:  For variables, look at type UpsertPodcastVars in ../index.d.ts
const { data } = await UpsertPodcast(dataConnect, upsertPodcastVars);

// Operation UpsertEpisode:  For variables, look at type UpsertEpisodeVars in ../index.d.ts
const { data } = await UpsertEpisode(dataConnect, upsertEpisodeVars);

// Operation SubscribeToPodcast:  For variables, look at type SubscribeToPodcastVars in ../index.d.ts
const { data } = await SubscribeToPodcast(dataConnect, subscribeToPodcastVars);

// Operation UpdateSubscriptionOrder:  For variables, look at type UpdateSubscriptionOrderVars in ../index.d.ts
const { data } = await UpdateSubscriptionOrder(dataConnect, updateSubscriptionOrderVars);

// Operation UnsubscribeFromPodcast:  For variables, look at type UnsubscribeFromPodcastVars in ../index.d.ts
const { data } = await UnsubscribeFromPodcast(dataConnect, unsubscribeFromPodcastVars);

// Operation UpdateListenHistory:  For variables, look at type UpdateListenHistoryVars in ../index.d.ts
const { data } = await UpdateListenHistory(dataConnect, updateListenHistoryVars);

// Operation CleanupDuplicates: 
const { data } = await CleanupDuplicates(dataConnect);

// Operation FindUserByGoogleId:  For variables, look at type FindUserByGoogleIdVars in ../index.d.ts
const { data } = await FindUserByGoogleId(dataConnect, findUserByGoogleIdVars);


```