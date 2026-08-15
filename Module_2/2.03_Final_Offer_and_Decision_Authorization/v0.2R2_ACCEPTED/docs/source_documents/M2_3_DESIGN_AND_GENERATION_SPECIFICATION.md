# M2.3 Design and Generation Specification

M2.3 performs deterministic decision mapping from the accepted M2.2 pricing disposition to a final authorization outcome. Only `STRUCTURE_READY` rows receive final offer terms. All other routes carry null offer terms. Decline-authorized rows remain synthetic internal outcomes and all production-adverse-action flags remain false.
