
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



public interface UpdateListenHistoryMutation :
    com.google.firebase.dataconnect.generated.GeneratedMutation<
      ExampleConnector,
      UpdateListenHistoryMutation.Data,
      UpdateListenHistoryMutation.Variables
    >
{
  
    @kotlinx.serialization.Serializable
  public data class Variables(
  
    val userId: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID,
    val episodeId: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID,
    val progressSeconds: Long,
    val finishedListening: Boolean,
    val listenedAt: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.TimestampSerializer::class) com.google.firebase.Timestamp
  ) {
    
    
  }
  

  
    @kotlinx.serialization.Serializable
  public data class Data(
  
    val listenHistory_upsert: ListenHistoryKey
  ) {
    
    
  }
  

  public companion object {
    public val operationName: String = "UpdateListenHistory"

    public val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data> =
      kotlinx.serialization.serializer()

    public val variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables> =
      kotlinx.serialization.serializer()
  }
}

public fun UpdateListenHistoryMutation.ref(
  
    userId: java.util.UUID,episodeId: java.util.UUID,progressSeconds: Long,finishedListening: Boolean,listenedAt: com.google.firebase.Timestamp,

  
  
): com.google.firebase.dataconnect.MutationRef<
    UpdateListenHistoryMutation.Data,
    UpdateListenHistoryMutation.Variables
  > =
  ref(
    
      UpdateListenHistoryMutation.Variables(
        userId=userId,episodeId=episodeId,progressSeconds=progressSeconds,finishedListening=finishedListening,listenedAt=listenedAt,
  
      )
    
  )

public suspend fun UpdateListenHistoryMutation.execute(

  
    
      userId: java.util.UUID,episodeId: java.util.UUID,progressSeconds: Long,finishedListening: Boolean,listenedAt: com.google.firebase.Timestamp,

  

  ): com.google.firebase.dataconnect.MutationResult<
    UpdateListenHistoryMutation.Data,
    UpdateListenHistoryMutation.Variables
  > =
  ref(
    
      userId=userId,episodeId=episodeId,progressSeconds=progressSeconds,finishedListening=finishedListening,listenedAt=listenedAt,
  
    
  ).execute()


