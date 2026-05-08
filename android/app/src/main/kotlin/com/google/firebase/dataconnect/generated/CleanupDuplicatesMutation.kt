
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



public interface CleanupDuplicatesMutation :
    com.google.firebase.dataconnect.generated.GeneratedMutation<
      ExampleConnector,
      CleanupDuplicatesMutation.Data,
      Unit
    >
{
  

  
    @kotlinx.serialization.Serializable
  public data class Data(
  
    val cleanEpisodes: Int?,
    val cleanPodcasts: Int?,
    val cleanUsers: Int?
  ) {
    
    
  }
  

  public companion object {
    public val operationName: String = "CleanupDuplicates"

    public val dataDeserializer: kotlinx.serialization.DeserializationStrategy<Data> =
      kotlinx.serialization.serializer()

    public val variablesSerializer: kotlinx.serialization.SerializationStrategy<Unit> =
      kotlinx.serialization.serializer()
  }
}

public fun CleanupDuplicatesMutation.ref(
  
): com.google.firebase.dataconnect.MutationRef<
    CleanupDuplicatesMutation.Data,
    Unit
  > =
  ref(
    
      Unit
    
  )

public suspend fun CleanupDuplicatesMutation.execute(

  

  ): com.google.firebase.dataconnect.MutationResult<
    CleanupDuplicatesMutation.Data,
    Unit
  > =
  ref(
    
  ).execute()


