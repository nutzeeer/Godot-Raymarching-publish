This plugin is currently to be used as is, with the raymarching-plugin folder used as the project folder.
Its under development and subject to refactoring and fixing issues. Effect file and shape classes are subject to be extended, but not to completely change.

This plugin organizes Raymarching rendering using godots node system. You add a Raymarching camera node, which is an extended Camera3D. This camera adds raymarching settings and a full screen quad to render the fragment shader on. (Raymarching is done per pixel and needs a full screen surface to render on .) 
Shape manager nodes are added as children of the Raymarching camera. You can choose shapes and effects applied to them. The shape specific parameters are defined in the shape class, and standard parameters like transforms are leveraging Godots inbuilt system.

Known issues:
-Effect helper functions are not yet given an effect id, so selecting effects with same name helper functions will cause a redeclaration issue in the shader.
-Changing base functionality is difficult due to the shape manager being a mess. Its declaring the ability of the files it uses in multiple points, rather centrally once. The sub class invocation as used in the shader generator will be useful here.
-local p or d affecting effects are unstable from off angles. I reckon there is a structural flaw present that needs assesment.
-loading a scene other than the standard node_3d.tscn is currently not possible. Though saving scenes is. (Scene change triggers).
-The folder structure is messy from constant refactoring.
-A broken class file can halt class list loading upon shape manager creation. If effects and shapes are missing upon node creation there is probably an issue.
-Editor settings are not maintained upon project export, creating gray scenes.


To be implemented:
-Boolean operations of Shapes: The option to add shapes as children of shape nodes and then choosing the boolean operation like + - / * to create more complex shapes. Currently its possible to manually create more complex shape classes to be used in a shape manager. Perhaps it would be useful to combine shape managers using booleans as needed and push an export button to create a singular sdf shape file.
-The plugin is currently usable as is, without development for deep integration with other Godot functions.
-Deeper Godot integration of existing functions. (File loading like for meshes instead of loading once at node generation and then having a list).
-A bounding volume hierarchy to improve performance.(Either manually defined as an extra function or analytically created using normals fields around objects)
-Physics using

This plugin is provided as is without any warranty under the same license as Godot itself.
If you are interested in supporting this project please reach out to me, so I will set up patreon or ko-fi.
Optimally I would like to work at the Godot foundation to continue working on the part time or full time. There is much potential left to be uncovered to bring Raymarching to the masses!
