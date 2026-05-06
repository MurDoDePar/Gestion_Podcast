
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


public interface GetMySubscriptionsQuery :
    com.google.firebase.dataconnect.generated.GeneratedQuery<
      ExampleConnector,
      GetMySubscriptionsQuery.Data,
      GetMySubscriptionsQuery.Variables
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
    val feedUrl: String,
    val imageUrl: String?,
    val author: String?,
    val categories: List<String>?
  ) {
    
    
  }
      
    
    
  }
      
    
    
  }
  

  public companion object {
    public val operationName: String = "GetMySubscriptions"

    public val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data> =
      kotlinx.serialization.serializer()

    public val variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables> =
      kotlinx.serialization.serializer()
  }
}

public fun GetMySubscriptionsQuery.ref(
  
    userId: java.util.UUID,

  
  
): com.google.firebase.dataconnect.QueryRef<
    GetMySubscriptionsQuery.Data,
    GetMySubscriptionsQuery.Variables
  > =
  ref(
    
      GetMySubscriptionsQuery.Variables(
        userId=userId,
  
      )
    
  )

public suspend fun GetMySubscriptionsQuery.execute(

  
    
      userId: java.util.UUID,
  fetchPolicy: com.google.firebase.dataconnect.QueryRef.FetchPolicy = com.google.firebase.dataconnect.QueryRef.FetchPolicy.PREFER_CACHE,
  

  ): com.google.firebase.dataconnect.QueryResult<
    GetMySubscriptionsQuery.Data,
    GetMySubscriptionsQuery.Variables
  > =
  ref(
    
      userId=userId,
  
    
  ).execute(fetchPolicy = fetchPolicy)


  public fun GetMySubscriptionsQuery.flow(
    
      userId: java.util.UUID,

  
    
    ): kotlinx.coroutines.flow.Flow<GetMySubscriptionsQuery.Data> =
    ref(
        
          userId=userId,
  
        
      ).subscribe()
      .flow
      ._flow_map { querySubscriptionResult -> querySubscriptionResult.result.getOrNull() }
      ._flow_filterNotNull()
      ._flow_map { it.data }

