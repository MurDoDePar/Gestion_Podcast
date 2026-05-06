
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


import kotlinx.coroutines.flow.filterNotNull as _flow_filterNotNull
import kotlinx.coroutines.flow.map as _flow_map


public interface GetLatestSubscribedEpisodesQuery :
    com.google.firebase.dataconnect.generated.GeneratedQuery<
      ExampleConnector,
      GetLatestSubscribedEpisodesQuery.Data,
      GetLatestSubscribedEpisodesQuery.Variables
    >
{
  
    @kotlinx.serialization.Serializable
  public data class Variables(
  
    val userId: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID
  ) {
    
    
  }
  

  
    @kotlinx.serialization.Serializable
  public data class Data(
  
    val subscriptionTypes: List<SubscriptionTypesItem>
  ) {
    
      
        @kotlinx.serialization.Serializable
  public data class SubscriptionTypesItem(
  
    val listOrder: Int?,
    val podcast: Podcast
  ) {
    
      
        @kotlinx.serialization.Serializable
  public data class Podcast(
  
    val id: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID,
    val title: String,
    val imageUrl: String?,
    val episodes_on_podcast: List<EpisodesOnPodcastItem>
  ) {
    
      
        @kotlinx.serialization.Serializable
  public data class EpisodesOnPodcastItem(
  
    val id: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID,
    val title: String,
    val audioUrl: String,
    val publishedAt: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.TimestampSerializer::class) com.google.firebase.Timestamp,
    val imageUrl: String?
  ) {
    
    
  }
      
    
    
  }
      
    
    
  }
      
    
    
  }
  

  public companion object {
    public val operationName: String = "GetLatestSubscribedEpisodes"

    public val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data> =
      kotlinx.serialization.serializer()

    public val variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables> =
      kotlinx.serialization.serializer()
  }
}

public fun GetLatestSubscribedEpisodesQuery.ref(
  
    userId: java.util.UUID,

  
  
): com.google.firebase.dataconnect.QueryRef<
    GetLatestSubscribedEpisodesQuery.Data,
    GetLatestSubscribedEpisodesQuery.Variables
  > =
  ref(
    
      GetLatestSubscribedEpisodesQuery.Variables(
        userId=userId,
  
      )
    
  )

public suspend fun GetLatestSubscribedEpisodesQuery.execute(

  
    
      userId: java.util.UUID,
  fetchPolicy: com.google.firebase.dataconnect.QueryRef.FetchPolicy = com.google.firebase.dataconnect.QueryRef.FetchPolicy.PREFER_CACHE,
  

  ): com.google.firebase.dataconnect.QueryResult<
    GetLatestSubscribedEpisodesQuery.Data,
    GetLatestSubscribedEpisodesQuery.Variables
  > =
  ref(
    
      userId=userId,
  
    
  ).execute(fetchPolicy = fetchPolicy)


  public fun GetLatestSubscribedEpisodesQuery.flow(
    
      userId: java.util.UUID,

  
    
    ): kotlinx.coroutines.flow.Flow<GetLatestSubscribedEpisodesQuery.Data> =
    ref(
        
          userId=userId,
  
        
      ).subscribe()
      .flow
      ._flow_map { querySubscriptionResult -> querySubscriptionResult.result.getOrNull() }
      ._flow_filterNotNull()
      ._flow_map { it.data }

