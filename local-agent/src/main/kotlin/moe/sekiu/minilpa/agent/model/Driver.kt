package moe.sekiu.minilpa.agent.model

import kotlinx.serialization.Serializable

@Serializable
data class Driver(
    val env : String,
    val name : String
) {
    override fun toString() : String = name
}

