import { ConnectorConfig, DataConnect, QueryRef, QueryPromise, ExecuteQueryOptions, MutationRef, MutationPromise, DataConnectSettings } from 'firebase/data-connect';

export const connectorConfig: ConnectorConfig;
export const dataConnectSettings: DataConnectSettings;

export type TimestampString = string;
export type UUIDString = string;
export type Int64String = string;
export type DateString = string;




export interface CleanupDuplicatesData {
  cleanEpisodes?: number | null;
  cleanPodcasts?: number | null;
  cleanUsers?: number | null;
}

export interface Episode_Key {
  id: UUIDString;
  __typename?: 'Episode_Key';
}

export interface FindUserByGoogleIdData {
  users: ({
    id: UUIDString;
    googleId: string;
    displayName: string;
    email?: string | null;
  } & User_Key)[];
}

export interface FindUserByGoogleIdVariables {
  googleId: string;
}

export interface GetEpisodesByPodcastData {
  episodes: ({
    id: UUIDString;
    title: string;
    audioUrl: string;
    duration: Int64String;
    description?: string | null;
    imageUrl?: string | null;
    publishedAt: TimestampString;
  } & Episode_Key)[];
}

export interface GetEpisodesByPodcastVariables {
  podcastId: UUIDString;
}

export interface GetLatestSubscribedEpisodesData {
  subscriptionTypes: ({
    listOrder?: number | null;
    podcast: {
      id: UUIDString;
      title: string;
      imageUrl?: string | null;
      episodes_on_podcast: ({
        id: UUIDString;
        title: string;
        audioUrl: string;
        publishedAt: TimestampString;
        imageUrl?: string | null;
        description?: string | null;
      } & Episode_Key)[];
    } & Podcast_Key;
  })[];
}

export interface GetLatestSubscribedEpisodesVariables {
  userId: UUIDString;
}

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

export interface GetListenHistoryVariables {
  userId: UUIDString;
}

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

export interface GetMySubscriptionsVariables {
  userId: UUIDString;
}

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

export interface GetRecommendationsVariables {
  feedUrl: string;
}

export interface InsertUserData {
  user_insert: User_Key;
}

export interface InsertUserVariables {
  googleId: string;
  displayName: string;
  email?: string | null;
  photoUrl?: string | null;
  createdAt: TimestampString;
}

export interface ListenHistory_Key {
  userId: UUIDString;
  episodeId: UUIDString;
  __typename?: 'ListenHistory_Key';
}

export interface Podcast_Key {
  id: UUIDString;
  __typename?: 'Podcast_Key';
}

export interface SubscribeToPodcastData {
  subscriptionType_upsert: SubscriptionType_Key;
}

export interface SubscribeToPodcastVariables {
  userId: UUIDString;
  podcastId: UUIDString;
  subscribedAt: TimestampString;
  listOrder?: number | null;
}

export interface SubscriptionType_Key {
  userId: UUIDString;
  podcastId: UUIDString;
  __typename?: 'SubscriptionType_Key';
}

export interface UnsubscribeFromPodcastData {
  subscriptionType_delete?: SubscriptionType_Key | null;
}

export interface UnsubscribeFromPodcastVariables {
  userId: UUIDString;
  podcastId: UUIDString;
}

export interface UpdateListenHistoryData {
  listenHistory_upsert: ListenHistory_Key;
}

export interface UpdateListenHistoryVariables {
  userId: UUIDString;
  episodeId: UUIDString;
  progressSeconds: Int64String;
  finishedListening: boolean;
  listenedAt: TimestampString;
}

export interface UpdateSubscriptionOrderData {
  subscriptionType_update?: SubscriptionType_Key | null;
}

export interface UpdateSubscriptionOrderVariables {
  userId: UUIDString;
  podcastId: UUIDString;
  listOrder: number;
}

export interface UpsertEpisodeData {
  episode_upsert: Episode_Key;
}

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

export interface UpsertPodcastData {
  podcast_upsert: Podcast_Key;
}

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

export interface UpsertUserData {
  user_upsert: User_Key;
}

export interface UpsertUserVariables {
  id: UUIDString;
  googleId: string;
  displayName: string;
  email?: string | null;
  photoUrl?: string | null;
  createdAt: TimestampString;
}

export interface User_Key {
  id: UUIDString;
  __typename?: 'User_Key';
}

interface InsertUserRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: InsertUserVariables): MutationRef<InsertUserData, InsertUserVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: InsertUserVariables): MutationRef<InsertUserData, InsertUserVariables>;
  operationName: string;
}
export const insertUserRef: InsertUserRef;

export function insertUser(vars: InsertUserVariables): MutationPromise<InsertUserData, InsertUserVariables>;
export function insertUser(dc: DataConnect, vars: InsertUserVariables): MutationPromise<InsertUserData, InsertUserVariables>;

interface UpsertUserRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: UpsertUserVariables): MutationRef<UpsertUserData, UpsertUserVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: UpsertUserVariables): MutationRef<UpsertUserData, UpsertUserVariables>;
  operationName: string;
}
export const upsertUserRef: UpsertUserRef;

export function upsertUser(vars: UpsertUserVariables): MutationPromise<UpsertUserData, UpsertUserVariables>;
export function upsertUser(dc: DataConnect, vars: UpsertUserVariables): MutationPromise<UpsertUserData, UpsertUserVariables>;

interface UpsertPodcastRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: UpsertPodcastVariables): MutationRef<UpsertPodcastData, UpsertPodcastVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: UpsertPodcastVariables): MutationRef<UpsertPodcastData, UpsertPodcastVariables>;
  operationName: string;
}
export const upsertPodcastRef: UpsertPodcastRef;

export function upsertPodcast(vars: UpsertPodcastVariables): MutationPromise<UpsertPodcastData, UpsertPodcastVariables>;
export function upsertPodcast(dc: DataConnect, vars: UpsertPodcastVariables): MutationPromise<UpsertPodcastData, UpsertPodcastVariables>;

interface UpsertEpisodeRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: UpsertEpisodeVariables): MutationRef<UpsertEpisodeData, UpsertEpisodeVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: UpsertEpisodeVariables): MutationRef<UpsertEpisodeData, UpsertEpisodeVariables>;
  operationName: string;
}
export const upsertEpisodeRef: UpsertEpisodeRef;

export function upsertEpisode(vars: UpsertEpisodeVariables): MutationPromise<UpsertEpisodeData, UpsertEpisodeVariables>;
export function upsertEpisode(dc: DataConnect, vars: UpsertEpisodeVariables): MutationPromise<UpsertEpisodeData, UpsertEpisodeVariables>;

interface SubscribeToPodcastRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: SubscribeToPodcastVariables): MutationRef<SubscribeToPodcastData, SubscribeToPodcastVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: SubscribeToPodcastVariables): MutationRef<SubscribeToPodcastData, SubscribeToPodcastVariables>;
  operationName: string;
}
export const subscribeToPodcastRef: SubscribeToPodcastRef;

export function subscribeToPodcast(vars: SubscribeToPodcastVariables): MutationPromise<SubscribeToPodcastData, SubscribeToPodcastVariables>;
export function subscribeToPodcast(dc: DataConnect, vars: SubscribeToPodcastVariables): MutationPromise<SubscribeToPodcastData, SubscribeToPodcastVariables>;

interface UpdateSubscriptionOrderRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: UpdateSubscriptionOrderVariables): MutationRef<UpdateSubscriptionOrderData, UpdateSubscriptionOrderVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: UpdateSubscriptionOrderVariables): MutationRef<UpdateSubscriptionOrderData, UpdateSubscriptionOrderVariables>;
  operationName: string;
}
export const updateSubscriptionOrderRef: UpdateSubscriptionOrderRef;

export function updateSubscriptionOrder(vars: UpdateSubscriptionOrderVariables): MutationPromise<UpdateSubscriptionOrderData, UpdateSubscriptionOrderVariables>;
export function updateSubscriptionOrder(dc: DataConnect, vars: UpdateSubscriptionOrderVariables): MutationPromise<UpdateSubscriptionOrderData, UpdateSubscriptionOrderVariables>;

interface UnsubscribeFromPodcastRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: UnsubscribeFromPodcastVariables): MutationRef<UnsubscribeFromPodcastData, UnsubscribeFromPodcastVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: UnsubscribeFromPodcastVariables): MutationRef<UnsubscribeFromPodcastData, UnsubscribeFromPodcastVariables>;
  operationName: string;
}
export const unsubscribeFromPodcastRef: UnsubscribeFromPodcastRef;

export function unsubscribeFromPodcast(vars: UnsubscribeFromPodcastVariables): MutationPromise<UnsubscribeFromPodcastData, UnsubscribeFromPodcastVariables>;
export function unsubscribeFromPodcast(dc: DataConnect, vars: UnsubscribeFromPodcastVariables): MutationPromise<UnsubscribeFromPodcastData, UnsubscribeFromPodcastVariables>;

interface UpdateListenHistoryRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: UpdateListenHistoryVariables): MutationRef<UpdateListenHistoryData, UpdateListenHistoryVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: UpdateListenHistoryVariables): MutationRef<UpdateListenHistoryData, UpdateListenHistoryVariables>;
  operationName: string;
}
export const updateListenHistoryRef: UpdateListenHistoryRef;

export function updateListenHistory(vars: UpdateListenHistoryVariables): MutationPromise<UpdateListenHistoryData, UpdateListenHistoryVariables>;
export function updateListenHistory(dc: DataConnect, vars: UpdateListenHistoryVariables): MutationPromise<UpdateListenHistoryData, UpdateListenHistoryVariables>;

interface CleanupDuplicatesRef {
  /* Allow users to create refs without passing in DataConnect */
  (): MutationRef<CleanupDuplicatesData, undefined>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect): MutationRef<CleanupDuplicatesData, undefined>;
  operationName: string;
}
export const cleanupDuplicatesRef: CleanupDuplicatesRef;

export function cleanupDuplicates(): MutationPromise<CleanupDuplicatesData, undefined>;
export function cleanupDuplicates(dc: DataConnect): MutationPromise<CleanupDuplicatesData, undefined>;

interface FindUserByGoogleIdRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: FindUserByGoogleIdVariables): QueryRef<FindUserByGoogleIdData, FindUserByGoogleIdVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: FindUserByGoogleIdVariables): QueryRef<FindUserByGoogleIdData, FindUserByGoogleIdVariables>;
  operationName: string;
}
export const findUserByGoogleIdRef: FindUserByGoogleIdRef;

export function findUserByGoogleId(vars: FindUserByGoogleIdVariables, options?: ExecuteQueryOptions): QueryPromise<FindUserByGoogleIdData, FindUserByGoogleIdVariables>;
export function findUserByGoogleId(dc: DataConnect, vars: FindUserByGoogleIdVariables, options?: ExecuteQueryOptions): QueryPromise<FindUserByGoogleIdData, FindUserByGoogleIdVariables>;

interface GetMySubscriptionsRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: GetMySubscriptionsVariables): QueryRef<GetMySubscriptionsData, GetMySubscriptionsVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: GetMySubscriptionsVariables): QueryRef<GetMySubscriptionsData, GetMySubscriptionsVariables>;
  operationName: string;
}
export const getMySubscriptionsRef: GetMySubscriptionsRef;

export function getMySubscriptions(vars: GetMySubscriptionsVariables, options?: ExecuteQueryOptions): QueryPromise<GetMySubscriptionsData, GetMySubscriptionsVariables>;
export function getMySubscriptions(dc: DataConnect, vars: GetMySubscriptionsVariables, options?: ExecuteQueryOptions): QueryPromise<GetMySubscriptionsData, GetMySubscriptionsVariables>;

interface GetListenHistoryRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: GetListenHistoryVariables): QueryRef<GetListenHistoryData, GetListenHistoryVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: GetListenHistoryVariables): QueryRef<GetListenHistoryData, GetListenHistoryVariables>;
  operationName: string;
}
export const getListenHistoryRef: GetListenHistoryRef;

export function getListenHistory(vars: GetListenHistoryVariables, options?: ExecuteQueryOptions): QueryPromise<GetListenHistoryData, GetListenHistoryVariables>;
export function getListenHistory(dc: DataConnect, vars: GetListenHistoryVariables, options?: ExecuteQueryOptions): QueryPromise<GetListenHistoryData, GetListenHistoryVariables>;

interface GetRecommendationsRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: GetRecommendationsVariables): QueryRef<GetRecommendationsData, GetRecommendationsVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: GetRecommendationsVariables): QueryRef<GetRecommendationsData, GetRecommendationsVariables>;
  operationName: string;
}
export const getRecommendationsRef: GetRecommendationsRef;

export function getRecommendations(vars: GetRecommendationsVariables, options?: ExecuteQueryOptions): QueryPromise<GetRecommendationsData, GetRecommendationsVariables>;
export function getRecommendations(dc: DataConnect, vars: GetRecommendationsVariables, options?: ExecuteQueryOptions): QueryPromise<GetRecommendationsData, GetRecommendationsVariables>;

interface GetEpisodesByPodcastRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: GetEpisodesByPodcastVariables): QueryRef<GetEpisodesByPodcastData, GetEpisodesByPodcastVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: GetEpisodesByPodcastVariables): QueryRef<GetEpisodesByPodcastData, GetEpisodesByPodcastVariables>;
  operationName: string;
}
export const getEpisodesByPodcastRef: GetEpisodesByPodcastRef;

export function getEpisodesByPodcast(vars: GetEpisodesByPodcastVariables, options?: ExecuteQueryOptions): QueryPromise<GetEpisodesByPodcastData, GetEpisodesByPodcastVariables>;
export function getEpisodesByPodcast(dc: DataConnect, vars: GetEpisodesByPodcastVariables, options?: ExecuteQueryOptions): QueryPromise<GetEpisodesByPodcastData, GetEpisodesByPodcastVariables>;

interface GetLatestSubscribedEpisodesRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: GetLatestSubscribedEpisodesVariables): QueryRef<GetLatestSubscribedEpisodesData, GetLatestSubscribedEpisodesVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: GetLatestSubscribedEpisodesVariables): QueryRef<GetLatestSubscribedEpisodesData, GetLatestSubscribedEpisodesVariables>;
  operationName: string;
}
export const getLatestSubscribedEpisodesRef: GetLatestSubscribedEpisodesRef;

export function getLatestSubscribedEpisodes(vars: GetLatestSubscribedEpisodesVariables, options?: ExecuteQueryOptions): QueryPromise<GetLatestSubscribedEpisodesData, GetLatestSubscribedEpisodesVariables>;
export function getLatestSubscribedEpisodes(dc: DataConnect, vars: GetLatestSubscribedEpisodesVariables, options?: ExecuteQueryOptions): QueryPromise<GetLatestSubscribedEpisodesData, GetLatestSubscribedEpisodesVariables>;

