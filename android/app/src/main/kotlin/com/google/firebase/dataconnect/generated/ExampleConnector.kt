
@file:Suppress(
  "KotlinRedundantDiagnosticSuppress",
  "LocalVariableName",
  "MayBeConstant",
  "RedundantVisibilityModifier",
  "RedundantCompanionReference",
  "RemoveEmptyClassBody",
  "SpellCheckingInspection",
  "LocalVariableName",
  "unused",
)

package com.google.firebase.dataconnect.generated

import com.google.firebase.dataconnect.getInstance as _fdcGetInstance
import kotlin.time.Duration.Companion.milliseconds as _milliseconds

public interface ExampleConnector : com.google.firebase.dataconnect.generated.GeneratedConnector<ExampleConnector> {
  override val dataConnect: com.google.firebase.dataconnect.FirebaseDataConnect

  
    public val findUserByGoogleId: FindUserByGoogleIdQuery
  
    public val getListenHistory: GetListenHistoryQuery
  
    public val getMySubscriptions: GetMySubscriptionsQuery
  
    public val getRecommendations: GetRecommendationsQuery
  
    public val subscribeToPodcast: SubscribeToPodcastMutation
  
    public val unsubscribeFromPodcast: UnsubscribeFromPodcastMutation
  
    public val updateListenHistory: UpdateListenHistoryMutation
  
    public val updateSubscriptionOrder: UpdateSubscriptionOrderMutation
  
    public val upsertEpisode: UpsertEpisodeMutation
  
    public val upsertPodcast: UpsertPodcastMutation
  
    public val upsertUser: UpsertUserMutation
  

  public companion object {
    @Suppress("MemberVisibilityCanBePrivate")
    public val config: com.google.firebase.dataconnect.ConnectorConfig = com.google.firebase.dataconnect.ConnectorConfig(
      connector = "example",
      location = "europe-west9",
      serviceId = "podstream-a980a-service",
    )

    public fun getInstance(
      dataConnect: com.google.firebase.dataconnect.FirebaseDataConnect
    ):ExampleConnector = synchronized(instances) {
      instances.getOrPut(dataConnect) {
        ExampleConnectorImpl(dataConnect)
      }
    }

    private val instances = java.util.WeakHashMap<com.google.firebase.dataconnect.FirebaseDataConnect, ExampleConnectorImpl>()

    
    public val defaultCacheSettings: com.google.firebase.dataconnect.CacheSettings =
      com.google.firebase.dataconnect.CacheSettings(
        
        
      )

    public val defaultDataConnectSettings: com.google.firebase.dataconnect.DataConnectSettings =
      com.google.firebase.dataconnect.DataConnectSettings(
        cacheSettings = defaultCacheSettings,
      )
    
  }
}

public val ExampleConnector.Companion.instance:ExampleConnector
  get() = getInstance(com.google.firebase.dataconnect.FirebaseDataConnect._fdcGetInstance(
    config, defaultDataConnectSettings
  ))

public fun ExampleConnector.Companion.getInstance(
  settings: com.google.firebase.dataconnect.DataConnectSettings = defaultDataConnectSettings
):ExampleConnector =
  getInstance(com.google.firebase.dataconnect.FirebaseDataConnect._fdcGetInstance(config, settings))

public fun ExampleConnector.Companion.getInstance(
  app: com.google.firebase.FirebaseApp,
  settings: com.google.firebase.dataconnect.DataConnectSettings = defaultDataConnectSettings
):ExampleConnector =
  getInstance(com.google.firebase.dataconnect.FirebaseDataConnect._fdcGetInstance(app, config, settings))

private class ExampleConnectorImpl(
  override val dataConnect: com.google.firebase.dataconnect.FirebaseDataConnect
) : ExampleConnector {
  
    override val findUserByGoogleId by lazy(LazyThreadSafetyMode.PUBLICATION) {
      FindUserByGoogleIdQueryImpl(this)
    }
  
    override val getListenHistory by lazy(LazyThreadSafetyMode.PUBLICATION) {
      GetListenHistoryQueryImpl(this)
    }
  
    override val getMySubscriptions by lazy(LazyThreadSafetyMode.PUBLICATION) {
      GetMySubscriptionsQueryImpl(this)
    }
  
    override val getRecommendations by lazy(LazyThreadSafetyMode.PUBLICATION) {
      GetRecommendationsQueryImpl(this)
    }
  
    override val subscribeToPodcast by lazy(LazyThreadSafetyMode.PUBLICATION) {
      SubscribeToPodcastMutationImpl(this)
    }
  
    override val unsubscribeFromPodcast by lazy(LazyThreadSafetyMode.PUBLICATION) {
      UnsubscribeFromPodcastMutationImpl(this)
    }
  
    override val updateListenHistory by lazy(LazyThreadSafetyMode.PUBLICATION) {
      UpdateListenHistoryMutationImpl(this)
    }
  
    override val updateSubscriptionOrder by lazy(LazyThreadSafetyMode.PUBLICATION) {
      UpdateSubscriptionOrderMutationImpl(this)
    }
  
    override val upsertEpisode by lazy(LazyThreadSafetyMode.PUBLICATION) {
      UpsertEpisodeMutationImpl(this)
    }
  
    override val upsertPodcast by lazy(LazyThreadSafetyMode.PUBLICATION) {
      UpsertPodcastMutationImpl(this)
    }
  
    override val upsertUser by lazy(LazyThreadSafetyMode.PUBLICATION) {
      UpsertUserMutationImpl(this)
    }
  

  @com.google.firebase.dataconnect.ExperimentalFirebaseDataConnect
  override fun operations(): List<com.google.firebase.dataconnect.generated.GeneratedOperation<ExampleConnector, *, *>> =
    queries() + mutations()

  @com.google.firebase.dataconnect.ExperimentalFirebaseDataConnect
  override fun mutations(): List<com.google.firebase.dataconnect.generated.GeneratedMutation<ExampleConnector, *, *>> =
    listOf(
      subscribeToPodcast,
        unsubscribeFromPodcast,
        updateListenHistory,
        updateSubscriptionOrder,
        upsertEpisode,
        upsertPodcast,
        upsertUser,
        
    )

  @com.google.firebase.dataconnect.ExperimentalFirebaseDataConnect
  override fun queries(): List<com.google.firebase.dataconnect.generated.GeneratedQuery<ExampleConnector, *, *>> =
    listOf(
      findUserByGoogleId,
        getListenHistory,
        getMySubscriptions,
        getRecommendations,
        
    )

  @com.google.firebase.dataconnect.ExperimentalFirebaseDataConnect
  override fun copy(dataConnect: com.google.firebase.dataconnect.FirebaseDataConnect) =
    ExampleConnectorImpl(dataConnect)

  override fun equals(other: Any?): Boolean =
    other is ExampleConnectorImpl &&
    other.dataConnect == dataConnect

  override fun hashCode(): Int =
    java.util.Objects.hash(
      "ExampleConnectorImpl",
      dataConnect,
    )

  override fun toString(): String =
    "ExampleConnectorImpl(dataConnect=$dataConnect)"
}



private open class ExampleConnectorGeneratedQueryImpl<Data, Variables>(
  override val connector: ExampleConnector,
  override val operationName: String,
  override val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data>,
  override val variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables>,
) : com.google.firebase.dataconnect.generated.GeneratedQuery<ExampleConnector, Data, Variables> {

  @com.google.firebase.dataconnect.ExperimentalFirebaseDataConnect
  override fun copy(
    connector: ExampleConnector,
    operationName: String,
    dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data>,
    variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables>,
  ) =
    ExampleConnectorGeneratedQueryImpl(
      connector, operationName, dataDeserializer, variablesSerializer
    )

  @com.google.firebase.dataconnect.ExperimentalFirebaseDataConnect
  override fun <NewVariables> withVariablesSerializer(
    variablesSerializer: kotlinx.serialization.SerializationStrategy<NewVariables>
  ) =
    ExampleConnectorGeneratedQueryImpl(
      connector, operationName, dataDeserializer, variablesSerializer
    )

  @com.google.firebase.dataconnect.ExperimentalFirebaseDataConnect
  override fun <NewData> withDataDeserializer(
    dataDeserializer: kotlinx.serialization.DeserializationStrategy<NewData>
  ) =
    ExampleConnectorGeneratedQueryImpl(
      connector, operationName, dataDeserializer, variablesSerializer
    )

  override fun equals(other: Any?): Boolean =
    other is ExampleConnectorGeneratedQueryImpl<*,*> &&
    other.connector == connector &&
    other.operationName == operationName &&
    other.dataDeserializer == dataDeserializer &&
    other.variablesSerializer == variablesSerializer

  override fun hashCode(): Int =
    java.util.Objects.hash(
      "ExampleConnectorGeneratedQueryImpl",
      connector, operationName, dataDeserializer, variablesSerializer
    )

  override fun toString(): String =
    "ExampleConnectorGeneratedQueryImpl(" +
    "operationName=$operationName, " +
    "dataDeserializer=$dataDeserializer, " +
    "variablesSerializer=$variablesSerializer, " +
    "connector=$connector)"
}

private open class ExampleConnectorGeneratedMutationImpl<Data, Variables>(
  override val connector: ExampleConnector,
  override val operationName: String,
  override val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data>,
  override val variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables>,
) : com.google.firebase.dataconnect.generated.GeneratedMutation<ExampleConnector, Data, Variables> {

  @com.google.firebase.dataconnect.ExperimentalFirebaseDataConnect
  override fun copy(
    connector: ExampleConnector,
    operationName: String,
    dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data>,
    variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables>,
  ) =
    ExampleConnectorGeneratedMutationImpl(
      connector, operationName, dataDeserializer, variablesSerializer
    )

  @com.google.firebase.dataconnect.ExperimentalFirebaseDataConnect
  override fun <NewVariables> withVariablesSerializer(
    variablesSerializer: kotlinx.serialization.SerializationStrategy<NewVariables>
  ) =
    ExampleConnectorGeneratedMutationImpl(
      connector, operationName, dataDeserializer, variablesSerializer
    )

  @com.google.firebase.dataconnect.ExperimentalFirebaseDataConnect
  override fun <NewData> withDataDeserializer(
    dataDeserializer: kotlinx.serialization.DeserializationStrategy<NewData>
  ) =
    ExampleConnectorGeneratedMutationImpl(
      connector, operationName, dataDeserializer, variablesSerializer
    )

  override fun equals(other: Any?): Boolean =
    other is ExampleConnectorGeneratedMutationImpl<*,*> &&
    other.connector == connector &&
    other.operationName == operationName &&
    other.dataDeserializer == dataDeserializer &&
    other.variablesSerializer == variablesSerializer

  override fun hashCode(): Int =
    java.util.Objects.hash(
      "ExampleConnectorGeneratedMutationImpl",
      connector, operationName, dataDeserializer, variablesSerializer
    )

  override fun toString(): String =
    "ExampleConnectorGeneratedMutationImpl(" +
    "operationName=$operationName, " +
    "dataDeserializer=$dataDeserializer, " +
    "variablesSerializer=$variablesSerializer, " +
    "connector=$connector)"
}



private class FindUserByGoogleIdQueryImpl(
  connector: ExampleConnector
):
  FindUserByGoogleIdQuery,
  ExampleConnectorGeneratedQueryImpl<
      FindUserByGoogleIdQuery.Data,
      FindUserByGoogleIdQuery.Variables
  >(
    connector,
    FindUserByGoogleIdQuery.Companion.operationName,
    FindUserByGoogleIdQuery.Companion.dataDeserializer,
    FindUserByGoogleIdQuery.Companion.variablesSerializer,
  )


private class GetListenHistoryQueryImpl(
  connector: ExampleConnector
):
  GetListenHistoryQuery,
  ExampleConnectorGeneratedQueryImpl<
      GetListenHistoryQuery.Data,
      GetListenHistoryQuery.Variables
  >(
    connector,
    GetListenHistoryQuery.Companion.operationName,
    GetListenHistoryQuery.Companion.dataDeserializer,
    GetListenHistoryQuery.Companion.variablesSerializer,
  )


private class GetMySubscriptionsQueryImpl(
  connector: ExampleConnector
):
  GetMySubscriptionsQuery,
  ExampleConnectorGeneratedQueryImpl<
      GetMySubscriptionsQuery.Data,
      GetMySubscriptionsQuery.Variables
  >(
    connector,
    GetMySubscriptionsQuery.Companion.operationName,
    GetMySubscriptionsQuery.Companion.dataDeserializer,
    GetMySubscriptionsQuery.Companion.variablesSerializer,
  )


private class GetRecommendationsQueryImpl(
  connector: ExampleConnector
):
  GetRecommendationsQuery,
  ExampleConnectorGeneratedQueryImpl<
      GetRecommendationsQuery.Data,
      GetRecommendationsQuery.Variables
  >(
    connector,
    GetRecommendationsQuery.Companion.operationName,
    GetRecommendationsQuery.Companion.dataDeserializer,
    GetRecommendationsQuery.Companion.variablesSerializer,
  )


private class SubscribeToPodcastMutationImpl(
  connector: ExampleConnector
):
  SubscribeToPodcastMutation,
  ExampleConnectorGeneratedMutationImpl<
      SubscribeToPodcastMutation.Data,
      SubscribeToPodcastMutation.Variables
  >(
    connector,
    SubscribeToPodcastMutation.Companion.operationName,
    SubscribeToPodcastMutation.Companion.dataDeserializer,
    SubscribeToPodcastMutation.Companion.variablesSerializer,
  )


private class UnsubscribeFromPodcastMutationImpl(
  connector: ExampleConnector
):
  UnsubscribeFromPodcastMutation,
  ExampleConnectorGeneratedMutationImpl<
      UnsubscribeFromPodcastMutation.Data,
      UnsubscribeFromPodcastMutation.Variables
  >(
    connector,
    UnsubscribeFromPodcastMutation.Companion.operationName,
    UnsubscribeFromPodcastMutation.Companion.dataDeserializer,
    UnsubscribeFromPodcastMutation.Companion.variablesSerializer,
  )


private class UpdateListenHistoryMutationImpl(
  connector: ExampleConnector
):
  UpdateListenHistoryMutation,
  ExampleConnectorGeneratedMutationImpl<
      UpdateListenHistoryMutation.Data,
      UpdateListenHistoryMutation.Variables
  >(
    connector,
    UpdateListenHistoryMutation.Companion.operationName,
    UpdateListenHistoryMutation.Companion.dataDeserializer,
    UpdateListenHistoryMutation.Companion.variablesSerializer,
  )


private class UpdateSubscriptionOrderMutationImpl(
  connector: ExampleConnector
):
  UpdateSubscriptionOrderMutation,
  ExampleConnectorGeneratedMutationImpl<
      UpdateSubscriptionOrderMutation.Data,
      UpdateSubscriptionOrderMutation.Variables
  >(
    connector,
    UpdateSubscriptionOrderMutation.Companion.operationName,
    UpdateSubscriptionOrderMutation.Companion.dataDeserializer,
    UpdateSubscriptionOrderMutation.Companion.variablesSerializer,
  )


private class UpsertEpisodeMutationImpl(
  connector: ExampleConnector
):
  UpsertEpisodeMutation,
  ExampleConnectorGeneratedMutationImpl<
      UpsertEpisodeMutation.Data,
      UpsertEpisodeMutation.Variables
  >(
    connector,
    UpsertEpisodeMutation.Companion.operationName,
    UpsertEpisodeMutation.Companion.dataDeserializer,
    UpsertEpisodeMutation.Companion.variablesSerializer,
  )


private class UpsertPodcastMutationImpl(
  connector: ExampleConnector
):
  UpsertPodcastMutation,
  ExampleConnectorGeneratedMutationImpl<
      UpsertPodcastMutation.Data,
      UpsertPodcastMutation.Variables
  >(
    connector,
    UpsertPodcastMutation.Companion.operationName,
    UpsertPodcastMutation.Companion.dataDeserializer,
    UpsertPodcastMutation.Companion.variablesSerializer,
  )


private class UpsertUserMutationImpl(
  connector: ExampleConnector
):
  UpsertUserMutation,
  ExampleConnectorGeneratedMutationImpl<
      UpsertUserMutation.Data,
      UpsertUserMutation.Variables
  >(
    connector,
    UpsertUserMutation.Companion.operationName,
    UpsertUserMutation.Companion.dataDeserializer,
    UpsertUserMutation.Companion.variablesSerializer,
  )


