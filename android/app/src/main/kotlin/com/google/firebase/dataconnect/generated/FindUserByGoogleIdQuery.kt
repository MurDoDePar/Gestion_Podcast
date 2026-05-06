
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


public interface FindUserByGoogleIdQuery :
    com.google.firebase.dataconnect.generated.GeneratedQuery<
      ExampleConnector,
      FindUserByGoogleIdQuery.Data,
      FindUserByGoogleIdQuery.Variables
    >
{
  
    @kotlinx.serialization.Serializable
  public data class Variables(
  
    val googleId: String
  ) {
    
    
  }
  

  
    @kotlinx.serialization.Serializable
  public data class Data(
  
    val users: List<UsersItem>
  ) {
    
      
        @kotlinx.serialization.Serializable
  public data class UsersItem(
  
    val id: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID,
    val googleId: String,
    val displayName: String,
    val email: String?
  ) {
    
    
  }
      
    
    
  }
  

  public companion object {
    public val operationName: String = "FindUserByGoogleId"

    public val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data> =
      kotlinx.serialization.serializer()

    public val variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables> =
      kotlinx.serialization.serializer()
  }
}

public fun FindUserByGoogleIdQuery.ref(
  
    googleId: String,

  
  
): com.google.firebase.dataconnect.QueryRef<
    FindUserByGoogleIdQuery.Data,
    FindUserByGoogleIdQuery.Variables
  > =
  ref(
    
      FindUserByGoogleIdQuery.Variables(
        googleId=googleId,
  
      )
    
  )

public suspend fun FindUserByGoogleIdQuery.execute(

  
    
      googleId: String,
  fetchPolicy: com.google.firebase.dataconnect.QueryRef.FetchPolicy = com.google.firebase.dataconnect.QueryRef.FetchPolicy.PREFER_CACHE,
  

  ): com.google.firebase.dataconnect.QueryResult<
    FindUserByGoogleIdQuery.Data,
    FindUserByGoogleIdQuery.Variables
  > =
  ref(
    
      googleId=googleId,
  
    
  ).execute(fetchPolicy = fetchPolicy)


  public fun FindUserByGoogleIdQuery.flow(
    
      googleId: String,

  
    
    ): kotlinx.coroutines.flow.Flow<FindUserByGoogleIdQuery.Data> =
    ref(
        
          googleId=googleId,
  
        
      ).subscribe()
      .flow
      ._flow_map { querySubscriptionResult -> querySubscriptionResult.result.getOrNull() }
      ._flow_filterNotNull()
      ._flow_map { it.data }

