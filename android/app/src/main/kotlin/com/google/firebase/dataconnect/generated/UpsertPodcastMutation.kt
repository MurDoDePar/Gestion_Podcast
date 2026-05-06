
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



public interface UpsertPodcastMutation :
    com.google.firebase.dataconnect.generated.GeneratedMutation<
      ExampleConnector,
      UpsertPodcastMutation.Data,
      UpsertPodcastMutation.Variables
    >
{
  
    @kotlinx.serialization.Serializable
  public data class Variables(
  
    val id: com.google.firebase.dataconnect.OptionalVariable<@kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID?>,
    val title: String,
    val feedUrl: String,
    val description: com.google.firebase.dataconnect.OptionalVariable<String?>,
    val imageUrl: com.google.firebase.dataconnect.OptionalVariable<String?>,
    val author: com.google.firebase.dataconnect.OptionalVariable<String?>,
    val categories: com.google.firebase.dataconnect.OptionalVariable<List<String>?>,
    val createdAt: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.TimestampSerializer::class) com.google.firebase.Timestamp
  ) {
    
    
      
      @kotlin.DslMarker public annotation class BuilderDsl

      @BuilderDsl
      public interface Builder {
        public var id: java.util.UUID?
        public var title: String
        public var feedUrl: String
        public var description: String?
        public var imageUrl: String?
        public var author: String?
        public var categories: List<String>?
        public var createdAt: com.google.firebase.Timestamp
        
      }

      public companion object {
        @Suppress("NAME_SHADOWING")
        public fun build(
          title: String,feedUrl: String,createdAt: com.google.firebase.Timestamp,
          block_: Builder.() -> Unit
        ): Variables {
          var id: com.google.firebase.dataconnect.OptionalVariable<java.util.UUID?> =
                com.google.firebase.dataconnect.OptionalVariable.Undefined
            var title= title
            var feedUrl= feedUrl
            var description: com.google.firebase.dataconnect.OptionalVariable<String?> =
                com.google.firebase.dataconnect.OptionalVariable.Undefined
            var imageUrl: com.google.firebase.dataconnect.OptionalVariable<String?> =
                com.google.firebase.dataconnect.OptionalVariable.Undefined
            var author: com.google.firebase.dataconnect.OptionalVariable<String?> =
                com.google.firebase.dataconnect.OptionalVariable.Undefined
            var categories: com.google.firebase.dataconnect.OptionalVariable<List<String>?> =
                com.google.firebase.dataconnect.OptionalVariable.Undefined
            var createdAt= createdAt
            

          return object : Builder {
            override var id: java.util.UUID?
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { id = com.google.firebase.dataconnect.OptionalVariable.Value(value_) }
              
            override var title: String
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { title = value_ }
              
            override var feedUrl: String
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { feedUrl = value_ }
              
            override var description: String?
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { description = com.google.firebase.dataconnect.OptionalVariable.Value(value_) }
              
            override var imageUrl: String?
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { imageUrl = com.google.firebase.dataconnect.OptionalVariable.Value(value_) }
              
            override var author: String?
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { author = com.google.firebase.dataconnect.OptionalVariable.Value(value_) }
              
            override var categories: List<String>?
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { categories = com.google.firebase.dataconnect.OptionalVariable.Value(value_) }
              
            override var createdAt: com.google.firebase.Timestamp
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { createdAt = value_ }
              
            
          }.apply(block_)
          .let {
            Variables(
              id=id,title=title,feedUrl=feedUrl,description=description,imageUrl=imageUrl,author=author,categories=categories,createdAt=createdAt,
            )
          }
        }
      }
    
  }
  

  
    @kotlinx.serialization.Serializable
  public data class Data(
  
    val podcast_upsert: PodcastKey
  ) {
    
    
  }
  

  public companion object {
    public val operationName: String = "UpsertPodcast"

    public val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data> =
      kotlinx.serialization.serializer()

    public val variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables> =
      kotlinx.serialization.serializer()
  }
}

public fun UpsertPodcastMutation.ref(
  
    title: String,feedUrl: String,createdAt: com.google.firebase.Timestamp,

  
    block_: UpsertPodcastMutation.Variables.Builder.() -> Unit = {}
  
): com.google.firebase.dataconnect.MutationRef<
    UpsertPodcastMutation.Data,
    UpsertPodcastMutation.Variables
  > =
  ref(
    
      UpsertPodcastMutation.Variables.build(
        title=title,feedUrl=feedUrl,createdAt=createdAt,
  
    block_
      )
    
  )

public suspend fun UpsertPodcastMutation.execute(

  
    
      title: String,feedUrl: String,createdAt: com.google.firebase.Timestamp,

  
    block_: UpsertPodcastMutation.Variables.Builder.() -> Unit = {}

  ): com.google.firebase.dataconnect.MutationResult<
    UpsertPodcastMutation.Data,
    UpsertPodcastMutation.Variables
  > =
  ref(
    
      title=title,feedUrl=feedUrl,createdAt=createdAt,
  
    block_
    
  ).execute()


