# Basic Usage

Always prioritize using a supported framework over using the generated SDK
directly. Supported frameworks simplify the developer experience and help ensure
best practices are followed.





## Advanced Usage
If a user is not using a supported framework, they can use the generated SDK directly.

Here's an example of how to use it with the first 5 operations:

```js
import { findUserByGoogleId, getMySubscriptions, getListenHistory, getRecommendations, getEpisodesByPodcast, getLatestSubscribedEpisodes, getAppCache, insertUser, upsertUser, upsertPodcast } from '@dataconnect/generated';


// Operation FindUserByGoogleId:  For variables, look at type FindUserByGoogleIdVars in ../index.d.ts
const { data } = await FindUserByGoogleId(dataConnect, findUserByGoogleIdVars);

// Operation GetMySubscriptions:  For variables, look at type GetMySubscriptionsVars in ../index.d.ts
const { data } = await GetMySubscriptions(dataConnect, getMySubscriptionsVars);

// Operation GetListenHistory:  For variables, look at type GetListenHistoryVars in ../index.d.ts
const { data } = await GetListenHistory(dataConnect, getListenHistoryVars);

// Operation GetRecommendations:  For variables, look at type GetRecommendationsVars in ../index.d.ts
const { data } = await GetRecommendations(dataConnect, getRecommendationsVars);

// Operation GetEpisodesByPodcast:  For variables, look at type GetEpisodesByPodcastVars in ../index.d.ts
const { data } = await GetEpisodesByPodcast(dataConnect, getEpisodesByPodcastVars);

// Operation GetLatestSubscribedEpisodes:  For variables, look at type GetLatestSubscribedEpisodesVars in ../index.d.ts
const { data } = await GetLatestSubscribedEpisodes(dataConnect, getLatestSubscribedEpisodesVars);

// Operation GetAppCache:  For variables, look at type GetAppCacheVars in ../index.d.ts
const { data } = await GetAppCache(dataConnect, getAppCacheVars);

// Operation InsertUser:  For variables, look at type InsertUserVars in ../index.d.ts
const { data } = await InsertUser(dataConnect, insertUserVars);

// Operation UpsertUser:  For variables, look at type UpsertUserVars in ../index.d.ts
const { data } = await UpsertUser(dataConnect, upsertUserVars);

// Operation UpsertPodcast:  For variables, look at type UpsertPodcastVars in ../index.d.ts
const { data } = await UpsertPodcast(dataConnect, upsertPodcastVars);


```