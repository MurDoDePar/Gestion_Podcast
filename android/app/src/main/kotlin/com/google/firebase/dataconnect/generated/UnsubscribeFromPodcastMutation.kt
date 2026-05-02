
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



public interface UnsubscribeFromPodcastMutation :
    com.google.firebase.dataconnect.generated.GeneratedMutation<
      ExampleConnector,
      UnsubscribeFromPodcastMutation.Data,
      UnsubscribeFromPodcastMutation.Variables
    >
{
  
    @kotlinx.serialization.Serializable
  public data class Variables(
  
    val userId: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID,
    val podcastId: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID
  ) {
    
    
  }
  

  
    @kotlinx.serialization.Serializable
  public data class Data(
  
    val subscriptionType_delete: SubscriptionTypeKey?
  ) {
    
    
  }
  

  public companion object {
    public val operationName: String = "UnsubscribeFromPodcast"

    public val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data> =
      kotlinx.serialization.serializer()

    public val variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables> =
      kotlinx.serialization.serializer()
  }
}

public fun UnsubscribeFromPodcastMutation.ref(
  
    userId: java.util.UUID,podcastId: java.util.UUID,

  
  
): com.google.firebase.dataconnect.MutationRef<
    UnsubscribeFromPodcastMutation.Data,
    UnsubscribeFromPodcastMutation.Variables
  > =
  ref(
    
      UnsubscribeFromPodcastMutation.Variables(
        userId=userId,podcastId=podcastId,
  
      )
    
  )

public suspend fun UnsubscribeFromPodcastMutation.execute(

  
    
      userId: java.util.UUID,podcastId: java.util.UUID,

  

  ): com.google.firebase.dataconnect.MutationResult<
    UnsubscribeFromPodcastMutation.Data,
    UnsubscribeFromPodcastMutation.Variables
  > =
  ref(
    
      userId=userId,podcastId=podcastId,
  
    
  ).execute()


