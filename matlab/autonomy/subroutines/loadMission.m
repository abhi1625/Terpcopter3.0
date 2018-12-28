function mission = loadMission()
mission.config.firstLoop = 1;

% Behavior 1: Takeoff
mission.bhv{1}.name = 'bhv_takeoff';
mission.bhv{1}.ahs.desiredAltMeters = 0.5;    %
% mission.bhv{1}.ahs.forwardSpeed = 0;
% mission.bhv{1}.ahs.crabSpeed = 0;
mission.bhv{1}.completion.status = false;

% Behavior 2: Hover in Place
mission.bhv{2}.name = 'bhv_hover';
mission.bhv{2}.ahs.desiredAltMeters = 0.5;
mission.bhv{2}.completion.durationSec = 9.95; % 10 seconds
mission.bhv{2}.completion.status = false;     % completion flag

%Behavior 3: Land
mission.bhv{3}.name = 'bhv_land';
mission.bhv{3}.params.maxDescentRateMps = 0.2;
mission.bhv{3}.ahs.desiredAltMeters = 0.25;
mission.bhv{3}.completion.threshold = 0.1;
mission.bhv{3}.completion.status = false;


end