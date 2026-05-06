
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


public interface GetEpisodesByPodcastQuery :
    com.google.firebase.dataconnect.generated.GeneratedQuery<
      ExampleConnector,
      GetEpisodesByPodcastQuery.Data,
      GetEpisodesByPodcastQuery.Variables
    >
{
  
    @kotlinx.serialization.Serializable
  public data class Variables(
  
    val podcastId: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID
  ) {
    
    
  }
  

  
    @kotlinx.serialization.Serializable
  public data class Data(
  
    val episodes: List<EpisodesItem>
  ) {
    
      
        @kotlinx.serialization.Serializable
  public data class EpisodesItem(
  
    val id: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID,
    val title: String,
    val audioUrl: String,
    val duration: Long,
    val description: String?,
    val imageUrl: String?,
    val publishedAt: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.TimestampSerializer::class) com.google.firebase.Timestamp
  ) {
    
    
  }
      
    
    
  }
  

  public companion object {
    public val operationName: String = "GetEpisodesByPodcast"

    public val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data> =
      kotlinx.serialization.serializer()

    public val variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables> =
      kotlinx.serialization.serializer()
  }
}

public fun GetEpisodesByPodcastQuery.ref(
  
    podcastId: java.util.UUID,

  
  
): com.google.firebase.dataconnect.QueryRef<
    GetEpisodesByPodcastQuery.Data,
    GetEpisodesByPodcastQuery.Variables
  > =
  ref(
    
      GetEpisodesByPodcastQuery.Variables(
        podcastId=podcastId,
  
      )
    
  )

public suspend fun GetEpisodesByPodcastQuery.execute(

  
    
      podcastId: java.util.UUID,
  fetchPolicy: com.google.firebase.dataconnect.QueryRef.FetchPolicy = com.google.firebase.dataconnect.QueryRef.FetchPolicy.PREFER_CACHE,
  

  ): com.google.firebase.dataconnect.QueryResult<
    GetEpisodesByPodcastQuery.Data,
    GetEpisodesByPodcastQuery.Variables
  > =
  ref(
    
      podcastId=podcastId,
  
    
  ).execute(fetchPolicy = fetchPolicy)


  public fun GetEpisodesByPodcastQuery.flow(
    
      podcastId: java.util.UUID,

  
    
    ): kotlinx.coroutines.flow.Flow<GetEpisodesByPodcastQuery.Data> =
    ref(
        
          podcastId=podcastId,
  
        
      ).subscribe()
      .flow
      ._flow_map { querySubscriptionResult -> querySubscriptionResult.result.getOrNull() }
      ._flow_filterNotNull()
      ._flow_map { it.data }

