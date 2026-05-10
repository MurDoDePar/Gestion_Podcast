
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



public interface UpsertAppCacheMutation :
    com.google.firebase.dataconnect.generated.GeneratedMutation<
      ExampleConnector,
      UpsertAppCacheMutation.Data,
      UpsertAppCacheMutation.Variables
    >
{
  
    @kotlinx.serialization.Serializable
  public data class Variables(
  
    val id: String,
    val data: com.google.firebase.dataconnect.AnyValue,
    val updatedAt: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.TimestampSerializer::class) com.google.firebase.Timestamp
  ) {
    
    
  }
  

  
    @kotlinx.serialization.Serializable
  public data class Data(
  
    val appCache_upsert: AppCacheKey
  ) {
    
    
  }
  

  public companion object {
    public val operationName: String = "UpsertAppCache"

    public val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data> =
      kotlinx.serialization.serializer()

    public val variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables> =
      kotlinx.serialization.serializer()
  }
}

public fun UpsertAppCacheMutation.ref(
  
    id: String,data: com.google.firebase.dataconnect.AnyValue,updatedAt: com.google.firebase.Timestamp,

  
  
): com.google.firebase.dataconnect.MutationRef<
    UpsertAppCacheMutation.Data,
    UpsertAppCacheMutation.Variables
  > =
  ref(
    
      UpsertAppCacheMutation.Variables(
        id=id,data=data,updatedAt=updatedAt,
  
      )
    
  )

public suspend fun UpsertAppCacheMutation.execute(

  
    
      id: String,data: com.google.firebase.dataconnect.AnyValue,updatedAt: com.google.firebase.Timestamp,

  

  ): com.google.firebase.dataconnect.MutationResult<
    UpsertAppCacheMutation.Data,
    UpsertAppCacheMutation.Variables
  > =
  ref(
    
      id=id,data=data,updatedAt=updatedAt,
  
    
  ).execute()


