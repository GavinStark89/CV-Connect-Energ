# VECTOR-Velocity-based-Energetics-informed-Connectivity-for-Tracking-Organisms-to-Refugia
Project summary (VECTOR)

Idea. Protected areas (PAs) are increasingly “static” in a moving climate: many sites will lose the climatic conditions they were designated to protect, so long-term conservation depends on whether species can realistically move from climate-exposed PAs to climatically stable refugia.

Objective. VECTOR builds an energy-based, climate-resilient connectivity workflow for Europe that jointly considers (1) climate velocity and PA climatic residence time (a PA-scale persistence metric) and (2) the physiological feasibility of movement (movement energetics + landscape resistance), to identify feasible corridors and high-leverage bottlenecks linking exposed lowlands to mountainous refugia.

Analysis workflow.

Climate exposure & resilience: compute climate velocity from gridded temperature change and spatial gradients; summarize within WDPA terrestrial PAs; derive climate residence time from PA size (effective radius) divided by mean internal velocity.

Energetic movement resistance: build an energy landscape from terrain slope (normalized movement cost) and integrate with land-cover/human-pressure resistance.

Habitat suitability: generate SDM-derived suitability → resistance layers for focal mammal taxa; add (“burn in”) major barriers (e.g., waterbodies, roads) and combine with energetics into a composite resistance surface.

Functional connectivity: run current-density (circuit theory) connectivity modelling (Omniscape) to map movement flow, corridors, and bottlenecks; summarize results for herbivore and carnivore archetypes and relate connectivity to climatic resilience within and around PAs.

Overall result patterns (Europe-wide).

Climate risk is widespread: ~46% of terrestrial PAs are climate-exposed (short residence times), concentrated in lowland regions; climatically resilient PAs (~24%) cluster in major mountain systems (e.g., Alps, Pyrenees, Carpathians, Scandinavian highlands), consistent with steep topographic gradients reducing effective velocity.

Connectivity differs by archetype: herbivore connectivity is generally lower and more fragmented, especially across intensive agricultural lowlands; carnivore connectivity is more continuous, but still shows major lowland bottlenecks tied to urbanization and intensive land use.

Key takeaway: climate-tracking opportunities are strongly constrained by energetic feasibility and become channelled through a small number of concentrated bottlenecks—meaning corridors that look structurally connected can become functionally inaccessible once physiology + climate exposure are accounted for.
