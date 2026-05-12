
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


public interface GetPodcastByFeedUrlQuery :
    com.google.firebase.dataconnect.generated.GeneratedQuery<
      ExampleConnector,
      GetPodcastByFeedUrlQuery.Data,
      GetPodcastByFeedUrlQuery.Variables
    >
{
  
    @kotlinx.serialization.Serializable
  public data class Variables(
  
    val feedUrl: String
  ) {
    
    
  }
  

  
    @kotlinx.serialization.Serializable
  public data class Data(
  
    val podcasts: List<PodcastsItem>
  ) {
    
      
        @kotlinx.serialization.Serializable
  public data class PodcastsItem(
  
    val id: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID,
    val title: String,
    val feedUrl: String,
    val imageUrl: String?
  ) {
    
    
  }
      
    
    
  }
  

  public companion object {
    public val operationName: String = "GetPodcastByFeedUrl"

    public val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data> =
      kotlinx.serialization.serializer()

    public val variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables> =
      kotlinx.serialization.serializer()
  }
}

public fun GetPodcastByFeedUrlQuery.ref(
  
    feedUrl: String,

  
  
): com.google.firebase.dataconnect.QueryRef<
    GetPodcastByFeedUrlQuery.Data,
    GetPodcastByFeedUrlQuery.Variables
  > =
  ref(
    
      GetPodcastByFeedUrlQuery.Variables(
        feedUrl=feedUrl,
  
      )
    
  )

public suspend fun GetPodcastByFeedUrlQuery.execute(

  
    
      feedUrl: String,
  fetchPolicy: com.google.firebase.dataconnect.QueryRef.FetchPolicy = com.google.firebase.dataconnect.QueryRef.FetchPolicy.PREFER_CACHE,
  

  ): com.google.firebase.dataconnect.QueryResult<
    GetPodcastByFeedUrlQuery.Data,
    GetPodcastByFeedUrlQuery.Variables
  > =
  ref(
    
      feedUrl=feedUrl,
  
    
  ).execute(fetchPolicy = fetchPolicy)


  public fun GetPodcastByFeedUrlQuery.flow(
    
      feedUrl: String,

  
    
    ): kotlinx.coroutines.flow.Flow<GetPodcastByFeedUrlQuery.Data> =
    ref(
        
          feedUrl=feedUrl,
  
        
      ).subscribe()
      .flow
      ._flow_map { querySubscriptionResult -> querySubscriptionResult.result.getOrNull() }
      ._flow_filterNotNull()
      ._flow_map { it.data }

