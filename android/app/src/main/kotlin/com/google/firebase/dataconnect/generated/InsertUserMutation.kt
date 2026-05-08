
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



public interface InsertUserMutation :
    com.google.firebase.dataconnect.generated.GeneratedMutation<
      ExampleConnector,
      InsertUserMutation.Data,
      InsertUserMutation.Variables
    >
{
  
    @kotlinx.serialization.Serializable
  public data class Variables(
  
    val googleId: String,
    val displayName: String,
    val email: com.google.firebase.dataconnect.OptionalVariable<String?>,
    val photoUrl: com.google.firebase.dataconnect.OptionalVariable<String?>,
    val createdAt: @kotlinx.serialization.Serializable(with = com.google.firebase.dataconnect.serializers.TimestampSerializer::class) com.google.firebase.Timestamp
  ) {
    
    
      
      @kotlin.DslMarker public annotation class BuilderDsl

      @BuilderDsl
      public interface Builder {
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
          var googleId= googleId
            var displayName= displayName
            var email: com.google.firebase.dataconnect.OptionalVariable<String?> =
                com.google.firebase.dataconnect.OptionalVariable.Undefined
            var photoUrl: com.google.firebase.dataconnect.OptionalVariable<String?> =
                com.google.firebase.dataconnect.OptionalVariable.Undefined
            var createdAt= createdAt
            

          return object : Builder {
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
              googleId=googleId,displayName=displayName,email=email,photoUrl=photoUrl,createdAt=createdAt,
            )
          }
        }
      }
    
  }
  

  
    @kotlinx.serialization.Serializable
  public data class Data(
  
    val user_insert: UserKey
  ) {
    
    
  }
  

  public companion object {
    public val operationName: String = "InsertUser"

    public val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data> =
      kotlinx.serialization.serializer()

    public val variablesSerializer: kotlinx.serialization.SerializationStrategy<Variables> =
      kotlinx.serialization.serializer()
  }
}

public fun InsertUserMutation.ref(
  
    googleId: String,displayName: String,createdAt: com.google.firebase.Timestamp,

  
    block_: InsertUserMutation.Variables.Builder.() -> Unit = {}
  
): com.google.firebase.dataconnect.MutationRef<
    InsertUserMutation.Data,
    InsertUserMutation.Variables
  > =
  ref(
    
      InsertUserMutation.Variables.build(
        googleId=googleId,displayName=displayName,createdAt=createdAt,
  
    block_
      )
    
  )

public suspend fun InsertUserMutation.execute(

  
    
      googleId: String,displayName: String,createdAt: com.google.firebase.Timestamp,

  
    block_: InsertUserMutation.Variables.Builder.() -> Unit = {}

  ): com.google.firebase.dataconnect.MutationResult<
    InsertUserMutation.Data,
    InsertUserMutation.Variables
  > =
  ref(
    
      googleId=googleId,displayName=displayName,createdAt=createdAt,
  
    block_
    
  ).execute()


