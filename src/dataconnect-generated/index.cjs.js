const { queryRef, executeQuery, validateArgsWithOptions, mutationRef, executeMutation, validateArgs, makeMemoryCacheProvider } = require('firebase/data-connect');

const connectorConfig = {
  connector: 'example',
  service: 'podstream-a980a-service',
  location: 'europe-west9'
};
exports.connectorConfig = connectorConfig;
const dataConnectSettings = {
  cacheSettings: {
    cacheProvider: makeMemoryCacheProvider()
  }
};
exports.dataConnectSettings = dataConnectSettings;

const upsertUserRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return mutationRef(dcInstance, 'UpsertUser', inputVars);
}
upsertUserRef.operationName = 'UpsertUser';
exports.upsertUserRef = upsertUserRef;

exports.upsertUser = function upsertUser(dcOrVars, vars) {
  const { dc: dcInstance, vars: inputVars } = validateArgs(connectorConfig, dcOrVars, vars, true);
  return executeMutation(upsertUserRef(dcInstance, inputVars));
}
;

const upsertPodcastRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return mutationRef(dcInstance, 'UpsertPodcast', inputVars);
}
upsertPodcastRef.operationName = 'UpsertPodcast';
exports.upsertPodcastRef = upsertPodcastRef;

exports.upsertPodcast = function upsertPodcast(dcOrVars, vars) {
  const { dc: dcInstance, vars: inputVars } = validateArgs(connectorConfig, dcOrVars, vars, true);
  return executeMutation(upsertPodcastRef(dcInstance, inputVars));
}
;

const upsertEpisodeRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return mutationRef(dcInstance, 'UpsertEpisode', inputVars);
}
upsertEpisodeRef.operationName = 'UpsertEpisode';
exports.upsertEpisodeRef = upsertEpisodeRef;

exports.upsertEpisode = function upsertEpisode(dcOrVars, vars) {
  const { dc: dcInstance, vars: inputVars } = validateArgs(connectorConfig, dcOrVars, vars, true);
  return executeMutation(upsertEpisodeRef(dcInstance, inputVars));
}
;

const subscribeToPodcastRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return mutationRef(dcInstance, 'SubscribeToPodcast', inputVars);
}
subscribeToPodcastRef.operationName = 'SubscribeToPodcast';
exports.subscribeToPodcastRef = subscribeToPodcastRef;

exports.subscribeToPodcast = function subscribeToPodcast(dcOrVars, vars) {
  const { dc: dcInstance, vars: inputVars } = validateArgs(connectorConfig, dcOrVars, vars, true);
  return executeMutation(subscribeToPodcastRef(dcInstance, inputVars));
}
;

const updateSubscriptionOrderRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return mutationRef(dcInstance, 'UpdateSubscriptionOrder', inputVars);
}
updateSubscriptionOrderRef.operationName = 'UpdateSubscriptionOrder';
exports.updateSubscriptionOrderRef = updateSubscriptionOrderRef;

exports.updateSubscriptionOrder = function updateSubscriptionOrder(dcOrVars, vars) {
  const { dc: dcInstance, vars: inputVars } = validateArgs(connectorConfig, dcOrVars, vars, true);
  return executeMutation(updateSubscriptionOrderRef(dcInstance, inputVars));
}
;

const unsubscribeFromPodcastRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return mutationRef(dcInstance, 'UnsubscribeFromPodcast', inputVars);
}
unsubscribeFromPodcastRef.operationName = 'UnsubscribeFromPodcast';
exports.unsubscribeFromPodcastRef = unsubscribeFromPodcastRef;

exports.unsubscribeFromPodcast = function unsubscribeFromPodcast(dcOrVars, vars) {
  const { dc: dcInstance, vars: inputVars } = validateArgs(connectorConfig, dcOrVars, vars, true);
  return executeMutation(unsubscribeFromPodcastRef(dcInstance, inputVars));
}
;

const updateListenHistoryRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return mutationRef(dcInstance, 'UpdateListenHistory', inputVars);
}
updateListenHistoryRef.operationName = 'UpdateListenHistory';
exports.updateListenHistoryRef = updateListenHistoryRef;

exports.updateListenHistory = function updateListenHistory(dcOrVars, vars) {
  const { dc: dcInstance, vars: inputVars } = validateArgs(connectorConfig, dcOrVars, vars, true);
  return executeMutation(updateListenHistoryRef(dcInstance, inputVars));
}
;

const findUserByGoogleIdRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return queryRef(dcInstance, 'FindUserByGoogleId', inputVars);
}
findUserByGoogleIdRef.operationName = 'FindUserByGoogleId';
exports.findUserByGoogleIdRef = findUserByGoogleIdRef;

exports.findUserByGoogleId = function findUserByGoogleId(dcOrVars, varsOrOptions, options) {
  
  const { dc: dcInstance, vars: inputVars, options: inputOpts } = validateArgsWithOptions(connectorConfig, dcOrVars, varsOrOptions, options, true, true);
  return executeQuery(findUserByGoogleIdRef(dcInstance, inputVars), inputOpts && inputOpts.fetchPolicy);
}
;

const getMySubscriptionsRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return queryRef(dcInstance, 'GetMySubscriptions', inputVars);
}
getMySubscriptionsRef.operationName = 'GetMySubscriptions';
exports.getMySubscriptionsRef = getMySubscriptionsRef;

exports.getMySubscriptions = function getMySubscriptions(dcOrVars, varsOrOptions, options) {
  
  const { dc: dcInstance, vars: inputVars, options: inputOpts } = validateArgsWithOptions(connectorConfig, dcOrVars, varsOrOptions, options, true, true);
  return executeQuery(getMySubscriptionsRef(dcInstance, inputVars), inputOpts && inputOpts.fetchPolicy);
}
;

const getListenHistoryRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return queryRef(dcInstance, 'GetListenHistory', inputVars);
}
getListenHistoryRef.operationName = 'GetListenHistory';
exports.getListenHistoryRef = getListenHistoryRef;

exports.getListenHistory = function getListenHistory(dcOrVars, varsOrOptions, options) {
  
  const { dc: dcInstance, vars: inputVars, options: inputOpts } = validateArgsWithOptions(connectorConfig, dcOrVars, varsOrOptions, options, true, true);
  return executeQuery(getListenHistoryRef(dcInstance, inputVars), inputOpts && inputOpts.fetchPolicy);
}
;

const getRecommendationsRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return queryRef(dcInstance, 'GetRecommendations', inputVars);
}
getRecommendationsRef.operationName = 'GetRecommendations';
exports.getRecommendationsRef = getRecommendationsRef;

exports.getRecommendations = function getRecommendations(dcOrVars, varsOrOptions, options) {
  
  const { dc: dcInstance, vars: inputVars, options: inputOpts } = validateArgsWithOptions(connectorConfig, dcOrVars, varsOrOptions, options, true, true);
  return executeQuery(getRecommendationsRef(dcInstance, inputVars), inputOpts && inputOpts.fetchPolicy);
}
;

const getEpisodesByPodcastRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return queryRef(dcInstance, 'GetEpisodesByPodcast', inputVars);
}
getEpisodesByPodcastRef.operationName = 'GetEpisodesByPodcast';
exports.getEpisodesByPodcastRef = getEpisodesByPodcastRef;

exports.getEpisodesByPodcast = function getEpisodesByPodcast(dcOrVars, varsOrOptions, options) {
  
  const { dc: dcInstance, vars: inputVars, options: inputOpts } = validateArgsWithOptions(connectorConfig, dcOrVars, varsOrOptions, options, true, true);
  return executeQuery(getEpisodesByPodcastRef(dcInstance, inputVars), inputOpts && inputOpts.fetchPolicy);
}
;

const getLatestSubscribedEpisodesRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return queryRef(dcInstance, 'GetLatestSubscribedEpisodes', inputVars);
}
getLatestSubscribedEpisodesRef.operationName = 'GetLatestSubscribedEpisodes';
exports.getLatestSubscribedEpisodesRef = getLatestSubscribedEpisodesRef;

exports.getLatestSubscribedEpisodes = function getLatestSubscribedEpisodes(dcOrVars, varsOrOptions, options) {
  
  const { dc: dcInstance, vars: inputVars, options: inputOpts } = validateArgsWithOptions(connectorConfig, dcOrVars, varsOrOptions, options, true, true);
  return executeQuery(getLatestSubscribedEpisodesRef(dcInstance, inputVars), inputOpts && inputOpts.fetchPolicy);
}
;
