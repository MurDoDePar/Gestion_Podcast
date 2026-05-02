
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



public interface SubscribeToPodcastMutation :
    com.google.firebase.dataconnect.generated.GeneratedMutation<
      ExampleConnector,
      SubscribeToPodcastMutation.Data,
      SubscribeToPodcastMutation.Variables
    >
{
  
    @kotlinx.serialization.Serializable
  public data class Variables(
  
    val userId: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID,
    val podcastId: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID,
    val subscribedAt: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.TimestampSerializer::class) com.google.firebase.Timestamp,
    val listOrder: com.google.firebase.dataconnect.OptionalVariable<Int?>
  ) {
    
    
      
      @kotlin.DslMarker public annotation class BuilderDsl

      @BuilderDsl
      public interface Builder {
        public var userId: java.util.UUID
        public var podcastId: java.util.UUID
        public var subscribedAt: com.google.firebase.Timestamp
        public var listOrder: Int?
        
      }

      public companion object {
        @Suppress("NAME_SHADOWING")
        public fun build(
          userId: java.util.UUID,podcastId: java.util.UUID,subscribedAt: com.google.firebase.Timestamp,
          block_: Builder.() -> Unit
        ): Variables {
          var userId= userId
            var podcastId= podcastId
            var subscribedAt= subscribedAt
            var listOrder: com.google.firebase.dataconnect.OptionalVariable<Int?> =
                com.google.firebase.dataconnect.OptionalVariable.Undefined
            

          return object : Builder {
            override var userId: java.util.UUID
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { userId = value_ }
              
            override var podcastId: java.util.UUID
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { podcastId = value_ }
              
            override var subscribedAt: com.google.firebase.Timestamp
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { subscribedAt = value_ }
              
            override var listOrder: Int?
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { listOrder = com.google.firebase.dataconnect.OptionalVariable.Value(value_) }
              
            
          }.apply(block_)
          .let {
            Variables(
              userId=userId,podcastId=podcastId,subscribedAt=subscribedAt,listOrder=listOrder,
            )
          }
        }
      }
    
  }
  

  
    @kotlinx.serialization.Serializable
  public data class Data(
  
    val subscriptionType_upsert: SubscriptionTypeKey
  ) {
    
    
  }
  

  public companion object {
    public val operationName: String = "SubscribeToPodcast"

    public val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data> =
      kotlinx.serialization.serializer()

    public val variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables> =
      kotlinx.serialization.serializer()
  }
}

public fun SubscribeToPodcastMutation.ref(
  
    userId: java.util.UUID,podcastId: java.util.UUID,subscribedAt: com.google.firebase.Timestamp,

  
    block_: SubscribeToPodcastMutation.Variables.Builder.() -> Unit = {}
  
): com.google.firebase.dataconnect.MutationRef<
    SubscribeToPodcastMutation.Data,
    SubscribeToPodcastMutation.Variables
  > =
  ref(
    
      SubscribeToPodcastMutation.Variables.build(
        userId=userId,podcastId=podcastId,subscribedAt=subscribedAt,
  
    block_
      )
    
  )

public suspend fun SubscribeToPodcastMutation.execute(

  
    
      userId: java.util.UUID,podcastId: java.util.UUID,subscribedAt: com.google.firebase.Timestamp,

  
    block_: SubscribeToPodcastMutation.Variables.Builder.() -> Unit = {}

  ): com.google.firebase.dataconnect.MutationResult<
    SubscribeToPodcastMutation.Data,
    SubscribeToPodcastMutation.Variables
  > =
  ref(
    
      userId=userId,podcastId=podcastId,subscribedAt=subscribedAt,
  
    block_
    
  ).execute()


