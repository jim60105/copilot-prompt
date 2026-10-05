# Research Evidence for Game UI Design

Snapshot reviewed: 2026-10-05.

Use this file to justify recommendations about game usability, HUD composition, diegetic/spatial presentation, tutorials, and learnability. Distinguish experimental findings from descriptive observations.

## Pinelle, Wong, and Stach, CHI 2008

**Paper:** *Heuristic Evaluation for Games: Usability Principles for Video Game Design*  
**Venue:** CHI 2008  
**Online:** https://www.researchgate.net/publication/395238929_Heuristic_Evaluation_for_Games_Usability_Principles_for_Video_Game_Design  
**Bibliographic index:** https://dblp.org/rec/conf/chi/PinelleW08

The authors developed game-usability heuristics by analyzing reviews covering 108 PC games across six major genres. They identified recurring usability problem classes and produced ten heuristics for inspecting early and functional prototypes.

Useful implications:

- Provide predictable responses to player actions.
- Support customization for settings that materially affect usability.
- Keep input mappings understandable and consistent.
- Provide enough game-state information for players to understand what is happening.
- Reduce visual representations that are difficult to interpret or that interfere with important information.
- Provide training, help, or documentation where the game requires learning.

Scope caution: the source set was PC-game reviews from its era, so apply the heuristics as usability prompts rather than modern platform certification criteria.

## Caroux and Isbister, 2016

**Paper:** *Influence of head-up displays’ characteristics on user experience in video games*  
**Journal:** International Journal of Human-Computer Studies, 87, 65-79  
**DOI:** https://doi.org/10.1016/j.ijhcs.2015.11.001  
**Publisher page:** https://www.sciencedirect.com/science/article/pii/S1071581915001779

Two experiments examined HUD use and experience. The paper reports that HUD composition and spatial organization matter, that permanent HUDs can improve understanding of the game environment, and that effects vary with player expertise and game genre.

Use this source when rejecting blanket rules such as "always hide the HUD" or "minimal HUD is always better." Treat HUD density and persistence as context-dependent design variables.

## Peacocke et al., 2018

**Paper:** *An empirical comparison of first-person shooter information displays: HUDs, diegetic displays, and spatial representations*  
**Journal:** Entertainment Computing, 26, 41-58  
**DOI:** https://doi.org/10.1016/j.entcom.2018.01.003  
**Publisher page:** https://www.sciencedirect.com/science/article/pii/S1875952117300435

The authors ran four experiments covering ammunition monitoring, health monitoring, weapon matching, and navigation in FPS-style tasks. Their overall conclusion is that neither conventional HUDs nor alternatives such as diegetic and spatial displays are universally best.

Use this as the main evidence for task-specific presentation choices. Evaluate each information type by monitoring frequency, time pressure, search cost, spatial relationship, and occlusion rather than by visual ideology.

Scope caution: the experiments focus on first-person-shooter information tasks. Do not generalize exact performance results to every genre without additional evidence.

## Cao and Liu, 2022

**Paper:** *Learning to play: understanding in-game tutorials with a pilot study on implicit tutorials*  
**Journal:** Heliyon, 8(11), e11482  
**DOI:** https://doi.org/10.1016/j.heliyon.2022.e11482  
**Open article:** https://www.sciencedirect.com/science/article/pii/S2405844022027700

The literature review reports recurring tutorial considerations: complex games benefit more from instruction; player proficiency matters; practice with timely feedback is useful; and just-in-time access to tutorial information is promising. The pilot study suggests implicit guidance can improve some player perceptions and may be especially useful for experienced players.

Use this source to support practice-based onboarding, timely feedback, and optional/contextual instruction. Do not treat the pilot study as proof that implicit tutorials are always superior.

## Poretski and Tang, CHI 2022

**Paper:** *Press A to Jump: Design Strategies for Video Game Learnability*  
**Venue:** CHI 2022  
**DOI:** https://doi.org/10.1145/3491102.3517685  
**Repository page:** https://ink.library.smu.edu.sg/sis_research/7892/

The authors analyzed 40 contemporary games and documented repeatable design strategies that use visual cues to support learning. This work is valuable as a descriptive framework for how games teach players beyond static tutorial screens.

Use this source to generate onboarding patterns and visual-cue ideas. Because the study is descriptive, do not present every observed strategy as causally proven to improve performance.

## Evidence synthesis

Use the combined evidence to support these conclusions:

- There is no single best HUD style across tasks and genres.
- HUD composition, persistence, and spatial organization influence player experience and comprehension.
- Game UI evaluation should include consistency, state visibility, input mappings, and interpretable visual representations.
- Tutorials benefit from proximity to use, active practice, and timely feedback, while player proficiency changes what guidance is useful.
- Visual learning cues are common and reusable, but observed industry patterns still require testing in the target game.
