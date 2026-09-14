# Visual Direction — Storybook Field Guide

Status: **Approved direction; validate in the Act I slice**  
Milestone: **0 — Vision lock**

## Target

> Ecologically recognizable plants, animals, water, and geology, simplified
> into layered paper-cut shapes with expressive animation.

The procedural cutout look is part of the production strategy, but the demo's
current level of detail is not the final quality bar. Deepen the style through
composition, layering, motion, and transformation before considering a new
sprite or painted-asset pipeline.

## Rendering language

- Give important objects a clear silhouette at gameplay zoom before adding
  interior detail.
- Build forms from two or three value layers: base, shadow, and selective
  highlight. Avoid both flat single-fill objects and noisy gradients.
- Use the shared warm outline and soft ground shadow to hold different region
  palettes together.
- Cluster vegetation by habitat and moisture instead of scattering decorations
  evenly.
- Reserve the strongest saturation and motion for interactable objects,
  characters, water edges, and ecological payoff details.
- Use overlapping foreground, play-space, and background shapes to make each
  map feel composed rather than tiled.

## Character and motion bar

- Preserve recognizable species markings while exaggerating pose and facial
  expression for dialogue-scale readability.
- Build real directional walk cycles from layered body, foot, head, and tail
  motion; do not rely only on whole-body bobbing.
- Give every resident at least three readable states: neutral routine,
  concerned or conflicted, and post-restoration ease or delight.
- Animate habitats as character payoff: Moss calls from changing perches, Eddy
  uses multiple flow paths, and Bramble works along the high-bank route.
- Let wind, water, willow tips, aspen leaves, flowers, snowmelt, and drifting
  debris establish region motion even when the player stands still.

## Transformation bar

- Author clear before, transition, and after states for every major build.
- Change water shape, soil moisture, vegetation, wildlife, routes, resident
  behavior, ambience, and sound—not only color or HUD state.
- Several compressed spring weeks allow buds, small shoots, and flowers to
  appear. Do not grow mature trees or erase the Moraine Basin burn scar.
- Use payoff framing and timing generously, then return control promptly.

## Fire and recovery framing

- Fire is not the story's antagonist. Do not specify an ignition cause or
  imply that all wildfire is ecologically destructive.
- Depict a mixed burn with surviving habitat, burned patches, safe deadwood,
  and active regrowth.
- Residents may discuss loss, displacement, changed snowmelt, erosion, and
  debris without describing the mountain as wholly destroyed.
- The ending improves watershed resilience but does not erase the scar or
  finish the ecosystem's recovery.

## Production boundary

Prove this quality bar in the Willowbend vertical slice. If the polished slice
still feels too basic, evaluate SVG or sprite workflows with a representative
character, habitat, and transformation before committing the other regions to
a replacement pipeline.
