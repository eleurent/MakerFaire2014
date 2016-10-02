Mission on Mars Robot Challenge - Maker Faire 2014
=================

*Alexandre Lefort, Martin de Gourcuff, Edouard Leurent* - Psittacidae team

# Features

## InputProcessing
- Implementation of an Extended Kalman Filter to estimate position and orientation by updating odometry with computer vision.
- Implementation of an Unscented Kalman Filter for the same purpose, more efficient than the EKF for state update after an important dift (with added noise in the encoders, for instance), but more computationally expensive.
- The camera observation with EKF/UKF uses all targets detected by the camera, and not just the destination as in the original simulation.
- The camera delay (0.3s) is now taken into account in the EKF/UKF.
- Distance command is now handled as a relative command to handle overshoots and turns.
- Rotation during the validation time at a target pour to face the next target.

## Controller
- More aggressive gains tuning
- Priorization of the angle command by dynamic saturation of the distance command at the maximum allowing the bearing command differential.
- Add integral gains in distance and bearing to avoid being stuck near a target because of the motor dead bands.
  The integral term is bounded for bearing to avoid wind-up phenomenon.
- Add a derivative term to the bearing controller, when the robot is stopped, to avoir overshoots.
- Two different sets of gains are used in the bearing controller when the robot is stopped or in motion.

## Strategy
- Travelling salesman solver using a genetic algorithm to find the shortest route.
