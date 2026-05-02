
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



public interface UpsertUserMutation :
    com.google.firebase.dataconnect.generated.GeneratedMutation<
      ExampleConnector,
      UpsertUserMutation.Data,
      UpsertUserMutation.Variables
    >
{
  
    @kotlinx.serialization.Serializable
  public data class Variables(
  
    val id: com.google.firebase.dataconnect.OptionalVariable<@kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.UUIDSerializer::class) java.util.UUID?>,
    val googleId: String,
    val displayName: String,
    val email: com.google.firebase.dataconnect.OptionalVariable<String?>,
    val photoUrl: com.google.firebase.dataconnect.OptionalVariable<String?>,
    val createdAt: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.TimestampSerializer::class) com.google.firebase.Timestamp
  ) {
    
    
      
      @kotlin.DslMarker public annotation class BuilderDsl

      @BuilderDsl
      public interface Builder {
        public var id: java.util.UUID?
        public var googleId: String
        public var displayName: String
        public var email: String?
        public var photoUrl: String?
        public var createdAt: com.google.firebase.Timestamp
        
      }

      public companion object {
        @Suppress("NAME_SHADOWING")
        public fun build(
          googleId: String,displayName: String,createdAt: com.google.firebase.Timestamp,
          block_: Builder.() -> Unit
        ): Variables {
          var id: com.google.firebase.dataconnect.OptionalVariable<java.util.UUID?> =
                com.google.firebase.dataconnect.OptionalVariable.Undefined
            var googleId= googleId
            var displayName= displayName
            var email: com.google.firebase.dataconnect.OptionalVariable<String?> =
                com.google.firebase.dataconnect.OptionalVariable.Undefined
            var photoUrl: com.google.firebase.dataconnect.OptionalVariable<String?> =
                com.google.firebase.dataconnect.OptionalVariable.Undefined
            var createdAt= createdAt
            

          return object : Builder {
            override var id: java.util.UUID?
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { id = com.google.firebase.dataconnect.OptionalVariable.Value(value_) }
              
            override var googleId: String
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { googleId = value_ }
              
            override var displayName: String
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { displayName = value_ }
              
            override var email: String?
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { email = com.google.firebase.dataconnect.OptionalVariable.Value(value_) }
              
            override var photoUrl: String?
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { photoUrl = com.google.firebase.dataconnect.OptionalVariable.Value(value_) }
              
            override var createdAt: com.google.firebase.Timestamp
              get() = throw UnsupportedOperationException("getting builder values is not supported")
              set(value_) { createdAt = value_ }
              
            
          }.apply(block_)
          .let {
            Variables(
              id=id,googleId=googleId,displayName=displayName,email=email,photoUrl=photoUrl,createdAt=createdAt,
            )
          }
        }
      }
    
  }
  

  
    @kotlinx.serialization.Serializable
  public data class Data(
  
    val user_upsert: UserKey
  ) {
    
    
  }
  

  public companion object {
    public val operationName: String = "UpsertUser"

    public val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data> =
      kotlinx.serialization.serializer()

    public val variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables> =
      kotlinx.serialization.serializer()
  }
}

public fun UpsertUserMutation.ref(
  
    googleId: String,displayName: String,createdAt: com.google.firebase.Timestamp,

  
    block_: UpsertUserMutation.Variables.Builder.() -> Unit = {}
  
): com.google.firebase.dataconnect.MutationRef<
    UpsertUserMutation.Data,
    UpsertUserMutation.Variables
  > =
  ref(
    
      UpsertUserMutation.Variables.build(
        googleId=googleId,displayName=displayName,createdAt=createdAt,
  
    block_
      )
    
  )

public suspend fun UpsertUserMutation.execute(

  
    
      googleId: String,displayName: String,createdAt: com.google.firebase.Timestamp,

  
    block_: UpsertUserMutation.Variables.Builder.() -> Unit = {}

  ): com.google.firebase.dataconnect.MutationResult<
    UpsertUserMutation.Data,
    UpsertUserMutation.Variables
  > =
  ref(
    
      googleId=googleId,displayName=displayName,createdAt=createdAt,
  
    block_
    
  ).execute()


