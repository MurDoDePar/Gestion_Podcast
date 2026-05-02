
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



public interface UpsertEpisodeMutation :
    com.google.firebase.dataconnect.generated.GeneratedMutation<
      ExampleConnector,
      UpsertEpisodeMutation.Data,
      UpsertEpisodeMutation.Variables
    >
{
  
    @kotlinx.serialization.Serializable
  public data class Variables(
  
    val id: com.google.firebase.dataconnect.OptionalVariable<@kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID?>,
    val podcastId: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID,
    val title: String,
    val audioUrl: String,
    val duration: Long,
    val description: com.google.firebase.dataconnect.OptionalVariable<String?>,
    val imageUrl: com.google.firebase.dataconnect.OptionalVariable<String?>,
    val publishedAt: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.TimestampSerializer::class) com.google.firebase.Timestamp
  ) {
    
    
      
      @kotlin.DslMarker public annotation class BuilderDsl

      @BuilderDsl
      public interface Builder {
        public var id: java.util.UUID?
        public var podcastId: java.util.UUID
        public var title: String
        public var audioUrl: String
        public var duration: Long
        public var description: String?
        public var imageUrl: String?
        public var publishedAt: com.google.firebase.Timestamp
        
      }

      public companion object {
        @Suppress("NAME_SHADOWING")
        public fun build(
          podcastId: java.util.UUID,title: String,audioUrl: String,duration: Long,publishedAt: com.google.firebase.Timestamp,
          block_: Builder.() -> Unit
        ): Variables {
          var id: com.google.firebase.dataconnect.OptionalVariable<java.util.UUID?> =
                com.google.firebase.dataconnect.OptionalVariable.Undefined
            var podcastId= podcastId
            var title= title
            var audioUrl= audioUrl
            var duration= duration
            var description: com.google.firebase.dataconnect.OptionalVariable<String?> =
                com.google.firebase.dataconnect.OptionalVariable.Undefined
            var imageUrl: com.google.firebase.dataconnect.OptionalVariable<String?> =
                com.google.firebase.dataconnect.OptionalVariable.Undefined
            var publishedAt= publishedAt
            

          return object : Builder {
            override var id: java.util.UUID?
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { id = com.google.firebase.dataconnect.OptionalVariable.Value(value_) }
              
            override var podcastId: java.util.UUID
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { podcastId = value_ }
              
            override var title: String
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { title = value_ }
              
            override var audioUrl: String
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { audioUrl = value_ }
              
            override var duration: Long
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { duration = value_ }
              
            override var description: String?
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { description = com.google.firebase.dataconnect.OptionalVariable.Value(value_) }
              
            override var imageUrl: String?
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { imageUrl = com.google.firebase.dataconnect.OptionalVariable.Value(value_) }
              
            override var publishedAt: com.google.firebase.Timestamp
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { publishedAt = value_ }
              
            
          }.apply(block_)
          .let {
            Variables(
              id=id,podcastId=podcastId,title=title,audioUrl=audioUrl,duration=duration,description=description,imageUrl=imageUrl,publishedAt=publishedAt,
            )
          }
        }
      }
    
  }
  

  
    @kotlinx.serialization.Serializable
  public data class Data(
  
    val episode_upsert: EpisodeKey
  ) {
    
    
  }
  

  public companion object {
    public val operationName: String = "UpsertEpisode"

    public val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data> =
      kotlinx.serialization.serializer()

    public val variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables> =
      kotlinx.serialization.serializer()
  }
}

public fun UpsertEpisodeMutation.ref(
  
    podcastId: java.util.UUID,title: String,audioUrl: String,duration: Long,publishedAt: com.google.firebase.Timestamp,

  
    block_: UpsertEpisodeMutation.Variables.Builder.() -> Unit = {}
  
): com.google.firebase.dataconnect.MutationRef<
    UpsertEpisodeMutation.Data,
    UpsertEpisodeMutation.Variables
  > =
  ref(
    
      UpsertEpisodeMutation.Variables.build(
        podcastId=podcastId,title=title,audioUrl=audioUrl,duration=duration,publishedAt=publishedAt,
  
    block_
      )
    
  )

public suspend fun UpsertEpisodeMutation.execute(

  
    
      podcastId: java.util.UUID,title: String,audioUrl: String,duration: Long,publishedAt: com.google.firebase.Timestamp,

  
    block_: UpsertEpisodeMutation.Variables.Builder.() -> Unit = {}

  ): com.google.firebase.dataconnect.MutationResult<
    UpsertEpisodeMutation.Data,
    UpsertEpisodeMutation.Variables
  > =
  ref(
    
      podcastId=podcastId,title=title,audioUrl=audioUrl,duration=duration,publishedAt=publishedAt,
  
    block_
    
  ).execute()


