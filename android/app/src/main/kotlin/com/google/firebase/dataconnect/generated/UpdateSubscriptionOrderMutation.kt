
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



public interface UpdateSubscriptionOrderMutation :
    com.google.firebase.dataconnect.generated.GeneratedMutation<
      ExampleConnector,
      UpdateSubscriptionOrderMutation.Data,
      UpdateSubscriptionOrderMutation.Variables
    >
{
  
    @kotlinx.serialization.Serializable
  public data class Variables(
  
    val userId: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID,
    val podcastId: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID,
    val listOrder: Int
  ) {
    
    
  }
  

  
    @kotlinx.serialization.Serializable
  public data class Data(
  
    val subscriptionType_update: SubscriptionTypeKey?
  ) {
    
    
  }
  

  public companion object {
    public val operationName: String = "UpdateSubscriptionOrder"

    public val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data> =
      kotlinx.serialization.serializer()

    public val variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables> =
      kotlinx.serialization.serializer()
  }
}

public fun UpdateSubscriptionOrderMutation.ref(
  
    userId: java.util.UUID,podcastId: java.util.UUID,listOrder: Int,

  
  
): com.google.firebase.dataconnect.MutationRef<
    UpdateSubscriptionOrderMutation.Data,
    UpdateSubscriptionOrderMutation.Variables
  > =
  ref(
    
      UpdateSubscriptionOrderMutation.Variables(
        userId=userId,podcastId=podcastId,listOrder=listOrder,
  
      )
    
  )

public suspend fun UpdateSubscriptionOrderMutation.execute(

  
    
      userId: java.util.UUID,podcastId: java.util.UUID,listOrder: Int,

  

  ): com.google.firebase.dataconnect.MutationResult<
    UpdateSubscriptionOrderMutation.Data,
    UpdateSubscriptionOrderMutation.Variables
  > =
  ref(
    
      userId=userId,podcastId=podcastId,listOrder=listOrder,
  
    
  ).execute()


