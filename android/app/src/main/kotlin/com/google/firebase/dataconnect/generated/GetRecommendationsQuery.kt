
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


public interface GetRecommendationsQuery :
    com.google.firebase.dataconnect.generated.GeneratedQuery<
      ExampleConnector,
      GetRecommendationsQuery.Data,
      GetRecommendationsQuery.Variables
    >
{
  
    @kotlinx.serialization.Serializable
  public data class Variables(
  
    val podcastId: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID
  ) {
    
    
  }
  

  
    @kotlinx.serialization.Serializable
  public data class Data(
  
    val subscriptionTypes: List<SubscriptionTypesItem>
  ) {
    
      
        @kotlinx.serialization.Serializable
  public data class SubscriptionTypesItem(
  
    val user: User
  ) {
    
      
        @kotlinx.serialization.Serializable
  public data class User(
  
    val subscriptionTypes_on_user: List<SubscriptionTypesOnUserItem>
  ) {
    
      
        @kotlinx.serialization.Serializable
  public data class SubscriptionTypesOnUserItem(
  
    val podcast: Podcast
  ) {
    
      
        @kotlinx.serialization.Serializable
  public data class Podcast(
  
    val id: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID,
    val title: String,
    val imageUrl: String?,
    val feedUrl: String,
    val author: String?,
    val categories: List<String>?
  ) {
    
    
  }
      
    
    
  }
      
    
    
  }
      
    
    
  }
      
    
    
  }
  

  public companion object {
    public val operationName: String = "GetRecommendations"

    public val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data> =
      kotlinx.serialization.serializer()

    public val variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables> =
      kotlinx.serialization.serializer()
  }
}

public fun GetRecommendationsQuery.ref(
  
    podcastId: java.util.UUID,

  
  
): com.google.firebase.dataconnect.QueryRef<
    GetRecommendationsQuery.Data,
    GetRecommendationsQuery.Variables
  > =
  ref(
    
      GetRecommendationsQuery.Variables(
        podcastId=podcastId,
  
      )
    
  )

public suspend fun GetRecommendationsQuery.execute(

  
    
      podcastId: java.util.UUID,
  fetchPolicy: com.google.firebase.dataconnect.QueryRef.FetchPolicy = com.google.firebase.dataconnect.QueryRef.FetchPolicy.PREFER_CACHE,
  

  ): com.google.firebase.dataconnect.QueryResult<
    GetRecommendationsQuery.Data,
    GetRecommendationsQuery.Variables
  > =
  ref(
    
      podcastId=podcastId,
  
    
  ).execute(fetchPolicy = fetchPolicy)


  public fun GetRecommendationsQuery.flow(
    
      podcastId: java.util.UUID,

  
    
    ): kotlinx.coroutines.flow.Flow<GetRecommendationsQuery.Data> =
    ref(
        
          podcastId=podcastId,
  
        
      ).subscribe()
      .flow
      ._flow_map { querySubscriptionResult -> querySubscriptionResult.result.getOrNull() }
      ._flow_filterNotNull()
      ._flow_map { it.data }

