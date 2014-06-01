================== Améliorations ==================
01/06/2014 - Alexandre Lefort, Martin de Gourcuff, Edouard Leurent

=== InputProcessing ===
- Implémentation d'un Extended Kalman Filter pour estimer la position et l'orientation en recalant l'odométrie par la vision
- Implémentation d'un Unscented Kalman Filter dans le même but, plus efficace que l'EKF pour recaler après une dérive importante (si on rajoute du bruit dans les encodeurs, par exemple), mais plus lourd en temps de calcul.
- Le recalage par EKF/UKF utilise toutes les zones vues par la caméra, et non plus juste la destination comme dans la simulation originale
- Prise en compte du délai de la caméra (0.3s) dans l'incorporation des mesures de l'EKF/UKF
- Commande de distance envoyée en relatif pour gérer les dépassements et demis-tours
- Rotation pendant l'attente à une zone pour s'orienter vers la prochaine

=== Controller === 
- Réglage des gains plus agressif
- Priorisation de la commande d'angle par saturation dynamique de la commande de distance au maximum possible permettant d'imposer le différentiel de la commande de bearing
- Ajout de termes intégraux en distance et en angle pour résoudre les blocages à proximité d'une cible (effort des roues dans la dead band, insuffisant pour avancer). 
  Le gain intégral est bridé en angle afin de converger plus rapidement et d'éviter le phénomène de wind-up
  Le gain intégral en distance est mis à 0 pour le moment
- Ajout d'un terme dérivé en angle à l'arrêt, pour limiter les dépassements
- Deux jeux de gains différents pour le PID del'angle en fonction de l'état du robot (à l'arrêt sur un site ou en mouvement)

=== Stratégie ===
- Solveur du voyageur de commerce par algorithme génétique, qu'on exécute à la place de changeSitesOrder.m pour trouver le plus court chemin 
  Pour ce faire il suffit de lancer le script matlab/utilities/computeTSPSitesOrder.m
