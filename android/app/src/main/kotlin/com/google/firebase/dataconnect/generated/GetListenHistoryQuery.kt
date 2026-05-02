
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


public interface GetListenHistoryQuery :
    com.google.firebase.dataconnect.generated.GeneratedQuery<
      ExampleConnector,
      GetListenHistoryQuery.Data,
      GetListenHistoryQuery.Variables
    >
{
  
    @kotlinx.serialization.Serializable
  public data class Variables(
  
    val userId: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID
  ) {
    
    
  }
  

  
    @kotlinx.serialization.Serializable
  public data class Data(
  
    val listenHistories: List<ListenHistoriesItem>
  ) {
    
      
        @kotlinx.serialization.Serializable
  public data class ListenHistoriesItem(
  
    val episode: Episode,
    val progressSeconds: Long,
    val finishedListening: Boolean?
  ) {
    
      
        @kotlinx.serialization.Serializable
  public data class Episode(
  
    val id: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID,
    val audioUrl: String
  ) {
    
    
  }
      
    
    
  }
      
    
    
  }
  

  public companion object {
    public val operationName: String = "GetListenHistory"

    public val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data> =
      kotlinx.serialization.serializer()

    public val variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables> =
      kotlinx.serialization.serializer()
  }
}

public fun GetListenHistoryQuery.ref(
  
    userId: java.util.UUID,

  
  
): com.google.firebase.dataconnect.QueryRef<
    GetListenHistoryQuery.Data,
    GetListenHistoryQuery.Variables
  > =
  ref(
    
      GetListenHistoryQuery.Variables(
        userId=userId,
  
      )
    
  )

public suspend fun GetListenHistoryQuery.execute(

  
    
      userId: java.util.UUID,
  fetchPolicy: com.google.firebase.dataconnect.QueryRef.FetchPolicy = com.google.firebase.dataconnect.QueryRef.FetchPolicy.PREFER_CACHE,
  

  ): com.google.firebase.dataconnect.QueryResult<
    GetListenHistoryQuery.Data,
    GetListenHistoryQuery.Variables
  > =
  ref(
    
      userId=userId,
  
    
  ).execute(fetchPolicy = fetchPolicy)


  public fun GetListenHistoryQuery.flow(
    
      userId: java.util.UUID,

  
    
    ): kotlinx.coroutines.flow.Flow<GetListenHistoryQuery.Data> =
    ref(
        
          userId=userId,
  
        
      ).subscribe()
      .flow
      ._flow_map { querySubscriptionResult -> querySubscriptionResult.result.getOrNull() }
      ._flow_filterNotNull()
      ._flow_map { it.data }

