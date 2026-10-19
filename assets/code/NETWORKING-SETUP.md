# Versioned state replication

Install DeltaReplicator as a server ModuleScript and DeltaReplicatorClient.client.luau in StarterPlayerScripts. The server owns all writes through DeltaReplicator.Track(player, initial) and DeltaReplicator.Set(player, key, value). Only the four defined keys and bounded value types are supported. The client receives 10 Hz batched deltas and requests snapshots through a rate-limited server RemoteFunction when it starts or sees a sequence gap.

The client writes local-only attributes named Foallow_Health, Foallow_Stamina, Foallow_Level and Foallow_Stance on Players.LocalPlayer. UI components should observe those attributes with GetAttributeChangedSignal. The client does not send state mutations back through the replication RemoteEvent. The data is a view model, not a substitute for server-side health or game state.

Packet-loss behavior, late joiners, request throttling and performance must be exercised in Studio; do not equate version numbers and snapshots with measured delivery guarantees.
