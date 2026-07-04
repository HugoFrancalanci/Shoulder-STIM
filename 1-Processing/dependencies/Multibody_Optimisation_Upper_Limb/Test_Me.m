% Test

% EOS
load('Segment.mat')
Main_Joint_Kinematics 
load('Joint.mat')
display('Distance between glenoid and head centres')
Joint(1).d % Display
display('Distance between sternoclavicular and acromioclavicular centres')
Joint(2).d % Display

% Spherical
[Segment] = Multibody_Optimisation_Upper_Limb_SPN(Segment,Joint);
Main_Joint_Kinematics

% Spherical with penalised translation
[Segment] = Multibody_Optimisation_Upper_Limb_LmPN(Segment,Joint);
Main_Joint_Kinematics

% Sphere on sphere
[Segment] = Multibody_Optimisation_Upper_Limb_PPN(Segment,Joint);
Main_Joint_Kinematics

% 6 Dof (single body optimisation)
[Segment] = Multibody_Optimisation_Upper_Limb_NNN(Segment,Joint);
Main_Joint_Kinematics

legend('EOS', 'Spherical', 'Penalised translation', 'Sphere on sphere', '6 Dof')
